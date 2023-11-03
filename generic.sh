#!/usr/bin/env bash
# PrivateRouter Update Script

# Log to the system log and echo if needed
log_say()
{
    SCRIPT_NAME=$(basename "$0")
    echo "${SCRIPT_NAME}: ${1}"
    logger "${SCRIPT_NAME}: ${1}"
}

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

# Command to wait for Internet connection
wait_for_internet() {
    while ! ping -q -c3 1.1.1.1 >/dev/null 2>&1; do
        log_say "Waiting for Internet connection..."
        sleep 1
    done
    log_say "Internet connection established"
}

# Command to wait for opkg to finish
wait_for_opkg() {
  while pgrep -x opkg >/dev/null; do
    log_say "Waiting for opkg to finish..."
    sleep 1
  done
  log_say "opkg is released, our turn!"
}

# Wait for Internet connection
wait_for_internet

# Perform the DNS resolution check
if ! nslookup "privaterouter.com" >/dev/null 2>&1; then
    log_say "Domain resolution failed. Setting DNS server to 1.1.1.1."

    # Update resolv.conf with the new DNS server
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
else
    log_say "Domain resolution successful."
fi

# Wait for opkg to finish
wait_for_opkg

# Set this to 0 to disable Tankman theme
TANKMAN_FLAG=1

# This file is our marker to know the first run init script has already ran
INIT_MARKER="/usr/lib/opkg/info/tankman.list"

# If we are online and our tankman flag is enabled (and we have not already been ran before), do our setup script
[ ${TANKMAN_FLAG} = "1" ] && [ ! -f "${INIT_MARKER}" ] && {
        #Install Argon Tankman theme
        log_say "Installing custom Argon Tankman Theme"
        opkg install /etc/luci-theme-argon*.ipk
        opkg install /etc/luci-app-argon*.ipk

        tar xzvf /etc/logo.tar.gz -C /www/luci-static/argon/
        tar xzvf /etc/dockerman.tar.gz -C /usr/lib/lua/luci/model/cbi/dockerman/

        # Delete the background files from /www/luci-static/argon/background
        # Comment these lines out if you want to avoid bing backgrounds
        rm -rf /www/luci-static/argon/background/mahsa_amini.png
        rm -rf /www/luci-static/argon/background/tankman.mp4

        # Marker set so we know theme has been installed
        log_say "Set our marker file to know our tankman theme install has already ran"
        touch "${INIT_MARKER}"
} || {
        # No need to run setup script
        log_say "We do not need to run the PrivateRouter Tankman Theme Setup Script or it has already ran"
}

# Check if we need to update our updater scripts
log_say "Beginning update-scripts up to date check"

HASH_STORE="/etc/config/.update-scripts"
TMP_DIR="/tmp/update-scripts"
GIT_URL="https://github.com/PrivateRouter-LLC/update-scripts"
UPDATER_LOCATION="/root/update-scripts"

CURRENT_HASH=$(
    curl \
        --silent https://api.github.com/repos/PrivateRouter-LLC/update-scripts/commits/main |
        jq --raw-output '.sha'
)

if [ -f "${HASH_STORE}" ]; then
    log_say "Update Script Found ${HASH_STORE}"
    CHECK_HASH=$(cat ${HASH_STORE})
    log_say "Update Script Check Hash ${CHECK_HASH}"
    [[ "${CHECK_HASH}" != "${CURRENT_HASH}" ]] && {
        log_say "Update Script ${CHECK_HASH} != ${CURRENT_HASH}"
        UPDATE_NEEDED="1"
        echo "${CURRENT_HASH}" > "${HASH_STORE}"
        log_say "Update Script Wrote ${CURRENT_HASH} > ${HASH_STORE}"
    }
