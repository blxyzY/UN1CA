# Copyright (c) 2026 Majaahh, 7jari, Noir
# SPDX-License-Identifier: GPL-3.0-or-later

# Firmware
if [ -d "$WORK_DIR/vendor/firmware/SM-A236E" ]; then
    EVAL "rm -rf \"$WORK_DIR/vendor/firmware/SM-A236E\""
fi
EVAL "mkdir -p \"$WORK_DIR/vendor/firmware/SM-A236E\""
SET_METADATA "vendor" "firmware/SM-A236E" 0 2000 755 "u:object_r:vendor_firmware_file:s0"

for f in "ipa_fws.b01" "ipa_fws.elf" "ipa_fws.mdt" "wlanmdsp.mbn"; do
    LOG "- Moving /vendor/firmware/$f to /vendor/firmware/SM-A236E/$f"
    EVAL "mv \"$WORK_DIR/vendor/firmware/$f\" \"$WORK_DIR/vendor/firmware/SM-A236E/$f\""
    SET_METADATA "vendor" "firmware/SM-A236E/$f" 0 0 644 "u:object_r:vendor_firmware_file:s0"

    LOG "- Creating dummy /vendor/firmware/$f"
    EVAL "touch \"$WORK_DIR/vendor/firmware/$f\""
done

LOG "- Adding SELinux entries"
{
    echo "(allow init_30_0 vendor_firmware_file (file (mounton)))"
    echo "(allow priv_app_30_0 vendor_firmware_file (file (getattr)))"
} >> "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil" || return 1
