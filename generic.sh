#!/usr/bin/env bash
# /etc/udpate.sh PrivateRouter Update Script

# Get the name of the script without the path
SCRIPT_NAME=$(basename "$0")

# Count the number of running instances of the script (excluding the current one)
NUM_INSTANCES=$(pgrep -f "${SCRIPT_NAME}" | grep -v "$$" | wc -l)

# If more than one instance is found, exit
if [ "$NUM_INSTANCES" -gt 1 ]; then
    log_say "${SCRIPT_NAME} is already running, exiting."
    exit 1
fi

# Log to the system log and echo if needed
log_say()
{
    SCRIPT_NAME=$(basename "$0")
    echo "${SCRIPT_NAME}: ${1}"
    logger "${SCRIPT_NAME}: ${1}"
    echo "${SCRIPT_NAME}: ${1}" >> "/tmp/${SCRIPT_NAME}.log"
}

install_packages() {
    # Install packages
    log_say "Installing packages: ${1}"
    local count=$(echo "${1}" | wc -w)
    log_say "Packages to install: ${count}"

    for package in ${1}; do
        if ! opkg list-installed | grep -q "^$package -"; then
            log_say "Installing $package..."
            # use --force-maintainer to preserve the existing config
            opkg install --force-maintainer $package
            if [ $? -eq 0 ]; then
                log_say "$package installed successfully."
            else
                log_say "Failed to install $package."
            fi
        else
            log_say "$package is already installed."
        fi
    done
}

# Command to wait for Internet connection
wait_for_internet() {
    while ! ping -q -c3 1.1.1.1 >/dev/null 2>&1; do
        log_say "Waiting for Internet connection..."
        sleep 1
    done
    log_say "Internet connection established"
}

wait_for_internet

# Perform the DNS resolution check
if ! nslookup "privaterouter.com" >/dev/null 2>&1; then
    log_say "Domain resolution failed. Setting DNS server to 1.1.1.1."

    # Update resolv.conf with the new DNS server
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
else
    log_say "Domain resolution successful."
fi

log_say "                                                                      "
log_say " ███████████             ███                         █████            "
log_say "░░███░░░░░███           ░░░                         ░░███             "
log_say " ░███    ░███ ████████  ████  █████ █████  ██████   ███████    ██████ "
log_say " ░██████████ ░░███░░███░░███ ░░███ ░░███  ░░░░░███ ░░░███░    ███░░███"
log_say " ░███░░░░░░   ░███ ░░░  ░███  ░███  ░███   ███████   ░███    ░███████ "
log_say " ░███         ░███      ░███  ░░███ ███   ███░░███   ░███ ███░███░░░  "
log_say " █████        █████     █████  ░░█████   ░░████████  ░░█████ ░░██████ "
log_say "░░░░░        ░░░░░     ░░░░░    ░░░░░     ░░░░░░░░    ░░░░░   ░░░░░░  "
log_say "                                                                      "
log_say "                                                                      "
log_say " ███████████                        █████                             "
log_say "░░███░░░░░███                      ░░███                              "
log_say " ░███    ░███   ██████  █████ ████ ███████    ██████  ████████        "
log_say " ░██████████   ███░░███░░███ ░███ ░░░███░    ███░░███░░███░░███       "
log_say " ░███░░░░░███ ░███ ░███ ░███ ░███   ░███    ░███████  ░███ ░░░        "
log_say " ░███    ░███ ░███ ░███ ░███ ░███   ░███ ███░███░░░   ░███            "
log_say " █████   █████░░██████  ░░████████  ░░█████ ░░██████  █████           "
log_say "░░░░░   ░░░░░  ░░░░░░    ░░░░░░░░    ░░░░░   ░░░░░░  ░░░░░            "

# Check if we need to update our updater scripts
log_say "Beginning update-scripts up to date check"

HASH_STORE="/etc/config/.update-scripts"
TMP_DIR="/tmp/update-scripts"
GIT_URL="https://github.com/PrivateRouter-LLC/update-scripts"
UPDATER_LOCATION="/root/update-scripts"