else
    log_say "Update Script ${HASH_STORE} did not exist"
    touch "${HASH_STORE}"
    echo "${CURRENT_HASH}" > "${HASH_STORE}"
    log_say "Update Script Wrote ${CURRENT_HASH} > ${HASH_STORE}"
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
    git clone --depth=1 "${GIT_URL}" "${TMP_DIR}"

    log_say "Update Script Cleaning up .git folder"
    rm -rf "${TMP_DIR}/.git"

    [ -d "${UPDATER_LOCATION}" ] && { log_say "Update Script Removing old ${UPDATER_LOCATION}"; rm -rf "${UPDATER_LOCATION}"; }

    log_say "Update Script Moving ${TMP_DIR} to ${UPDATER_LOCATION}"
    mv "${TMP_DIR}" "${UPDATER_LOCATION}"

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
    log_say "Update Script Update is not needed"
fi # UPDATE_NEEDED check

# Update and install all of our packages
log_say "updating all packages!"

log_say "NOTE: Since x86 does not currently have a stage2, we handle the install packages here"

opkg update
# Check if the file /etc/pr-mini exists, if it does we are on a device with smaller storage, otherwise we install all the packages
if [ -f /etc/pr-mini ]; then

    if [[ ! -f /etc/config/dhcp && -f /etc/config/dhcp.pr && ! -f /root/.dhcpfix-done ]]; then
        # Install our packages
        log_say "Fix dnsmasq problem"
        echo "nameserver 1.1.1.1" > /etc/resolv.conf
        opkg remove dnsmasq
        # The point here is to verify that we have a dhcp.pr file to put into place after the packages install
        # so if we have dhcp but no dhcp.pr, we move dhcp to dhcp.pr
        # if we have dhcp and dhcp.pr, we remove dhcp
        if [[ -f /etc/config/dhcp && ! -f /etc/config/dhcp.pr ]]; then
            log_say "/etc/config/dhcp exists but no /etc/config/dhcp.pr so we use our existing dhcp file"
            mv /etc/config/dhcp /etc/config/dhcp.pr
        elif [[ -f /etc/config/dhcp && -f /etc/config/dhcp.pr ]]; then
            log_say "/etc/config/dhcp exists and /etc/config/dhcp.pr exists so we remove the existing dhcp file"
            rm /etc/config/dhcp
        fi
        opkg install dnsmasq-full
        touch /root/.dhcpfix-done
    fi

    log_say "Installing mesh packages"
    ## INSTALL MESH  ##
    log_say "Installing Mesh Packages..."
    opkg install tgrouterappstore luci-app-shortcutmenu luci-app-poweroff luci-app-wizard luci-app-openwisp
    opkg remove wpad-basic wpad-basic-openssl wpad-basic-wolfssl wpad-wolfssl openwisp-monitoring openwisp-config
    opkg install wpad-mesh-openssl kmod-batman-adv batctl avahi-autoipd batctl-full luci-app-dawn 
    opkg install /etc/luci-app-easymesh_2.4_all.ipk
    opkg install /etc/luci-proto-batman-adv_git-22.104.47289-0a762fd_all.ipk
    
    log_say "Installing packages for a mini device"
    opkg install wireguard-tools ath10k-board-qca4019 ath10k-board-qca9888 ath10k-board-qca988x ath10k-firmware-qca4019-ct ath10k-firmware-qca9888-ct ath10k-firmware-qca988x-ct attr avahi-dbus-daemon base-files block-mount busybox ca-bundle certtool cgi-io dbus dropbear e2fsprogs fdisk firewall fstools fwtool
    opkg install getrandom hostapd-common ip-full ip6tables ipq-wifi-linksys_mr8300-v0 ipset iptables iptables-mod-ipopt iw iwinfo jshn jsonfilter kernel kmod-ath kmod-ath10k-ct kmod-ath9k kmod-ath9k-common kmod-cfg80211 kmod-crypto-crc32c kmod-crypto-hash kmod-crypto-kpp kmod-crypto-lib-blake2s kmod-crypto-lib-chacha20 kmod-crypto-lib-chacha20poly1305 kmod-crypto-lib-curve25519 kmod-crypto-lib-poly1305 kmod-fs-exfat kmod-fs-ext4
    opkg install kmod-gpio-button-hotplug kmod-hwmon-core kmod-ip6tables kmod-ipt-conntrack kmod-ipt-core kmod-ipt-ipopt kmod-ipt-ipset kmod-ipt-nat kmod-ipt-offload kmod-leds-gpio kmod-lib-crc-ccitt kmod-lib-crc16 kmod-mac80211 kmod-mii kmod-nf-conntrack
    opkg install kmod-nf-conntrack6 kmod-nf-flow kmod-nf-ipt kmod-nf-ipt6 kmod-nf-nat kmod-nf-reject kmod-nf-reject6 kmod-nfnetlink kmod-nls-base kmod-ppp kmod-pppoe kmod-pppox kmod-scsi-core kmod-slhc kmod-tun
    opkg install kmod-udptunnel4 kmod-udptunnel6 kmod-usb-core kmod-usb-dwc3 kmod-usb-dwc3-qcom kmod-usb-ehci kmod-usb-ledtrig-usbport kmod-usb-net kmod-usb-net-cdc-eem kmod-usb-net-cdc-ether kmod-usb-net-cdc-ncm kmod-usb-net-cdc-subset kmod-usb-net-ipheth kmod-usb-storage kmod-usb2
    opkg install kmod-usb3 kmod-wireguard libatomic1 libattr libavahi-client ath10k-board-qca4019 ath10k-board-qca9888 ath10k-board-qca988x ath10k-firmware-qca4019-ct ath10k-firmware-qca9888-ct ath10k-firmware-qca988x-ct attr avahi-dbus-daemon base-files block-mount busybox ca-bundle
    opkg install certtool cgi-io dbus dropbear e2fsprogs fdisk firewall fstools fwtool getrandom hostapd-common ip-full ip6tables ipq-wifi-linksys_mr8300-v0 ipset iptables iptables-mod-ipopt iw iwinfo jshn jsonfilter kernel kmod-ath kmod-ath10k-ct kmod-ath9k kmod-ath9k-common
    opkg install kmod-cfg80211 kmod-crypto-crc32c kmod-crypto-hash kmod-crypto-kpp kmod-crypto-lib-blake2s kmod-crypto-lib-chacha20 kmod-crypto-lib-chacha20poly1305 kmod-crypto-lib-curve25519 kmod-crypto-lib-poly1305 kmod-fs-exfat kmod-fs-ext4 kmod-gpio-button-hotplug kmod-hwmon-core
    opkg install kmod-ip6tables kmod-ipt-conntrack kmod-ipt-core kmod-ipt-ipopt kmod-ipt-ipset kmod-ipt-nat kmod-ipt-offload kmod-leds-gpio kmod-lib-crc-ccitt kmod-lib-crc16 kmod-mac80211 kmod-mii kmod-nf-conntrack kmod-nf-conntrack6 kmod-nf-flow kmod-nf-ipt kmod-nf-ipt6 kmod-nf-nat kmod-nf-reject
    opkg install kmod-nf-reject6 kmod-nfnetlink kmod-nls-base kmod-ppp kmod-pppoe kmod-pppox kmod-scsi-core kmod-slhc kmod-tun kmod-udptunnel4 kmod-udptunnel6 kmod-usb-core kmod-usb-dwc3 kmod-usb-dwc3-qcom kmod-usb-ehci kmod-usb-ledtrig-usbport kmod-usb-net kmod-usb-net-cdc-eem kmod-usb-net-cdc-ether
    opkg install kmod-usb-net-cdc-ncm kmod-usb-net-cdc-subset kmod-usb-net-ipheth kmod-usb-storage kmod-usb2 kmod-usb3 kmod-wireguard libatomic1 libattr libavahi-client minidlna mtd netifd odhcp6c odhcpd-ipv6only openconnect openssh-sftp-client
    opkg install openvpn-openssl openwrt-keyring opkg ppp ppp-mod-pppoe procd resolveip rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci rpcd-mod-rrdns samba4-libs samba4-server socksify swconfig terminfo ubi-utils uboot-envtools ubox ubus ubusd uci uclient-fetch uhttpd uhttpd-mod-ubus
    opkg install urandom-seed urngd usbids usbmuxd usbutils usign vpn-policy-routing vpnbypass vpnc-scripts watchcat wireguard-tools wireless-regdb wpad-basic-wolfssl
    opkg install zlib kmod-usb-storage block-mount luci-app-minidlna kmod-fs-ext4 kmod-fs-exfat fdisk luci-compat luci-lib-ipkg luci-proto-wireguard luci-app-wireguard luci-i18n-wireguard-en vpn-policy-routing vpnbypass vpnc-scripts watchcat wg-installer-client
    opkg install wireguard-tools luci-app-openvpn luci-app-vpn-policy-routing luci-app-vpnbypass luci-app-watchcat luci-app-wireguard
    opkg install jshn ip ipset iptables iptables-mod-tproxy resolveip

    if [[ -f /etc/config/dhcp && -f /etc/config/dhcp.pr ]]; then 
        rm -f /etc/config/dhcp
        mv /etc/config/dhcp.pr /etc/config/dhcp
        service dnsmasq restart
    fi

