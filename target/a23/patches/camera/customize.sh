FW_PATH="${TARGET_FIRMWARE_PATH:-out/fw/SM-A235F_THL}"
PREBUILTS_DIR="$SRC_DIR/prebuilts/samsung"

ADD_CAMERA_LIB()
{
    local REL="$1"
    local SRC

    if [ -f "$FW_PATH/system/$REL" ]; then
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$REL" 0 0 644 "u:object_r:system_lib_file:s0"
        return 0
    fi

    for SRC in a73xqxx r9qxxx; do
        if [ -f "$PREBUILTS_DIR/$SRC/system/$REL" ]; then
            LOGW "$REL not present in the A23 firmware; using prebuilts/samsung/$SRC"
            ADD_TO_WORK_DIR "$SRC" "system" "$REL" 0 0 644 "u:object_r:system_lib_file:s0"
            return 0
        fi
    done

    LOGW "$REL Not found in A23 firmware or prebuilts; skipped.."
    find "$FW_PATH" "$PREBUILTS_DIR" -name "$(basename "$REL")" 2> /dev/null | head -n 5 | sed 's/^/      /' >&2 || true
}

# Add Polarr libs
ADD_TO_WORK_DIR "a73xqxx" "system" "system/etc/public.libraries-polarr.txt" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libBestComposition.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libFeature.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libPolarrSnap.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libTracking.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libYuv.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"

# Add camera libs
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib64/libSceneDetector_v1.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
EVAL "echo \"libSceneDetector_v1.camera.samsung.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""
ADD_CAMERA_LIB "system/lib64/liblow_light_hdr.arcsoft.so"
ADD_CAMERA_LIB "system/lib64/libhigh_dynamic_range.arcsoft.so"
ADD_CAMERA_LIB "system/lib64/libhumantracking.arcsoft.so"
ADD_CAMERA_LIB "system/lib64/libhumantracking_util.camera.samsung.so"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libsecimaging_pdk.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_CAMERA_LIB "system/lib64/libveengine.arcsoft.so"

LOG "- Patching /vendor/ueventd.rc"
EVAL "cat \"$MODPATH/ueventd.rc.diff\" >> \"$WORK_DIR/vendor/ueventd.rc\""

