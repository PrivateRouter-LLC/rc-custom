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

# Verify we are connected to the Internet
is_connected() {
    ping -q -c3 1.1.1.1 >/dev/null 2>&1
    return $?
}

# Log to the system log and echo if needed
log_say()
{
    SCRIPT_NAME=$(basename "$0")
    echo "${SCRIPT_NAME}: ${1}"
    logger "${SCRIPT_NAME}: ${1}"
    echo "${SCRIPT_NAME}: ${1}" >> "/tmp/${SCRIPT_NAME}.log"
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
is_connected || { log_say "We are not connected to the Internet to run our update script." ; exit 0; }

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
            bash "${UPDATER_LOCATION}/first-run.sh" &
        }
    else
        log_say "We were not able to download our update scripts"
        #reboot
        exit 1
    fi
else
    log_say "Update Script Update is not needed"
fi # UPDATE_NEEDED check

# Command to wait for opkg to finish
wait_for_opkg() {
  while pgrep -x opkg >/dev/null; do
    log_say "Waiting for opkg to finish..."
    sleep 1
  done
  log_say "opkg is released, our turn!"
}

# Wait for opkg to finish
wait_for_opkg

log_say "Waiting for opkg update to succesfully run..."
while ! opkg update >/dev/null 2>&1; do
    log_say "... Waiting for opkg update to succesfully run ..."
    sleep 1
done

opkg update
if [ $? -eq 0 ]; then
    log_say "*** opkg update completed successfully. ***"
else
    log_say "*** opkg update DID NOT complete successfully. ***"
    exit 1
fi

# Install system packages as needed
log_say "Checking Required Packages..."

PACKAGE_LIST="modemmanager kmod-usb-serial kmod-usb-net kmod-usb-serial-wwan kmod-usb-serial-option kmod-usb-net-qmi-wwan kmod-usb-net-cdc-mbim luci-proto-modemmanager luci-app-shortcutmenu luci-app-poweroff luci-app-wizard"  # List of packages separated by space

for package in $PACKAGE_LIST; do
    if ! opkg list-installed | grep -q "^$package -"; then
        log_say "Installing $package..."
        opkg install $package
        if [ $? -eq 0 ]; then
            log_say "$package installed successfully."
        else
            log_say "Failed to install $package."
        fi
    else
        echo "$package is already installed."
    fi
done

# Check if the 'wwan' interface exists in the network configuration
if uci -q get network.wwan && [ -n "$(uci -q get network.wwan.device)" ]; then
    log_say "Interface 'wwan' already exists and has a device value."
else
    log_say "Attempting to create 'wwan' interface..."

    # Get ModemManager modem path
    modem_path=$(mmcli -L | awk '{print $1}')
    usb_device_path="no"
    if [ "$modem_path" != "no" ]; then
        # Get USB device path from modem path
        usb_device_path=$(mmcli -m "$modem_path" | awk '/device:/ {print $NF}')

        # Create 'wwan' interface
        uci set network.wwan=interface
        uci set network.wwan.proto='modemmanager'
        uci set network.wwan.auth='none'
        uci set network.wwan.iptype='ipv4v6'
        uci set network.wwan.device="${usb_device_path}"
        # End user can add the interface to the WAN firewall zone to use it for Internet access
        #uci add_list firewall.wan.network='wwan'
        uci commit
        
        log_say "Interface 'wwan' created."
    else
        log_say "ModemManager modem not found."
    fi

fi

log_say "PrivateRouter update complete!"

exit 0
