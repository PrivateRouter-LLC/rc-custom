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

log_say "Installing specific packages Modem Manager Packages & Configure IP"
opkg install modemmanager kmod-usb-serial kmod-usb-net kmod-usb-serial-wwan kmod-usb-serial-option kmod-usb-net-qmi-wwan kmod-usb-net-cdc-mbim luci-proto-modemmanager
ifconfig wwan0 down
echo Y > /sys/class/net/wwan0/qmi/raw_ip
ifconfig wwan0 up

## INSTALL ROUTER APP STORE ##
log_say "Installing Router App Store..."
opkg install tgrouterappstore luci-app-shortcutmenu luci-app-poweroff luci-app-wizard

log_say "PrivateRouter update complete!"

exit 0
