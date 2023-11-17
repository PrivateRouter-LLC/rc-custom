#!/usr/bin/env bash
# Board detection stub for custom update.sh

# Get the model of the device we are on
BOARD_CHECK="$(cat /tmp/sysinfo/model)"
chmod +x /root/rc-custom/*.sh

# Print current time to a temp file for tracking
date > /tmp/last_update

if [[ "${BOARD_CHECK}" == *"GL-MT300N-V2"* ]]; then
    bash /root/rc-custom/mt300nv2.sh
elif [[ "${BOARD_CHECK}" == *"GL-AR750S (NOR)"* ]]; then
    bash /root/rc-custom/ar750s_ext.sh
elif [[ "${BOARD_CHECK}" == *"GL-AR750"* ]]; then
    bash /root/rc-custom/ar750.sh
elif [[ "${BOARD_CHECK}" == *"GL-MT300N"* ]]; then
    bash /root/rc-custom/mt300n.sh
elif [[ "${BOARD_CHECK}" == *"MR8300"* ]]; then
    bash /root/rc-custom/mr8300.sh
elif [[ "${BOARD_CHECK}" == *"EA8300"* ]]; then
    bash /root/rc-custom/ea8300.sh
elif [[ "${BOARD_CHECK}" == *"R8000"* ]]; then
    bash /root/rc-custom/r8000.sh
elif [[ "${BOARD_CHECK}" == *"R7800"* ]]; then
    bash /root/rc-custom/r7800.sh
elif [[ "${BOARD_CHECK}" == *"GL-AR300M"* ]]; then
    bash /root/rc-custom/ar300m16.sh
elif [[ "${BOARD_CHECK}" == *"orangepizero"* ]]; then
    bash /root/rc-custom/orangepizero.sh
elif [[ "${BOARD_CHECK}" == *"GL-AR750S"* ]]; then
    bash /root/rc-custom/ar750s.sh
elif [[ "${BOARD_CHECK}" == *"GL-MT1300"* ]]; then
    bash /root/rc-custom/mt1300.sh
elif [[ "${BOARD_CHECK}" == *"GL-E750"* ]]; then
    bash /root/rc-custom/gle750.sh
elif [[ "${BOARD_CHECK}" == *"GL-XE300"* ]]; then
    bash /root/rc-custom/xe300.sh
elif [[ "${BOARD_CHECK}" == *"GL-BL1300"* ]]; then
    bash /root/rc-custom/bl1300.sh
elif [[ "${BOARD_CHECK}" == *"GL-A1300"* ]]; then
    bash /root/rc-custom/a1300.sh
elif [[ "${BOARD_CHECK}" == *"WRT32X"* ]]; then
    bash /root/rc-custom/wrt32x.sh
elif [[ "${BOARD_CHECK}" == *"WRT3200ACM"* ]]; then
    bash /root/rc-custom/wrt3200acm.sh
elif [[ "${BOARD_CHECK}" == *"RT-AC88U"* ]]; then
    bash /root/rc-custom/ac88u.sh
elif [[ "${BOARD_CHECK}" == *"1200ac"* ]]; then
    bash /root/rc-custom/wrt1200ac.sh
elif [[ "${BOARD_CHECK}" == *"1900ac"* ]]; then
    bash /root/rc-custom/wrt1900ac.sh
elif [[ "${BOARD_CHECK}" == *"E8450"* ]]; then
    bash /root/rc-custom/e8450.sh
elif [[ "${BOARD_CHECK}" == *"E7350"* ]]; then
    bash /root/rc-custom/e8450.sh
elif [[ "${BOARD_CHECK}" == *"Archer C7 v"* ]]; then
    # For right now all the archers run the v5 script
    bash /root/rc-custom/archerc7v5.sh
else
    bash /root/rc-custom/generic.sh
fi
