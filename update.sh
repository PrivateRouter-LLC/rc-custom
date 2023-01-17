#!/usr/bin/env bash
# Board detection stub for custom update.sh

# Get the model of the device we are on
BOARD_CHECK="$(cat /tmp/sysinfo/model)"
chmod +x /root/rc-custom/*.sh

if [[ "${BOARD_CHECK}" == *"GL-MT300N-V2"* ]]; then
    bash /root/rc-custom/mt300nv2.sh
elif [[ "${BOARD_CHECK}" == *"GL-MT300N"* ]]; then
    bash /root/rc-custom/mt300n.sh
elif [[ "${BOARD_CHECK}" == *"MR8300"* ]]; then
    bash /root/rc-custom/mr8300.sh
elif [[ "${BOARD_CHECK}" == *"GL-AR300M"* ]]; then
    bash /root/rc-custom/ar300m16.sh
elif [[ "${BOARD_CHECK}" == *"GL-AR750S"* ]]; then
    bash /root/rc-custom/ar750s.sh
elif [[ "${BOARD_CHECK}" == *"GL-AR750S (NOR)"* ]]; then
    bash /root/rc-custom/ar750s_ext.sh
elif [[ "${BOARD_CHECK}" == *"WRT32X"* ]]; then
    bash /root/rc-custom/wrt32x.sh
elif [[ "${BOARD_CHECK}" == *"Archer C7 v5"* ]]; then
    bash /root/rc-custom/archerc7v5.sh
else
    bash /root/rc-custom/generic.sh
fi