CURRENT_HASH=$(
    curl \
        --silent https://api.github.com/repos/PrivateRouter-LLC/update-scripts/commits/main | \
        jq --raw-output '.sha'
)

if [ -f "${HASH_STORE}" ] && [ ! -z "${CURRENT_HASH}" ]; then
    log_say "Update Script Found ${HASH_STORE}"
    CHECK_HASH=$(cat ${HASH_STORE})
    log_say "Update Script Check Hash ${CHECK_HASH}"
    [[ "${CHECK_HASH}" != "${CURRENT_HASH}" ]] && {
        log_say "Update Script ${CHECK_HASH} != ${CURRENT_HASH}"
        UPDATE_NEEDED="1"
    }
else
    log_say "Update Script ${HASH_STORE} did not exist"
    UPDATE_NEEDED="1"
fi

if [[ "${UPDATE_NEEDED}" == "1" || ! -d ${UPDATER_LOCATION} ]]; then
    log_say "Update Script Update is needed"

    CRONTAB_CONTENT=$(cat "/etc/crontabs/root")
    [[ "${CRONTAB_CONTENT}" =~ "update-dockerdeploy.sh" ]] && {
        log_say "Update Script found update-dockerdeploy.sh, removing entry in crontab"
        sed -i '/update-dockerdeploy.sh/d' /etc/crontabs/root
    }
    [[ "${CRONTAB_CONTENT}" =~ "update-docker-compose-templates.sh" ]] && {
        log_say "Update Script found update-docker-compose-templates.sh, removing entry in crontab"
        sed -i '/update-docker-compose-templates.sh/d' /etc/crontabs/root
    }
    [[ "${CRONTAB_CONTENT}" =~ "update-repo.sh" ]] && {
        log_say "Update Script found update-repo.sh, removing entry in crontab"
        sed -i '/update-repo.sh/d' /etc/crontabs/root
    }

    [ -d "${TMP_DIR}" ] && {
        log_say "Update Script Cleaning temporary output ${TMP_DIR}"
        rm -rf "${TMP_DIR}"
    }

    log_say "Update Script Cloning ${GIT_URL} into ${TMP_DIR}"
    while ! git clone --depth=1 "${GIT_URL}" "${TMP_DIR}" >/dev/null 2>&1; do
        log_say "... Waiting to clone the update script repo ..."
        sleep 1
    done
    # Verify it downloaded successfully
    if [ -d "${TMP_DIR}" ]; then    
        log_say "Update Script Cleaning up .git folder"
        rm -rf "${TMP_DIR}/.git"

        [ -d "${UPDATER_LOCATION}" ] && { log_say "Update Script Removing old ${UPDATER_LOCATION}"; rm -rf "${UPDATER_LOCATION}"; }

        log_say "Update Script Moving ${TMP_DIR} to ${UPDATER_LOCATION}"
        mv "${TMP_DIR}" "${UPDATER_LOCATION}"

        echo "${CURRENT_HASH}" > "${HASH_STORE}"
        log_say "Update Script Wrote ${CURRENT_HASH} > ${HASH_STORE}"

        [ -f "${UPDATER_LOCATION}/crontabs" ] && {
            log_say "Update Script Inserting crontabs for updaters and restarting the cron service"
            cat "${UPDATER_LOCATION}/crontabs" >> /etc/crontabs/root
            /etc/init.d/cron restart
        }

        [ -f "${UPDATER_LOCATION}/first-run.sh" ] && {
            log_say "Running the commands in the first-run.sh script."
            bash "${UPDATER_LOCATION}/first-run.sh"
        }
    else
        log_say "We were not able to download our update scripts"
        #reboot
        exit 1
    fi
else
    log_say "Update Script Update is not needed"
fi # UPDATE_NEEDED check

# Wait until we can run opkg update, if it fails try again
while ! opkg update >/dev/null 2>&1; do
    log_say "... Waiting to update opkg ..."
    sleep 1
