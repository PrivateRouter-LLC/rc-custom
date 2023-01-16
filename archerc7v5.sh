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
opkg install opkg install openvpn-openssl luci-app-openvpn base-files usbutils busybox ca-bundle cgi-io dnsmasq dropbear openssh-sftp-client firewall fstools fwtool getrandom hostapd-common ip6tables iptables iw iwinfo jshn jsonfilter

opkg install kernel kmod-ath kmod-ath9k kmod-ath9k-common kmod-cfg80211 kmod-crypto-hash kmod-crypto-kpp kmod-crypto-lib-blake2s kmod-crypto-lib-chacha20 kmod-crypto-lib-chacha20poly1305 kmod-crypto-lib-curve25519

opkg install kmod-crypto-lib-poly1305 kmod-gpio-button-hotplug kmod-ip6tables kmod-ipt-conntrack kmod-ipt-core kmod-ipt-nat kmod-ipt-offload kmod-lib-crc-ccitt kmod-mac80211 kmod-nf-conntrack kmod-nf-conntrack6 kmod-nf-flow kmod-nf-ipt

opkg install kmod-nf-ipt6 kmod-nf-nat kmod-nf-reject kmod-nf-reject6 kmod-nls-base kmod-phy-ath79-usb kmod-ppp kmod-pppoe kmod-pppox

opkg install kmod-slhc kmod-udptunnel4 kmod-udptunnel6 kmod-usb-core kmod-usb-ehci kmod-usb-ledtrig-usbport kmod-usb2 kmod-wireguard libblobmsg-json20210516 libc libgcc1 libip4tc2 libip6tc2 libiwinfo-data libiwinfo-lua libiwinfo20210430 libjson-c5

opkg install libjson-script20210516 liblua5.1.5 liblucihttp-lua liblucihttp0 libnl-tiny1 libopenssl1.1 libpthread libubox20210516

opkg install libubus-lua libubus20210630 libuci20130104 libuclient20201210 libustream-wolfssl20201210 libwolfssl4.8.1.66253b90 libxtables12 logd lua luci luci-app-firewall luci-app-opkg luci-app-wireguard luci-base luci-compat

opkg install luci-lib-base luci-lib-ip luci-lib-ipkg luci-lib-jsonc luci-lib-nixio luci-mod-admin-full luci-mod-network luci-mod-status luci-mod-system

opkg install zlib kmod-usb-storage block-mount luci-app-minidlna minidlna kmod-fs-ext4 kmod-fs-exfat e2fsprogs fdisk
echo "Installing TorGuard Wireguard..."
opkg install /etc/luci-app-tgwireguard_1.0.3-1_all.ipk

## V2RAYA INSTALLER ##
echo "Installing V2rayA..."
## download

opkg update; opkg install unzip wget-ssl

## Remove DNSMasq

opkg remove dnsmasq

opkg install dnsmasq-full

opkg install v2raya

opkg install /etc/luci-app-v2raya_6_all.ipk

echo "PrivateRouter update complete!"

exit 0
