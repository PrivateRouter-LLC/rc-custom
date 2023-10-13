#!/usr/bin/env bash


setup_lxc() {
    # Wait until we can run opkg update, if it fails try again
    while ! opkg update >/dev/null 2>&1; do
        log_say "... Waiting to update opkg ..."
        sleep 1
    done
    
    log_say "Install LXC and related packages"

    # List of our packages to install
    PACKAGE_LIST="lxc lxc-attach lxc-auto lxc-autostart lxc-cgroup lxc-checkconfig lxc-common lxc-config lxc-configs lxc-console lxc-copy lxc-create lxc-destroy lxc-device lxc-execute lxc-freeze lxc-hooks lxc-info lxc-init lxc-ls lxc-monitor lxc-monitord lxc-snapshot lxc-start lxc-stop lxc-templates lxc-top lxc-unfreeze lxc-unprivileged lxc-unshare lxc-user-nic lxc-usernsexec lxc-wait liblxc luci-app-lxc luci-i18n-lxc-en rpcd-mod-lxc xz tar gnupg cgroupfs-mount cgroup-tools kmod-ikconfig kmod-veth gnupg2-utils gnupg2-dirmngr "

    count=$(echo "$PACKAGE_LIST" | wc -w)
    log_say "Packages to install: ${count}"

    for package in $PACKAGE_LIST; do
        if ! opkg list-installed | grep -q "^$package -"; then
            echo "Installing $package..."
            opkg install $package
            if [ $? -eq 0 ]; then
                echo "$package installed successfully."
            else
                echo "Failed to install $package."
            fi
        else
            echo "$package is already installed."
        fi
    done


    mkdir -p /opt/docker2/compose/lxc
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
        local MAC=$(hexdump -n 6 -v -e '/1 ":%02x"' /dev/urandom | sed 's/^://')

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
}