done

log_say "Install PrivateRouter Theme"
install_packages "luci-theme-privaterouter luci-mod-dashboard"
# Make sure theme installed ok, if so set it default
$(opkg list-installed | grep -q "^luci-theme-privaterouter") && {
    # Fix the CSS for the dashboard
    log_say "Fixing the CSS for the dashboard"
    [ ! -d /www/luci-static/resources/view/dashboard/css ] && mkdir -p /www/luci-static/resources/view/dashboard/css
    curl -o /www/luci-static/resources/view/dashboard/css/custom.css https://gist.githubusercontent.com/FixedBit/36327dd57f769f43c7058212a42ff65e/raw/d07d5ab89b27a62651871a4cc9fb7710445493d7/gistfile1.txt 
    # Set it as the default theme
    log_say "Setting the PrivateRouter theme as the default"
    uci set luci.main.mediaurlbase='/luci-static/privaterouter'
    uci commit luci
}

# Check and fix dnsmsaq
log_say "Checking if dnsmsaq-full is installed"
if ! opkg list-installed | grep -q "^dnsmasq-full "; then
    log_say "Removing original dnsmasq and installing dnsmasq-full"
    opkg remove dnsmasq
    # use --force-maintainer to preserve the existing config
    opkg install --force-maintainer dnsmasq-full
    if [ $? -eq 0 ]; then
        log_say "dnsmasq-full installed successfully."
    else
        log_say "Failed to install dnsmasq-full."
    fi
fi 

# Install v2ray
if ! opkg list-installed | grep -q "^luci-app-v2ray "; then
    log_say "Installing v2ray"
    wget -qO /tmp/luci-app-v2ray_2.0.0-1_all.ipk https://github.com/kuoruan/luci-app-v2ray/releases/download/v2.0.0-1/luci-app-v2ray_2.0.0-1_all.ipk
    if [ $? -eq 0 ]; then
        log_say "v2ray downloaded, now installing."
        opkg install --force-maintainer /tmp/luci-app-v2ray_2.0.0-1_all.ipk
    else
        log_say "v2ray did not download successfully."
    fi
fi 

