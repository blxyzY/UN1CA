SKIPUNZIP=1

REMOVE_FROM_WORK_DIR()
{
    local FILE_PATH="$1"

    if [ -e "$FILE_PATH" ]; then
        local FILE
        local PARTITION
        FILE="$(echo -n "$FILE_PATH" | sed "s.$WORK_DIR/..")"
        PARTITION="$(echo -n "$FILE" | cut -d "/" -f 1)"

        echo "Debloating /$FILE"
        rm -rf "$FILE_PATH"

        if [[ "$PARTITION" == "system" ]] && [[ "$FILE" == *".camera.samsung.so" ]]; then
            sed -i "/$(basename "$FILE")/d" "$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt"
        fi
        if [[ "$PARTITION" == "system" ]] && [[ "$FILE" == *".arcsoft.so" ]]; then
            sed -i "/$(basename "$FILE")/d" "$WORK_DIR/system/system/etc/public.libraries-arcsoft.txt"
        fi

        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}

#Fix system camera libs
BLOBS_LIST="
system/lib64/libDeepDocRectify.camera.samsung.so
system/lib64/libDocDeblur.camera.samsung.so
system/lib64/libDocDeblur.enhanceX.samsung.so
system/lib64/libDocObjectRemoval.camera.samsung.so
system/lib64/libDocObjectRemoval.enhanceX.samsung.so
system/lib64/libDocShadowRemoval.arcsoft.so
system/lib64/libImageSegmenter_v1.camera.samsung.so
system/lib64/libVideoClassifier.camera.samsung.so
system/lib64/libWideDistortionCorrection.camera.samsung.so
system/lib64/lib_pet_detection.arcsoft.so
system/lib64/libacz_hhdr.arcsoft.so
system/lib64/libaiclearzoom_raw.arcsoft.so
system/lib64/libaiclearzoomraw_wrapper_v1.camera.samsung.so
system/lib64/libtensorflowLite2_11_0_dynamic_camera.so
system/lib64/libtflite2.myfilters.camera.samsung.so
"
for blob in $BLOBS_LIST
do
    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/$blob"
done

echo "Add stock camera libs"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/public.libraries-camera.samsung.txt" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libImageCropper.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libMyFilter.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libPortraitDistortionCorrection.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libPortraitDistortionCorrectionCali.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhigh_dynamic_range.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/liblow_light_hdr.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libtensorflowLite.myfilter.camera.samsung.so" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libtensorflowlite_inference_api.myfilter.camera.samsung.so" 0 0 644 "u:object_r:system_file:s0"