else

    # Install our packages
    log_say "Fix dnsmasq problem"
    opkg remove dnsmasq
    # The point here is to verify that we have a dhcp.pr file to put into place after the packages install
    # so if we have dhcp but no dhcp.pr, we move dhcp to dhcp.pr
    # if we have dhcp and dhcp.pr, we remove dhcp
    if [[ -f /etc/config/dhcp && ! -f /etc/config/dhcp.pr ]]; then
        log_say "/etc/config/dhcp exists but no /etc/config/dhcp.pr so we use our existing dhcp file"
        mv /etc/config/dhcp /etc/config/dhcp.pr
    elif [[ -f /etc/config/dhcp && -f /etc/config/dhcp.pr ]]; then
        log_say "/etc/config/dhcp exists and /etc/config/dhcp.pr exists so we remove the existing dhcp file"
        rm /etc/config/dhcp
    fi
    
    log_say "fixing mod dashboard css"
    opkg install luci-mod-dashboard
    rm /www/luci-static/resources/view/dashboard/css/custom.css
    cp -f /etc/custom.css /www/luci-static/resources/view/dashboard/css/custom.css
    log_say "Install LXC and related packages"
    opkg install lxc lxc-attach lxc-auto lxc-autostart lxc-cgroup lxc-checkconfig lxc-common lxc-config lxc-configs 
    opkg install lxc-console lxc-copy lxc-create lxc-destroy lxc-device lxc-execute lxc-freeze lxc-hooks lxc-info lxc-init 
    opkg install lxc-ls lxc-monitor lxc-monitord lxc-snapshot lxc-start lxc-stop lxc-templates lxc-top lxc-unfreeze 
    opkg install lxc-unprivileged lxc-unshare lxc-user-nic lxc-usernsexec lxc-wait liblxc luci-app-lxc luci-i18n-lxc-en rpcd-mod-lxc
    mkdir /opt/docker2/compose/lxc
    rm /etc/lxc/default.conf
    rm /etc/lxc/lxc.conf
    touch /etc/lxc/default.conf
    touch /etc/lxc/lxc.conf