# All of this should be done in stage2.sh for new builds but leaving it here for now
log_say "Installing packages with Docker Support"
install_packages "attr avahi-dbus-daemon base-files busybox ca-bundle certtool cgi-io curl davfs2 dbus luci-app-uhttpd frpc luci-app-frpc kmod-rtl8xxxu rtl8188eu-firmware kmod-rtl8192ce kmod-rtl8192cu kmod-rtl8192de dcwapd jq bash git-http kmod-mwifiex-pcie kmod-mwifiex-sdio kmod-rtl8723bs kmod-rtlwifi kmod-rtlwifi-btcoexist kmod-rtlwifi-pci kmod-rtlwifi-usb kmod-wil6210 libuwifi kmod-8139cp kmod-8139too kmod-net-rtl8192su kmod-phy-realtek kmod-r8169 kmod-rtl8180 kmod-rtl8187 kmod-rtl8192c-common kmod-rtl8192se kmod-rtl8812au-ct kmod-rtl8821ae kmod-rtw88 kmod-sound-hda-codec-realtek kmod-switch-rtl8306 kmod-switch-rtl8366-smi kmod-switch-rtl8366rb kmod-switch-rtl8366s kmod-switch-rtl8367b kmod-usb-net-rtl8150 kmod-usb-net-rtl8152 librtlsdr r8169-firmware rtl-sdr rtl8192ce-firmware rtl8192cu-firmware rtl8192de-firmware rtl8192eu-firmware rtl8192se-firmware rtl8192su-firmware rtl8723au-firmware rtl8723bu-firmware rtl8821ae-firmware rtl8822be-firmware rtl8822ce-firmware rtl_433 kmod-mt76 kmod-mt76-connac kmod-mt76-core kmod-mt76-usb kmod-mt7603 kmod-mt7615-common kmod-mt7615-firmware kmod-mt7615e kmod-mt7663-firmware-ap kmod-mt7663-firmware-sta kmod-mt7663-usb-sdio kmod-mt7663s kmod-mt7663u kmod-mt76x0-common kmod-mt76x02-common kmod-mt76x02-usb kmod-mt76x0e kmod-mt76x0u kmod-mt76x2 kmod-mt76x2-common kmod-mt76x2u kmod-mt7915e kmod-ar5523 kmod-mt7921e mt7601u-firmware kmod-ath kmod-brcmutil kmod-libertas-sdio kmod-libertas-spi kmod-libertas-usb kmod-mt7601u iwlwifi-firmware-iwl100 iwlwifi-firmware-iwl1000 iwlwifi-firmware-iwl105 iwlwifi-firmware-iwl135 iwlwifi-firmware-iwl2000 iwlwifi-firmware-iwl2030 iwlwifi-firmware-iwl3160 iwlwifi-firmware-iwl3168 iwlwifi-firmware-iwl5000 iwlwifi-firmware-iwl5150 iwlwifi-firmware-iwl6000g2 iwlwifi-firmware-iwl6000g2a iwlwifi-firmware-iwl6000g2b iwlwifi-firmware-iwl6050 iwlwifi-firmware-iwl7260 iwlwifi-firmware-iwl7265 iwlwifi-firmware-iwl7265d iwlwifi-firmware-iwl8260c iwlwifi-firmware-iwl8265 iwlwifi-firmware-iwl9000 iwlwifi-firmware-iwl9260 kmod-iwlwifi luci-app-wifischedule dnsmasq dropbear firewall fstools fuse3-utils fwtool getrandom git glib2 gnupg hostapd-common ip-full ip6tables ipset iptables iptables-mod-ipopt iw iwinfo jshn adblock luci-app-adblock wwan jsonfilter kernel kmod-bluetooth kmod-btmrvl kmod-cfg80211 kmod-crypto-aead kmod-crypto-ccm kmod-crypto-cmac kmod-crypto-ctr kmod-crypto-ecb kmod-crypto-ecdh kmod-crypto-gcm kmod-crypto-gf128 kmod-usb-wdm kmod-usb-net-ipheth kmod-crypto-ghash kmod-crypto-hash kmod-crypto-hmac kmod-crypto-kpp kmod-crypto-lib-blake2s kmod-crypto-lib-chacha20 kmod-crypto-lib-chacha20poly1305 kmod-crypto-lib-curve25519 kmod-usb-net-asix-ax88179 kmod-crypto-lib-poly1305 kmod-crypto-manager kmod-crypto-null kmod-crypto-rng kmod-crypto-seqiv kmod-crypto-sha256 kmod-fuse kmod-gpio-button-hotplug kmod-hid kmod-input-core kmod-input-evdev kmod-ip6tables kmod-ipt-conntrack kmod-ipt-core kmod-ipt-ipopt kmod-ipt-ipset kmod-ipt-nat kmod-ipt-offload kmod-lib-crc-ccitt kmod-lib-crc16 kmod-mac80211 kmod-mmc luci-compat luci-lib-ipkg kmod-mwlwifi kmod-nf-conntrack kmod-nf-conntrack6 kmod-nf-flow kmod-nf-ipt kmod-nf-ipt6 kmod-nf-nat kmod-nf-reject kmod-nf-reject6 kmod-nfnetlink kmod-nls-base kmod-ppp kmod-pppoe kmod-pppox kmod-brcmfmac usbmuxd kmod-regmap-core kmod-slhc kmod-tun kmod-udptunnel4 kmod-udptunnel6 kmod-usb-core kmod-wireguard libatomic1 libattr libavahi-client libavahi-dbus-support libblkid1 libbpf0 libbz2-1.0 libc kmod-usb-net-rndis libcap libcurl4 libdaemon libdbus libelf1 libev libevdev libevent2-7 libexif libexpat libffi libffmpeg-mini libflac libfuse1 libfuse3-3 libgcc1 libgmp10 libgnutls libhttp-parser kmod-usb-net-cdc-ncm libid3tag libip4tc2 libip6tc2 libipset13 libiwinfo-data libiwinfo-lua libiwinfo20210430 libjpeg-turbo libjson-c5 liblua5.1.5 liblucihttp-lua liblucihttp0 liblzo2 libmbedtls12 libmnl0 luci-app-ttyd kmod-usb-net-cdc-eem libmount1 libncurses6 libneon libnettle8 libnftnl11 libnghttp2-14 libnl-tiny1 libogg0 libopenssl-conf libopenssl1.1 libowipcalc libpam libpcre libpopt0 libprotobuf-c libpthread libreadline8 kmod-usb-net-cdc-subset librt libsmartcols1 libsodium libsqlite3-0 libtasn1 libtirpc libubus-lua libuci-lua libuci20130104 libuclient20201210 libudev-zero liburing libusb-1.0-0 libustream-wolfssl20201210 libuuid1 kmod-usb-net-cdc-ether libvorbis libxml2 libxtables12 logd lua luci luci-app-attendedsysupgrade luci-app-firewall luci-app-minidlna luci-app-openvpn luci-app-opkg luci-app-samba4 kmod-usb-net-hso luci-app-wireguard luci-base luci-i18n-firewall-en kmod-usb2 kmod-usb3 luci-i18n-wireguard-en luci-lib-base luci-lib-ip luci-lib-jsonc luci-lib-nixio luci-mod-admin-full luci-mod-network luci-mod-status luci-mod-system luci-proto-ipv6 luci-proto-ppp luci-proto-wireguard luci-theme-bootstrap luci-theme-material luci-theme-openwrt-2020 minidlna mount-utils mtd mwifiex-sdio-firmware mwlwifi-firmware-88w8964 netifd odhcp6c odhcpd-ipv6only openssh-sftp-client openssh-sftp-server openssl-util openvpn-openssl openwrt-keyring opkg owipcalc ppp ppp-mod-pppoe procd procd-seccomp procd-ujail python3-base python3-email python3-light python3-logging python3-openssl python3-pysocks python3-urllib resolveip rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci luci-app-statistics rpcd-mod-rpcsys rpcd-mod-rrdns rsync samba4-libs samba4-server nano sshfs terminfo ubi-utils luci-app-commands uboot-envtools ubox ubus ubusd uci uclient-fetch uhttpd uhttpd-mod-ubus urandom-seed urngd usbutils usign vpnbypass vpnc-scripts watchcat wg-installer-client wget-ssl wireguard-tools wireless-regdb wpad zlib kmod-usb-storage block-mount kmod-fs-ext4 kmod-fs-exfat e2fsprogs fdisk luci-app-nlbwmon luci-app-vnstat"

