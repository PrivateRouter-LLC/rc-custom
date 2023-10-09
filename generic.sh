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

# Set this to 0 to disable Tankman theme
TANKMAN_FLAG=1

# This file is our marker to know the first run init script has already ran
INIT_MARKER="/usr/lib/opkg/info/tankman.list"

# If we are online and our tankman flag is enabled (and we have not already been ran before), do our setup script
[ ${TANKMAN_FLAG} = "1" ] && [ ! -f "${INIT_MARKER}" ] && [ -d /pr-installers ] && {
        #Install Argon Tankman theme
        log_say "Installing custom Argon Tankman Theme"
        opkg install /pr-installers/luci-theme-argon*.ipk
        opkg install /pr-installers/luci-app-argon*.ipk

        tar xzvf /pr-installers/logo.tar.gz -C /www/luci-static/argon/
        tar xzvf /pr-installers/dockerman.tar.gz -C /usr/lib/lua/luci/model/cbi/dockerman/

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

[ -f /pr-installers/custom.css ] && {
    log_say "fixing mod dashboard css"
    opkg install luci-mod-dashboard
    rm /www/luci-static/resources/view/dashboard/css/custom.css
    cp -f /pr-installers/custom.css /www/luci-static/resources/view/dashboard/css/custom.css
}

## INSTALL MESH  ##
log_say "Installing Mesh Packages..."
opkg install hostapd-utils hostapd
opkg install luci-app-shortcutmenu luci-app-poweroff luci-app-wizard luci-app-openwisp openwisp-monitoring openwisp-config
opkg remove wpad wpad-basic wpad-basic-openssl wpad-basic-wolfssl wpad-wolfssl 
opkg install wpad-mesh-openssl --force-depends
opkg install kmod-batman-adv
opkg install batctl 
opkg install avahi-autoipd batctl-full luci-app-dawn
# opkg install /pr-installers/luci-app-easymesh_2.4_all.ipk --force-depends
# opkg install /pr-installers/luci-proto-batman-adv_git-22.104.47289-0a762fd_all.ipk

# opkg remove tgsstp
# opkg remove tgopenvpn
# opkg remove tganyconnect
# opkg remove luci-app-shortcutmenu
# opkg remove luci-app-webtop
# opkg remove luci-app-nextcloud
# opkg remove luci-app-seafile
# opkg install /pr-installers/luci-app-megamedia_git-23.251.42088-cdbc3cb_all.ipk
# opkg install /pr-installers/luci-app-webtop_git-23.251.39494-1b8885d_all.ipk
# opkg install /pr-installers/luci-app-shortcutmenu_git-23.251.38707-d0c2502_all.ipk
# opkg install /pr-installers/tgsstp_git-23.251.15457-c428b60_all.ipk
# opkg install /pr-installers/tganyconnect_git-23.251.15499-9fafcfe_all.ipk
# opkg install /pr-installers/tgopenvpn_git-23.251.15416-16e4649_all.ipk
# opkg install /pr-installers/luci-app-seafile_git-23.251.23441-a760a47_all.ipk
# opkg install /pr-installers/luci-app-nextcloud_git-23.251.23529-ee6a72e_all.ipk
# opkg install /pr-installers/luci-app-whoogle_git-23.250.10284-cdadc0b_all.ipk
# opkg install /pr-installers/luci-theme-privaterouter_0.3.1-8_all.ipk

log_say "Checking if firewall4 is installed"
if ! opkg list-installed | grep -q "^firewall4 "; then
    log_say "Removing NFtables and Firewall4, Replacing with legacy packages"
    opkg remove firewall4 --force-removal-of-dependent-packages
    opkg install firewall luci-app-firewall luci-i18n-firewall-en luci luci-ssl iptables-mod-extra kmod-br-netfilter kmod-ikconfig kmod-nf-conntrack-netlink kmod-nf-ipvs kmod-nf-nat iptables-zz-legacy
fi


if ! opkg list-installed | grep -q "^lxc "; then
    # Get current directory and set it as a variable
    CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    # Source the file with lxc install function
    [ -f "${CURRENT_DIR}/extras/lxc_install.sh" ] && { 
        source "${CURRENT_DIR}/extras/lxc_install.sh";
        log_say "Installing LXC Packages (external script)";
        setup_lxc;
    } || {
        log_say "LXC Install Script not found";
    }
fi

# Check /etc/passwd to see if root's shell is ash, if it is, change it to bash
if grep -q "/root:/bin/ash" /etc/passwd; then
    log_say "Changing root's shell from ash to bash"
    sed -i '/root/s/\/bin\/ash/\/bin\/bash/g' /etc/passwd
fi

log_say "PrivateRouter update complete!"

exit 0
