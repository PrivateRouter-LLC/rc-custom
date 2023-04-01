#!/usr/bin/env bash
# PrivateRouter Update Script

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

opkg update
# Check if the file /etc/pr-mini exists, if it does we are on a device with smaller storage, otherwise we install all the packages
if [ -f /etc/pr-mini ]; then

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
    opkg install jshn ip ipset iptables iptables-mod-tproxy resolveip dnsmasq-full

else

    log_say "Installing packages with Docker Support"
    opkg install hostapd-utils hostapd attr avahi-dbus-daemon base-files busybox ca-bundle certtool cgi-io curl davfs2 dbus luci-app-uhttpd frpc luci-app-frpc kmod-rtl8xxxu rtl8188eu-firmware kmod-rtl8192ce kmod-rtl8192cu kmod-rtl8192de dcwapd
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
    opkg install luci-app-vpn-policy-routing luci-app-vpnbypass luci-app-watchcat luci-app-wireguard luci-base luci-compat luci-i18n-firewall-en kmod-usb2 kmod-usb3 rtl8192eu-firmware
    opkg install luci-i18n-wireguard-en luci-lib-base luci-lib-ip luci-lib-ipkg luci-lib-jsonc luci-lib-nixio luci-mod-admin-full luci-mod-network luci-mod-status luci-mod-system luci-proto-ipv6 mt7601u-firmware
    opkg install luci-proto-ppp luci-proto-wireguard luci-theme-bootstrap luci-theme-material luci-theme-openwrt-2020 minidlna mount-utils mtd mwifiex-sdio-firmware mwlwifi-firmware-88w8964 kmod-mt76 kmod-rtl8187
    opkg install netifd odhcp6c odhcpd-ipv6only openssh-sftp-client openssh-sftp-server openssl-util openvpn-openssl openwrt-keyring opkg owipcalc ppp ppp-mod-pppoe procd procd-seccomp kmod-mt7601u
    opkg install procd-ujail python3-base python3-email python3-light python3-logging python3-openssl python3-pysocks python3-urllib resolveip rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci luci-app-statistics
    opkg install rpcd-mod-rpcsys rpcd-mod-rrdns rsync samba4-libs samba4-server nano sshfs terminfo ubi-utils kmod-usb-net-asix-ax88179 luci-mod-dashboard luci-app-commands
    opkg install uboot-envtools ubox ubus ubusd uci uclient-fetch uhttpd uhttpd-mod-ubus urandom-seed urngd usbutils usign vpnbypass vpnc-scripts watchcat wg-installer-client wget-ssl
    opkg install wireguard-tools wireless-regdb wpad zlib kmod-usb-storage block-mount samba4-server luci-app-samba4 luci-app-minidlna minidlna kmod-fs-ext4 kmod-fs-exfat e2fsprogs fdisk luci-app-nlbwmon luci-app-vnstat
    opkg install luci-lib-taskd taskd tgappstore luci-lib-xterm luci-lib-fs luci-app-filetransfer luci-app-wizard luci-app-docker-backup luci-app-shortcutmenu tgwireguard luci-app-nextcloud
    opkg install luci-app-syncthing luci-app-diskman luci-app-jellyfin luci-app-homeassistant luci-app-poweroff tgdocker kmod-veth uxc procd-ujail procd-ujail-console
    
    # Install extra languages
    log_say "Installing extra languages"
    opkg install luci-i18n-base-ar luci-i18n-base-bg luci-i18n-base-bn luci-i18n-base-ca luci-i18n-base-cs luci-i18n-base-da luci-i18n-base-de luci-i18n-base-el luci-i18n-base-en luci-i18n-base-es luci-i18n-base-fi luci-i18n-base-fr luci-i18n-base-he luci-i18n-base-hi luci-i18n-base-hu luci-i18n-base-it luci-i18n-base-ja 
    opkg install  luci-i18n-base-ko luci-i18n-base-mr luci-i18n-base-ms luci-i18n-base-nl luci-i18n-base-no luci-i18n-base-pl luci-i18n-base-pt luci-i18n-base-pt-br luci-i18n-base-ro luci-i18n-base-ru luci-i18n-base-sk luci-i18n-base-sv luci-i18n-base-tr luci-i18n-base-uk luci-i18n-base-vi luci-i18n-base-zh-cn luci-i18n-base-zh-tw

# End of our /etc/pr-mini check
fi


log_say "Removing NFtables and Firewall4, Replacing with legacy packages"
opkg remove firewall4 --force-removal-of-dependent-packages
opkg install firewall
opkg install luci-app-firewall
opkg install luci-i18n-firewall-en
opkg install luci
opkg install luci-ssl

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

# Always install our repo's public key to the router
log_say "Installing v2raya repo public key"
wget -qO /tmp/v2raya.pub https://osdn.net/projects/v2raya/storage/openwrt/v2raya.pub
opkg-key add /tmp/v2raya.pub
rm /tmp/v2raya.pub

# Always update the repo
log_say "Add v2raya repo"
sed -i '/v2raya/d' /etc/opkg/customfeeds.conf 
echo "src/gz v2raya https://osdn.net/projects/v2raya/storage/openwrt/$(. /etc/openwrt_release && echo "$DISTRIB_ARCH")" >> /etc/opkg/customfeeds.conf

# This script is used to update the packages in the repo
opkg update
[ $? -eq 0 ] && {
    log_say "Installing v2raya and luci-app-v2raya"
    opkg install v2raya
    opkg install luci-app-v2raya
}

#Adding Cloud Backgrounds
tar xzvf /etc/logo.tar.gz -C /www/luci-static/argon/
tar xzvf /etc/cloud.tar.gz -C /www/luci-static/argon/background/
tar xzvf /etc/cloud1.tar.gz -C /www/luci-static/argon/background/
tar xzvf /etc/cloud2.tar.gz -C /www/luci-static/argon/background/
opkg install /etc/tgappstore_3.0.0-6_all.ipk

log_say "PrivateRouter update complete!"

exit 0