if opkg list-installed | grep -q "^firewall4 "; then
    log_say "Removing NFtables and Firewall4, Replacing with legacy packages"
    opkg remove firewall4 --force-removal-of-dependent-packages
    if [ $? -eq 0 ]; then
        log_say "firewall4 removed successfully - installing Firewall packages."
        install_packages "firewall luci-app-firewall luci-i18n-firewall-en luci luci-ssl iptables-mod-extra kmod-br-netfilter kmod-ikconfig kmod-nf-conntrack-netlink kmod-nf-ipvs kmod-nf-nat iptables-zz-legacy"
    else
        log_say "Failed to remove firewall4."
    fi
fi # End Firewall4 Check

# Check /etc/passwd to see if root's shell is ash, if it is, change it to bash
if grep -q "/root:/bin/ash" /etc/passwd; then
    log_say "Changing root's shell from ash to bash"
    sed -i '/root/s/\/bin\/ash/\/bin\/bash/g' /etc/passwd
fi

# Install LXC on supported routers if it is not installed, we need to make sure it has /opt/docker2 first!
if ! opkg list-installed | grep -q "^lxc " && [ -d /opt/docker2 ]; then
    log_say "Install LXC and related packages"
    install_packages "lxc lxc-attach lxc-auto lxc-autostart lxc-cgroup lxc-checkconfig lxc-common lxc-config lxc-configs lxc-console lxc-copy lxc-create lxc-destroy lxc-device lxc-execute lxc-freeze lxc-hooks lxc-info lxc-init lxc-ls lxc-monitor lxc-monitord lxc-snapshot lxc-start lxc-stop lxc-templates lxc-top lxc-unfreeze lxc-unprivileged lxc-unshare lxc-user-nic lxc-usernsexec lxc-wait liblxc luci-app-lxc luci-i18n-lxc-en rpcd-mod-lxc"
    mkdir -p /opt/docker2/compose/lxc
    rm /etc/lxc/default.conf
    rm /etc/lxc/lxc.conf
    touch /etc/lxc/default.conf
    touch /etc/lxc/lxc.conf
    echo "lxc.lxcpath = /opt/docker2/compose/lxc" > /etc/lxc/lxc.conf
    cat > /etc/lxc/default.conf <<EOL
