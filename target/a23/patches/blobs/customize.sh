FW_PATH="${TARGET_FIRMWARE_PATH:-out/fw/SM-A235F_THL}"

ADD_FM_BLOB()
{
    local NAME="$1"
    local MODE="$2"
    local SRC

    if [ -f "$FW_PATH/system/system/lib64/$NAME" ]; then
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/$NAME" 0 0 "$MODE" "u:object_r:system_lib_file:s0"
        return 0
    fi

    if [ -f "$FW_PATH/system_ext/lib64/$NAME" ]; then
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/$NAME" 0 0 "$MODE" "u:object_r:system_lib_file:s0"
        return 0
    fi

    for SRC in \
        "$FW_PATH/system/system/system_ext/lib64/$NAME" \
        "$FW_PATH/system/system_ext/lib64/$NAME"
    do
        if [ -f "$SRC" ]; then
            mkdir -p "$FW_PATH/system_ext/lib64"
            cp -f "$SRC" "$FW_PATH/system_ext/lib64/$NAME"
            ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/$NAME" 0 0 "$MODE" "u:object_r:system_lib_file:s0"
            rm -f "$FW_PATH/system_ext/lib64/$NAME"
            return 0
        fi
    done

    echo "  ! $NAME is missing skip." >&2
    echo "    Firmware search results:" >&2
    find "$FW_PATH" -name "${NAME%-V*}*" 2>/dev/null | head -n 5 | sed 's/^/      /' >&2 || true
}

LOG_STEP_IN "- Adding FM Radio blobs"
ADD_FM_BLOB "libfmradio_jni.so" 644
ADD_FM_BLOB "vendor.qti.hardware.fm-V1-ndk.so" 755
ADD_FM_BLOB "fm_helium.so" 755
ADD_FM_BLOB "libfm-hci.so" 755
ADD_FM_BLOB "vendor.qti.hardware.fm@1.0.so" 755
ADD_FM_BLOB "android.hardware.bluetooth.audio-V3-ndk.so" 755
ADD_FM_BLOB "android.hardware.audio.common-V2-ndk.so" 755
ADD_FM_BLOB "android.media.audio.common.types-V2-ndk.so" 755
rmdir "$FW_PATH/system_ext/lib64" "$FW_PATH/system_ext" 2>/dev/null || true
LOG_STEP_OUT

LOG_STEP_IN "- Removing Google Hotword Enrollment blobs"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentOKGoogleEx4HEXAGON"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentXGoogleEx4HEXAGON"
LOG_STEP_OUT