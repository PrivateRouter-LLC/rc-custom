#!/usr/bin/env bash
# Board detection stub for custom update.sh

# Get the model of the device we are on
BOARD_CHECK="$(cat /tmp/sysinfo/model)"
chmod +x /root/rc-custom/*.sh

if [[ "${BOARD_CHECK}" == *"MR8300"* ]]; then
    bash /root/rc-custom/mr8300.sh
elif [[ "${BOARD_CHECK}" == *"GL-MT300N-V2"* ]]; then
    bash /root/rc-custom/mt300nv2.sh
else
    bash /root/rc-custom/generic.sh
fi