#lxc.net.0.type = empty
lxc.net.0.type = veth
lxc.net.0.link = br-lan
lxc.net.0.flags = up
#lxc.net.0.hwaddr = 00:FF:DD:BB:CC:01
EOL

    rm /etc/init.d/lxc-auto
    touch /etc/init.d/lxc-auto
    chmod +x /etc/init.d/lxc-auto
    cat > /etc/init.d/lxc-auto <<EOL
#!/bin/bash /etc/rc.common

. /lib/functions.sh

START=99
STOP=00

run_command() {
	local command="$1"
	$command
}

start_container() {
    local cfg="$1"
    local name

    config_get name "$cfg" name
    config_list_foreach "$cfg" command run_command

    if [ -n "$name" ]; then
        local config_path="/opt/docker2/compose/lxc/$name/config"

        # Change permissions so that the script can write to the file
        chmod 664 "$config_path" || echo "Failed to set permissions on $config_path" >> /etc/lxc/error.log

        # Generate a random MAC address
        local MAC=$(od -An -N6 -tx1 /dev/urandom | sed -e 's/  */:/g' -e 's/^://')

        # Debugging: log the MAC address generation
        echo "Debug: Generated MAC $MAC for $name" >> /etc/lxc/error.log

        # Remove existing MAC address setting if it exists
        sed -i "/^lxc.net.0.hwaddr/d" "$config_path"

        # Add new MAC address setting
        echo "lxc.net.0.hwaddr = $MAC" >> "$config_path" || echo "Failed to write MAC address to $config_path" >> /etc/lxc/error.log

        # Start the container
        /usr/bin/lxc-start -n "$name"
    fi
}

max_timeout=0

stop_container() {
	local cfg="$1"
	local name timeout

	config_get name "$cfg" name
	config_get timeout "$cfg" timeout 300

	if [ "$max_timeout" -lt "$timeout" ]; then
		max_timeout=$timeout
	fi

	if [ -n "$name" ]; then
		/usr/bin/lxc-stop -n "$name" -t $timeout &
	fi
}

start() {
	config_load lxc-auto
	config_foreach start_container container
}

stop() {
	config_load lxc-auto
	config_foreach stop_container container
	# ensure e.g. shutdown doesn't occur before maximum timeout on
	# containers that are shutting down
	if [ $max_timeout -gt 0 ]; then
		sleep $max_timeout
	fi
}

#Export systemd cgroups
boot() {
	if [ ! -d /sys/fs/cgroup/systemd ]; then
		mkdir -p /sys/fs/cgroup/systemd
		mount -t cgroup -o rw,nosuid,nodev,noexec,relatime,none,name=systemd cgroup /sys/fs/cgroup/systemd
	fi

	if [ ! -d /run ]; then
		ln -s /var/run /run
	fi

	start
}
EOL
fi
# End LXC install

log_say "PrivateRouter update complete!"

exit 0
