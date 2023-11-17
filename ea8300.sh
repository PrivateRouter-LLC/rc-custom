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

opkg update

opkg install tgrouterappstore luci-app-shortcutmenu luci-app-poweroff luci-app-wizard
opkg remove wpad-basic wpad-basic-openssl wpad-basic-wolfssl wpad-wolfssl wpad-mbedtls wpad-basic-mbedtls
opkg install wpad-mesh-openssl kmod-batman-adv batctl avahi-autoipd batctl-full luci-app-dawn
opkg install /etc/luci-proto-batman-adv_git-22.104.47289-0a762fd_all.ipk
 
opkg install wireguard-tools ath10k-board-qca4019 ath10k-board-qca9888 ath10k-board-qca988x ath10k-firmware-qca4019-ct ath10k-firmware-qca9888-ct ath10k-firmware-qca988x-ct attr avahi-dbus-daemon base-files block-mount busybox ca-bundle certtool cgi-io dbus dnsmasq dropbear e2fsprogs fdisk firewall fstools fwtool

opkg install getrandom hostapd-common ip-full ip6tables ipq-wifi-linksys_mr8300-v0 ipset iptables iptables-mod-ipopt iw iwinfo jshn jsonfilter kernel kmod-ath kmod-ath10k-ct kmod-ath9k kmod-ath9k-common kmod-cfg80211 kmod-crypto-crc32c kmod-crypto-hash kmod-crypto-kpp kmod-crypto-lib-blake2s kmod-crypto-lib-chacha20 kmod-crypto-lib-chacha20poly1305 kmod-crypto-lib-curve25519 kmod-crypto-lib-poly1305 kmod-fs-exfat kmod-fs-ext4

opkg install kmod-gpio-button-hotplug kmod-hwmon-core kmod-ip6tables kmod-ipt-conntrack kmod-ipt-core kmod-ipt-ipopt kmod-ipt-ipset kmod-ipt-nat kmod-ipt-offload kmod-leds-gpio kmod-lib-crc-ccitt kmod-lib-crc16 kmod-mac80211 kmod-mii kmod-nf-conntrack

opkg install kmod-nf-conntrack6 kmod-nf-flow kmod-nf-ipt kmod-nf-ipt6 kmod-nf-nat kmod-nf-reject kmod-nf-reject6 kmod-nfnetlink kmod-nls-base kmod-ppp kmod-pppoe kmod-pppox kmod-scsi-core kmod-slhc kmod-tun

opkg install kmod-udptunnel4 kmod-udptunnel6 kmod-usb-core kmod-usb-dwc3 kmod-usb-dwc3-qcom kmod-usb-ehci kmod-usb-ledtrig-usbport kmod-usb-net kmod-usb-net-cdc-eem kmod-usb-net-cdc-ether kmod-usb-net-cdc-ncm kmod-usb-net-cdc-subset kmod-usb-net-ipheth kmod-usb-storage kmod-usb2

opkg install kmod-usb3 kmod-wireguard libatomic1 libattr libavahi-client ath10k-board-qca4019 ath10k-board-qca9888 ath10k-board-qca988x ath10k-firmware-qca4019-ct ath10k-firmware-qca9888-ct ath10k-firmware-qca988x-ct attr avahi-dbus-daemon base-files block-mount busybox ca-bundle

opkg install certtool cgi-io dbus dnsmasq-full dropbear e2fsprogs fdisk firewall fstools fwtool getrandom hostapd-common ip-full ip6tables ipq-wifi-linksys_mr8300-v0 ipset iptables iptables-mod-ipopt iw iwinfo jshn jsonfilter kernel kmod-ath kmod-ath10k-ct kmod-ath9k kmod-ath9k-common

opkg install kmod-cfg80211 kmod-crypto-crc32c kmod-crypto-hash kmod-crypto-kpp kmod-crypto-lib-blake2s kmod-crypto-lib-chacha20 kmod-crypto-lib-chacha20poly1305 kmod-crypto-lib-curve25519 kmod-crypto-lib-poly1305 kmod-fs-exfat kmod-fs-ext4 kmod-gpio-button-hotplug kmod-hwmon-core

opkg install kmod-ip6tables kmod-ipt-conntrack kmod-ipt-core kmod-ipt-ipopt kmod-ipt-ipset kmod-ipt-nat kmod-ipt-offload kmod-leds-gpio kmod-lib-crc-ccitt kmod-lib-crc16 kmod-mac80211 kmod-mii kmod-nf-conntrack kmod-nf-conntrack6 kmod-nf-flow kmod-nf-ipt kmod-nf-ipt6 kmod-nf-nat kmod-nf-reject

opkg install kmod-nf-reject6 kmod-nfnetlink kmod-nls-base kmod-ppp kmod-pppoe kmod-pppox kmod-scsi-core kmod-slhc kmod-tun kmod-udptunnel4 kmod-udptunnel6 kmod-usb-core kmod-usb-dwc3 kmod-usb-dwc3-qcom kmod-usb-ehci kmod-usb-ledtrig-usbport kmod-usb-net kmod-usb-net-cdc-eem kmod-usb-net-cdc-ether

opkg install kmod-usb-net-cdc-ncm kmod-usb-net-cdc-subset kmod-usb-net-ipheth kmod-usb-storage kmod-usb2 kmod-usb3 kmod-wireguard libatomic1 libattr libavahi-client minidlna mtd netifd odhcp6c odhcpd-ipv6only openssh-sftp-client

opkg install openvpn-openssl openwrt-keyring opkg ppp ppp-mod-pppoe procd resolveip rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci rpcd-mod-rrdns swconfig terminfo ubi-utils uboot-envtools ubox ubus ubusd uci uclient-fetch uhttpd uhttpd-mod-ubus

opkg install urandom-seed urngd usbids usbmuxd usbutils usign watchcat wireguard-tools wireless-regdb wpad-basic-wolfssl

opkg install zlib kmod-usb-storage block-mount luci-app-minidlna kmod-fs-ext4 kmod-fs-exfat fdisk luci-compat luci-lib-ipkg luci-proto-wireguard luci-app-wireguard luci-i18n-wireguard-en watchcat wg-installer-client

opkg install wireguard-tools luci-app-openvpn luci-app-watchcat luci-app-wireguard

## V2RAYA INSTALLER PREP ##
log_say "Preparing for V2rayA..."
## download

## Remove DNSMasq

opkg remove dnsmasq

opkg install dnsmasq-full

## INSTALL ROUTER APP STORE ##
log_say "Installing Router App Store..."
opkg install tgrouterappstore luci-app-shortcutmenu luci-app-poweroff luci-app-wizard tgwireguard

log_say "PrivateRouter update complete!"

exit 0
