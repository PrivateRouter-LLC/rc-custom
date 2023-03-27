#!/usr/bin/env bash
# /etc/udpate.sh PrivateRouter Update Script

# Verify we are connected to the Internet
is_connected() {
    ping -q -c3 1.1.1.1 >/dev/null 2>&1
    return $?
}

# Log to the system log and echo if needed
log_say()
{
    echo "${1}"
    logger "${1}"
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

# Set our router's dns
echo "nameserver 1.1.1.1" > /etc/resolv.conf

# Check if we are connected, if not, exit
[ is_connected ] || { log_say "We are not connected to the Internet to run our update script." ; exit 0; }

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

#Go Go Packages
 opkg install base-files blockdev busybox ca-bundle ca-certificates cgi-io curl davfs2 dnsmasq dropbear e2fsprogs f2fsck firewall fstools fwtool getrandom hostapd-common ip-full ip6tables ipset iptables iptables-mod-ipopt iw iwinfo jshn jsonfilter kernel kmod-ata-

   opkg install ahci-mtk kmod-ata-core kmod-bluetooth kmod-btmtkuart kmod-cfg80211 kmod-crypto-aead kmod-crypto-ccm kmod-crypto-cmac kmod-crypto-ctr kmod-crypto-ecb kmod-crypto-ecdh kmod-crypto-gcm kmod-crypto-gf128 kmod-crypto-ghash kmod-crypto-hash kmod-crypto-hmac

   opkg install kmod-crypto-kpp kmod-crypto-lib-blake2s kmod-crypto-lib-chacha20 kmod-crypto-lib-chacha20poly1305 kmod-crypto-lib-curve25519 kmod-crypto-lib-poly1305 kmod-crypto-manager kmod-crypto-null kmod-crypto-rng kmod-crypto-seqiv kmod-crypto-sha256 kmod-

   opkg install fuse kmod-gpio-button-hotplug kmod-hid kmod-hwmon-core kmod-input-core kmod-input-evdev kmod-ip6tables kmod-ipt-conntrack kmod-ipt-core kmod-ipt-ipopt kmod-ipt-ipset kmod-ipt-nat kmod-ipt-offload kmod-leds-gpio kmod-lib-crc-ccitt kmod-lib-crc16 kmod-

   opkg install mac80211 kmod-mt76-connac kmod-mt76-core kmod-mt7615-common kmod-mt7615-firmware kmod-mt7615e kmod-nf-conntrack kmod-nf-conntrack6 kmod-nf-flow kmod-nf-ipt kmod-nf-ipt6 kmod-nf-nat kmod-nf-reject kmod-nf-reject6 kmod-nfnetlink kmod-nls-base kmod-ppp

   opkg install kmod-pppoe kmod-pppox kmod-regmap-core kmod-scsi-core kmod-slhc kmod-tun kmod-udptunnel4 kmod-udptunnel6 kmod-usb-core kmod-usb-xhci-hcd kmod-usb3 kmod-wireguard libblkid1 libblobmsg-json20210819 libbpf0 libbz2-1.0 libc libcomerr0 libcurl4 libelf1

   opkg install libevent2-7 libexif libexpat libext2fs2 libf2fs6 libffmpeg-mini libflac libfuse1 libgcc1 libid3tag libip4tc2 libip6tc2 libipset13 libiwinfo-data libiwinfo-lua libiwinfo20210430 libjpeg-turbo libjson-c5 libjson-script20210819 liblua5.1.5 liblucihttp-lua

   opkg install liblucihttp0 liblzo2 libmnl0 libneon libnghttp2-14 libnl-tiny1 libogg0 libopenssl1.1 libowipcalc libpthread librt libsqlite3-0 libss2 libubox20210819 libubus-lua libubus20210630 libuci20130104 libuclient20201210 libunbound libuuid1 libvorbis

   opkg install libxtables12 logd lua luci luci-app-firewall luci-app-minidlna luci-app-openvpn luci-app-opkg luci-app-unbound luci-app-wireguard luci-base luci-compat luci-i18n-wireguard-en luci-lib-base luci-lib-ip luci-lib-ipkg luci-lib-jsonc luci-lib-nixio luci-mod-

   opkg install admin-full luci-mod-network luci-mod-status luci-mod-system luci-proto-ipv6 luci-proto-ppp luci-proto-wireguard luci-theme-bootstrap luci-theme-openwrt-2020 minidlna mkf2fs mt7622bt-firmware mtd netifd odhcp6c odhcpd-ipv6only openssh-sftp-server

   opkg install openvpn-openssl openwrt-keyring opkg owipcalc ppp ppp-mod-pppoe procd resolveip rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci rpcd-mod-rrdns ubi-utils uboot-envtools ubox ubus ubusd uci uclient-fetch uhttpd uhttpd-mod-ubus unbound-daemon urandom-seed

   opkg install urngd usign vpn-policy-routing wg-installer-client wireguard-tools wireless-regdb zlib zlib kmod-usb-storage block-mount luci-app-minidlna kmod-fs-ext4 kmod-fs-exfat fdisk

   opkg install wireguard-tools wireless-regdb wpad zlib kmod-usb-storage block-mount samba4-server luci-app-samba4 luci-app-minidlna minidlna kmod-fs-ext4 kmod-fs-exfat e2fsprogs fdisk
   echo "Installing TorGuard Wireguard..."
   opkg install /etc/luci-app-tgwireguard_1.0.3-1_all.ipk
   echo "Removing NFtables and Firewall4, Replacing with legacy packages"
   opkg remove firewall4 --force-removal-of-dependent-packages
   opkg install firewall
   opkg install luci-app-firewall
   opkg install dockerd
   opkg install docker-compose
   opkg install luci-app-dockerman
   opkg install luci-i18n-firewall-en
   opkg install luci
   opkg install luci-ssl

   tar xzvf /etc/dockerman.tar.gz -C /usr/lib/lua/luci/model/cbi/dockerman/
   sed -i '/root/s/\/bin\/ash/\/bin\/bash/g' /etc/passwd
   chmod +x /usr/bin/dockerdeploy
   echo "PrivateRouter update complete!"

## INSTALL ROUTER APP STORE ##
log_say "Installing Router App Store..."
opkg install tgrouterappstore luci-app-shortcutmenu luci-app-poweroff luci-app-wizard tgwireguard

log_say "PrivateRouter update complete!"

exit 0