cat > /etc/lxc/lxc.conf <<EOL
lxc.lxcpath = /opt/docker2/compose/lxc
EOL
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
    log_say "Installing packages with Docker Support"
    ## V2RAYA INSTALLER PREP ##
    log_say "Preparing for V2rayA..."
    ## Remove DNSMasq
    opkg remove dnsmasq
    ## Install DNSMasq
    opkg install dnsmasq-full
    ## Install V2ray Repo and packages
    log_say "Installing V2rayA..."
    wget https://downloads.sourceforge.net/project/v2raya/openwrt/v2raya.pub -O /etc/opkg/keys/94cc2a834fb0aa03
    echo "src/gz v2raya https://downloads.sourceforge.net/project/v2raya/openwrt/$(. /etc/openwrt_release && echo "$DISTRIB_ARCH")" | tee -a "/etc/opkg/customfeeds.conf"
    opkg update
    opkg install v2raya
    # Install the following packages for the iptables-based firewall3 (command -v fw3)
    opkg install iptables-mod-conntrack-extra \
    iptables-mod-extra \
    iptables-mod-filter \
    iptables-mod-tproxy \
    kmod-ipt-nat6
    # Check your firewall implementation
    # Install the following packages for the nftables-based firewall4 (command -v fw4)
    # Generally speaking, install them on OpenWrt 22.03 and later
    opkg install kmod-nft-tproxy
    #Install V2rayA
    opkg install xray-core
    opkg install luci-app-v2raya
    
    ## INSTALL MESH  ##
    log_say "Installing Mesh Packages..."
    opkg install hostapd-utils hostapd
    opkg install luci-app-shortcutmenu luci-app-poweroff luci-app-wizard luci-app-openwisp openwisp-monitoring openwisp-config
    opkg remove wpad wpad-basic wpad-basic-openssl wpad-basic-wolfssl wpad-wolfssl 
    opkg install wpad-mesh-openssl --force-depends
    opkg install kmod-batman-adv
    opkg install batctl 
    opkg install avahi-autoipd batctl-full luci-app-dawn
    opkg install /etc/luci-app-easymesh_2.4_all.ipk --force-depends
    opkg install /etc/luci-proto-batman-adv_git-22.104.47289-0a762fd_all.ipk
    log_say "fixing mod dashboard css"
    opkg install luci-mod-dashboard
    rm /www/luci-static/resources/view/dashboard/css/custom.css
    cp -f /etc/custom.css /www/luci-static/resources/view/dashboard/css/custom.css
    opkg install attr avahi-dbus-daemon base-files busybox ca-bundle certtool cgi-io curl davfs2 dbus luci-app-uhttpd frpc luci-app-frpc kmod-rtl8xxxu rtl8188eu-firmware kmod-rtl8192ce kmod-rtl8192cu kmod-rtl8192de dcwapd
    opkg install jq bash git-http kmod-mwifiex-pcie kmod-mwifiex-sdio kmod-rtl8723bs kmod-rtlwifi kmod-rtlwifi-btcoexist kmod-rtlwifi-pci kmod-rtlwifi-usb kmod-wil6210 libuwifi
    opkg install kmod-8139cp kmod-8139too kmod-net-rtl8192su kmod-phy-realtek kmod-r8169 kmod-rtl8180 kmod-rtl8187 kmod-rtl8192c-common kmod-rtl8192ce kmod-rtl8192cu kmod-rtl8192de kmod-rtl8192se kmod-rtl8812au-ct kmod-rtl8821ae kmod-rtl8xxxu kmod-rtlwifi kmod-rtlwifi-btcoexist
    opkg install kmod-rtlwifi-pci kmod-rtlwifi-usb kmod-rtw88 kmod-sound-hda-codec-realtek kmod-switch-rtl8306 kmod-switch-rtl8366-smi kmod-switch-rtl8366rb kmod-switch-rtl8366s kmod-switch-rtl8367b kmod-usb-net-rtl8150 kmod-usb-net-rtl8152 librtlsdr r8169-firmware rtl-sdr rtl8188eu-firmware
    opkg install rtl8192ce-firmware rtl8192cu-firmware rtl8192de-firmware rtl8192eu-firmware rtl8192se-firmware rtl8192su-firmware rtl8723au-firmware rtl8723bu-firmware rtl8821ae-firmware rtl8822be-firmware rtl8822ce-firmware rtl_433 kmod-mt76 kmod-mt76-connac kmod-mt76-core kmod-mt76-usb kmod-mt7603
    opkg install kmod-mt7615-common kmod-mt7615-firmware kmod-mt7615e kmod-mt7663-firmware-ap kmod-mt7663-firmware-sta kmod-mt7663-usb-sdio kmod-mt7663s kmod-mt7663u kmod-mt76x0-common kmod-mt76x02-common kmod-mt76x02-usb kmod-mt76x0e kmod-mt76x0u kmod-mt76x2 kmod-mt76x2-common kmod-mt76x2u kmod-mt7915e kmod-ar5523
    opkg install kmod-mt7921e mt7601u-firmware kmod-ath kmod-brcmutil kmod-libertas-sdio kmod-libertas-spi kmod-libertas-usb kmod-mt76 kmod-mt76-connac kmod-mt76-core kmod-mt76-usb kmod-mt7601u kmod-mt7603 kmod-mt7615-common kmod-mt7615e kmod-mt7663s kmod-mt7663u kmod-mt76x0-common kmod-mt76x02-common kmod-mt76x02-usb
    opkg install kmod-mt76x0e kmod-mt76x0u kmod-mt76x2 kmod-mt76x2-common kmod-mt76x2u kmod-mt7915e kmod-mt7921e iwlwifi-firmware-iwl100 iwlwifi-firmware-iwl1000 iwlwifi-firmware-iwl105 iwlwifi-firmware-iwl135 iwlwifi-firmware-iwl2000 iwlwifi-firmware-iwl2030 iwlwifi-firmware-iwl3160 iwlwifi-firmware-iwl3168
    opkg install iwlwifi-firmware-iwl5000 iwlwifi-firmware-iwl5150 iwlwifi-firmware-iwl6000g2 iwlwifi-firmware-iwl6000g2a iwlwifi-firmware-iwl6000g2b iwlwifi-firmware-iwl6050 iwlwifi-firmware-iwl7260 iwlwifi-firmware-iwl7265 iwlwifi-firmware-iwl7265d iwlwifi-firmware-iwl8260c iwlwifi-firmware-iwl8265 iwlwifi-firmware-iwl9000
    opkg install iwlwifi-firmware-iwl9260 kmod-iwlwifi kmod-mwifiex-pcie kmod-mwifiex-sdio kmod-rtl8723bs kmod-rtlwifi kmod-rtlwifi-btcoexist kmod-rtlwifi-pci kmod-rtlwifi-usb kmod-wil6210 libuwifi luci-app-wifischedule
    opkg install dnsmasq dropbear firewall fstools fuse3-utils fwtool getrandom git glib2 gnupg hostapd-common ip-full ip6tables ipset iptables iptables-mod-ipopt iw iwinfo jshn adblock luci-app-adblock wwan iwlwifi-firmware-iwl6000g2
    opkg install jsonfilter kernel kmod-bluetooth kmod-btmrvl kmod-cfg80211 kmod-crypto-aead kmod-crypto-ccm kmod-crypto-cmac kmod-crypto-ctr kmod-crypto-ecb kmod-crypto-ecdh kmod-crypto-gcm kmod-crypto-gf128 kmod-usb-wdm kmod-usb-net-ipheth
    opkg install kmod-crypto-ghash kmod-crypto-hash kmod-crypto-hmac kmod-crypto-kpp kmod-crypto-lib-blake2s kmod-crypto-lib-chacha20 kmod-crypto-lib-chacha20poly1305 kmod-crypto-lib-curve25519 kmod-usb-net-asix-ax88179 kmod-usb-net-rtl8152
    opkg install kmod-crypto-lib-poly1305 kmod-crypto-manager kmod-crypto-null kmod-crypto-rng kmod-crypto-seqiv kmod-crypto-sha256 kmod-fuse kmod-gpio-button-hotplug kmod-hid kmod-input-core kmod-input-evdev kmod-mt76x02-usb iwlwifi-firmware-iwl6000g2
    opkg install kmod-ip6tables kmod-ipt-conntrack kmod-ipt-core kmod-ipt-ipopt kmod-ipt-ipset kmod-ipt-nat kmod-ipt-offload kmod-lib-crc-ccitt kmod-lib-crc16 kmod-mac80211 kmod-mmc kmod-mwifiex-sdio luci-compat luci-lib-ipkg rtl8192ce-firmware
    opkg install kmod-mwlwifi kmod-nf-conntrack kmod-nf-conntrack6 kmod-nf-flow kmod-nf-ipt kmod-nf-ipt6 kmod-nf-nat kmod-nf-reject kmod-nf-reject6 kmod-nfnetlink kmod-nls-base kmod-ppp kmod-pppoe kmod-pppox kmod-brcmfmac usbmuxd
    opkg install kmod-regmap-core kmod-slhc kmod-tun kmod-udptunnel4 kmod-udptunnel6 kmod-usb-core kmod-wireguard libatomic1 libattr libavahi-client libavahi-dbus-support libblkid1 libbpf0 libbz2-1.0 libc kmod-usb-net-rndis
    opkg install libcap libcurl4 libdaemon libdbus libelf1 libev libevdev libevent2-7 libexif libexpat libffi libffmpeg-mini libflac libfuse1 libfuse3-3 libgcc1 libgmp10 libgnutls libhttp-parser kmod-usb-net-cdc-ncm kmod-rtlwifi-pci
    opkg install libid3tag libip4tc2 libip6tc2 libipset13 libiwinfo-data libiwinfo-lua libiwinfo20210430 libjpeg-turbo libjson-c5 liblua5.1.5 liblucihttp-lua liblucihttp0 liblzo2 libmbedtls12 libmnl0 luci-app-ttyd kmod-usb-net-cdc-eem kmod-rtlwifi
    opkg install libmount1 libncurses6 libneon libnettle8 libnftnl11 libnghttp2-14 libnl-tiny1 libogg0 libopenssl-conf libopenssl1.1 libowipcalc libpam libpcre libpopt0 libprotobuf-c libpthread libreadline8 kmod-usb-net-cdc-subset
    opkg install librt libsmartcols1 libsodium libsqlite3-0 libtasn1 libtirpc libubus-lua libuci-lua libuci20130104 libuclient20201210 libudev-zero liburing libusb-1.0-0 libustream-wolfssl20201210 libuuid1 kmod-usb-net-cdc-ether kmod-rtl8xxxu
    opkg install libvorbis libxml2 libxtables12 logd lua luci luci-app-attendedsysupgrade luci-app-firewall luci-app-minidlna luci-app-openvpn luci-app-opkg luci-app-samba4 kmod-usb-net-hso kmod-net-rtl8192su kmod-usb-net-rtl8150
    opkg install luci-app-wireguard luci-base luci-compat luci-i18n-firewall-en kmod-usb2 kmod-usb3 rtl8192eu-firmware
    opkg install luci-i18n-wireguard-en luci-lib-base luci-lib-ip luci-lib-ipkg luci-lib-jsonc luci-lib-nixio luci-mod-admin-full luci-mod-network luci-mod-status luci-mod-system luci-proto-ipv6 mt7601u-firmware
    opkg install luci-proto-ppp luci-proto-wireguard luci-theme-bootstrap luci-theme-material luci-theme-openwrt-2020 minidlna mount-utils mtd mwifiex-sdio-firmware mwlwifi-firmware-88w8964 kmod-mt76 kmod-rtl8187
    opkg install netifd odhcp6c odhcpd-ipv6only openssh-sftp-client openssh-sftp-server openssl-util openvpn-openssl openwrt-keyring opkg owipcalc ppp ppp-mod-pppoe procd procd-seccomp kmod-mt7601u
    opkg install procd-ujail python3-base python3-email python3-light python3-logging python3-openssl python3-pysocks python3-urllib resolveip rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci luci-app-statistics
    opkg install rpcd-mod-rpcsys rpcd-mod-rrdns rsync samba4-libs samba4-server nano sshfs terminfo ubi-utils kmod-usb-net-asix-ax88179 luci-app-commands
    opkg install uboot-envtools ubox ubus ubusd uci uclient-fetch uhttpd uhttpd-mod-ubus urandom-seed urngd usbutils usign vpnbypass vpnc-scripts watchcat wg-installer-client wget-ssl
    opkg install wireguard-tools wireless-regdb wpad zlib kmod-usb-storage block-mount samba4-server luci-app-samba4 luci-app-minidlna minidlna kmod-fs-ext4 kmod-fs-exfat e2fsprogs fdisk luci-app-nlbwmon luci-app-vnstat
    opkg install dnsmasq-full
    opkg install luci-app-fileassistant
    opkg install luci-app-plugsy
    opkg remove tgsstp
    opkg remove tgopenvpn
    opkg remove tganyconnect
    opkg remove luci-app-shortcutmenu
    opkg remove luci-app-webtop
    opkg remove luci-app-nextcloud
    opkg remove luci-app-seafile
    opkg install /etc/luci-app-megamedia_git-23.251.42088-cdbc3cb_all.ipk
    opkg install /etc/luci-app-webtop_git-23.251.39494-1b8885d_all.ipk
    opkg install /etc/luci-app-shortcutmenu_git-23.251.38707-d0c2502_all.ipk
    opkg install /etc/tgsstp_git-23.251.15457-c428b60_all.ipk
    opkg install /etc/tganyconnect_git-23.251.15499-9fafcfe_all.ipk
    opkg install /etc/tgopenvpn_git-23.251.15416-16e4649_all.ipk
    opkg install /etc/luci-app-seafile_git-23.251.23441-a760a47_all.ipk
    opkg install /etc/luci-app-nextcloud_git-23.251.23529-ee6a72e_all.ipk
    opkg install /etc/luci-app-whoogle_git-23.250.10284-cdadc0b_all.ipk
    opkg install /etc/luci-theme-privaterouter_0.3.1-8_all.ipk

    if [[ -f /etc/config/dhcp && -f /etc/config/dhcp.pr ]]; then 
        rm -f /etc/config/dhcp
        mv /etc/config/dhcp.pr /etc/config/dhcp
        service dnsmasq restart
    fi    

# End of our /etc/pr-mini check
fi


log_say "Removing NFtables and Firewall4, Replacing with legacy packages"
opkg remove firewall4 --force-removal-of-dependent-packages
opkg install firewall
opkg install luci-app-firewall
opkg install luci-i18n-firewall-en
opkg install luci
opkg install luci-ssl
opkg install iptables-mod-extra kmod-br-netfilter kmod-ikconfig kmod-nf-conntrack-netlink kmod-nf-ipvs kmod-nf-nat iptables-zz-legacy

# Mini Routers do not install docker packages
[ -f /etc/pr-mini ] || {
    log_say "Installing Docker related packages"
    opkg install dockerd
    opkg install docker-compose
    opkg install luci-app-dockerman
    tar xzvf /etc/dockerman.tar.gz -C /usr/lib/lua/luci/model/cbi/dockerman/
    chmod +x /usr/bin/dockerdeploy
}

sed -i '/root/s/\/bin\/ash/\/bin\/bash/g' /etc/passwd

log_say "PrivateRouter update complete!"

exit 0
