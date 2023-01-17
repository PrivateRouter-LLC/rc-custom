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
elif [[ "${BOARD_CHECK}" == *"R8000"* ]]; then
    bash /root/rc-custom/r8000.sh
elif [[ "${BOARD_CHECK}" == *"GL-AR300M"* ]]; then
    bash /root/rc-custom/ar300m16.sh
elif [[ "${BOARD_CHECK}" == *"GL-AR750"* ]]; then
    bash /root/rc-custom/ar750.sh
elif [[ "${BOARD_CHECK}" == *"GL-AR750S"* ]]; then
    bash /root/rc-custom/ar750s.sh
elif [[ "${BOARD_CHECK}" == *"GL-MT1300"* ]]; then
    bash /root/rc-custom/mt1300.sh
elif [[ "${BOARD_CHECK}" == *"GL-E750"* ]]; then
    bash /root/rc-custom/gle750.sh
elif [[ "${BOARD_CHECK}" == *"GL-BL1300"* ]]; then
    bash /root/rc-custom/bl1300.sh
elif [[ "${BOARD_CHECK}" == *"GL-AR750S (NOR)"* ]]; then
    bash /root/rc-custom/ar750s_ext.sh
elif [[ "${BOARD_CHECK}" == *"WRT32X"* ]]; then
    bash /root/rc-custom/wrt32x.sh
elif [[ "${BOARD_CHECK}" == *"1200ac"* ]]; then
    bash /root/rc-custom/wrt1200ac.sh
elif [[ "${BOARD_CHECK}" == *"1900ac"* ]]; then
    bash /root/rc-custom/wrt1900ac.sh
elif [[ "${BOARD_CHECK}" == *"Archer C7 v5"* ]]; then
    bash /root/rc-custom/archerc7v5.sh
else
    bash /root/rc-custom/generic.sh
fi
