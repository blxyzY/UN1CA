# shellcheck disable=SC2034
SKIPUNZIP=1

# [
BACKPORT_SF_PROPS()
{
    local FILE="$WORK_DIR/vendor/build.prop"
    if [ -f "$WORK_DIR/vendor/default.prop" ]; then
        FILE="$WORK_DIR/vendor/default.prop"
    fi

    if [ ! -f "$FILE" ]; then
        LOGW "File not found: ${FILE//$SRC_DIR\/}; skipping SF prop backport"
        return 1
    fi

    local PROP
    local VALUE

    if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "34" ]; then
        PATCHED=true

        PROP="ro.surface_flinger.enable_frame_rate_override"
        VALUE="$(test "$TARGET_LCD_CONFIG_HFR_MODE" -gt "1" && echo "true" || echo "false")"

        if [ ! "$(GET_PROP "vendor" "$PROP")" ]; then
            LOG "- Adding \"$PROP\" prop with \"$VALUE\" in ${FILE//$WORK_DIR/}"
            EVAL "sed -i \"/persist.sys.usb.config/i $PROP=$VALUE\" \"$FILE\"" || LOGW "EVAL failed, skipping this step"
        fi
    fi

    if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "35" ]; then
        PATCHED=true

        PROP="ro.surface_flinger.set_display_power_timer_ms"

        if [ "$(GET_PROP "vendor" "$PROP")" ]; then
            SET_PROP "vendor" "$PROP" --delete || LOGW "SET_PROP failed, skipping this step"
        fi

        PROP="ro.surface_flinger.enable_frame_rate_override"
        if [ "$(GET_PROP "vendor" "ro.surface_flinger.set_idle_timer_ms")" ]; then
            PROP="ro.surface_flinger.set_idle_timer_ms"
        fi
        VALUE="$(GET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate")"
        if [ ! "$VALUE" ]; then
            VALUE="$(test "$TARGET_LCD_CONFIG_HFR_MODE" -gt "1" && echo "true" || echo "false")"
        fi

        if [[ "$(sed -n "/$PROP/{x;p;d;}; x" "$FILE")" != *"use_content_detection_for_refresh_rate"* ]]; then
            if [ ! "$(GET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate")" ]; then
                LOG "- Adding \"ro.surface_flinger.use_content_detection_for_refresh_rate\" prop with \"$VALUE\" in ${FILE//$WORK_DIR/}"
            else
                EVAL "sed -i \"/use_content_detection_for_refresh_rate/d\" \"$FILE\"" || LOGW "EVAL failed, skipping this step"
            fi
            EVAL "sed -i \"/$PROP/i ro.surface_flinger.use_content_detection_for_refresh_rate=$VALUE\" \"$FILE\"" || LOGW "EVAL failed, skipping this step"
        fi

        PROP="debug.sf.show_refresh_rate_overlay_render_rate"
        VALUE="true"
        if [ ! "$(GET_PROP "vendor" "$PROP")" ]; then
            LOG "- Adding \"$PROP\" prop with \"$VALUE\" in ${FILE//$WORK_DIR/}"
            EVAL "sed -i \"/ro.surface_flinger.use_content_detection_for_refresh_rate/i $PROP=$VALUE\" \"$FILE\"" || LOGW "EVAL failed, skipping this step"
        fi

        PROP="ro.surface_flinger.game_default_frame_rate_override"
        VALUE="60"
        if [ ! "$(GET_PROP "vendor" "$PROP")" ]; then
            LOG "- Adding \"$PROP\" prop with \"$VALUE\" in ${FILE//$WORK_DIR/}"
            EVAL "sed -i \"/debug.sf.show_refresh_rate_overlay_render_rate/a $PROP=$VALUE\" \"$FILE\"" || LOGW "EVAL failed, skipping this step"
        fi
    fi
}

EXTRACT_KERNEL_IMAGE() {
    if [ -d "$TMP_DIR" ]; then
        EVAL "rm -rf \"$TMP_DIR\"" || LOGW "EVAL failed, skipping this step"
    fi
    EVAL "mkdir -p \"$TMP_DIR\"" || LOGW "EVAL failed, skipping this step"
    EVAL "cp -a \"$WORK_DIR/kernel/boot.img\" \"$TMP_DIR/boot.img\"" || LOGW "EVAL failed, skipping this step"

    EVAL "unpack_bootimg --boot_img \"$TMP_DIR/boot.img\" --out \"$TMP_DIR/out\" 2>&1" || LOGW "EVAL failed, skipping this step"

    EVAL "rm \"$TMP_DIR/boot.img\"" || LOGW "EVAL failed, skipping this step"

    if [[ "$(READ_BYTES_AT "$TMP_DIR/out/kernel" "0" "2")" == "8b1f" ]]; then
        EVAL "cat \"$TMP_DIR/out/kernel\" | gzip -d > \"$TMP_DIR/out/tmp\" && mv -f \"$TMP_DIR/out/tmp\" \"$TMP_DIR/out/kernel\"" || LOGW "EVAL failed, skipping this step"
    fi
}

EXTRACT_KERNEL_MODULES() {
    if [ -d "$TMP_DIR" ]; then
        EVAL "rm -rf \"$TMP_DIR\"" || LOGW "EVAL failed, skipping this step"
    fi
    EVAL "mkdir -p \"$TMP_DIR\"" || LOGW "EVAL failed, skipping this step"
    EVAL "cp -a \"$WORK_DIR/kernel/vendor_boot.img\" \"$TMP_DIR/vendor_boot.img\"" || LOGW "EVAL failed, skipping this step"

    EVAL "unpack_bootimg --boot_img \"$TMP_DIR/vendor_boot.img\" --out \"$TMP_DIR/out\" 2>&1" || LOGW "EVAL failed, skipping this step"

    EVAL "rm \"$TMP_DIR/vendor_boot.img\"" || LOGW "EVAL failed, skipping this step"

    while IFS= read -r f; do
        if [[ "$(READ_BYTES_AT "$f" "0" "4")" == "184c2102" ]]; then
            EVAL "cat \"$f\" | lz4 -d > \"$TMP_DIR/out/tmp\" && mv -f \"$TMP_DIR/out/tmp\" \"$f\"" || LOGW "EVAL failed, skipping this step"
        elif [[ "$(READ_BYTES_AT "$f" "0" "2")" == "8b1f" ]]; then
            EVAL "cat \"$f\" | gzip -d > \"$TMP_DIR/out/tmp\" && mv -f \"$TMP_DIR/out/tmp\" \"$f\"" || LOGW "EVAL failed, skipping this step"
        fi
    done < <(find "$TMP_DIR/out" -maxdepth 1 -type f -name "vendor_ramdisk*")
}
# ]

PATCHED=false

# Pre-API 34
# - Add ro.surface_flinger.enable_frame_rate_override if missing
#
# Pre-API 35
# - Place ro.surface_flinger.use_content_detection_for_refresh_rate correctly
# - Add debug.sf.show_refresh_rate_overlay_render_rate if missing
# - Add ro.surface_flinger.game_default_frame_rate_override if missing
BACKPORT_SF_PROPS || LOGW "BACKPORT_SF_PROPS failed, skipping this step"

# Support legacy Face HAL (pre-API 34)
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "34" ]; then
    if [ ! -f "$WORK_DIR/vendor/bin/hw/vendor.samsung.hardware.biometrics.face@3.0-service" ]; then
        PATCHED=true
        APPLY_PATCH "system" "system/framework/services.jar" \
            "$MODPATH/face/services.jar/0001-Fallback-to-Face-HIDL-2.0.patch" || LOGW "APPLY_PATCH failed, skipping this step"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali/com/android/server/biometrics/sensors/face/hidl/HidlToAidlCallbackConverter.smali" "replaceall" \
            "V3_0" \
            "V2_0" \
            > /dev/null || LOGW "SMALI_PATCH failed, skipping this step"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali/com/android/server/biometrics/sensors/face/hidl/TestHal.smali" "replaceall" \
            "V3_0" \
            "V2_0" \
            > /dev/null || LOGW "SMALI_PATCH failed, skipping this step"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali/com/android/server/biometrics/sensors/face/aidl/SemFaceServiceExImpl\$\$ExternalSyntheticLambda6.smali" "remove" || LOGW "SMALI_PATCH failed, skipping this step"
        LOG "- Removing \"smali_classes2/vendor/samsung/hardware/biometrics/face/V3_0/ISehBiometricsFace.smali\" from /system/system/framework/services.jar"
        EVAL "rm \"$APKTOOL_DIR/system/framework/services.jar/smali_classes2/vendor/samsung/hardware/biometrics/face/V3_0/ISehBiometricsFace.smali\"" || LOGW "EVAL failed, skipping this step"
        LOG "- Removing \"smali_classes2/vendor/samsung/hardware/biometrics/face/V3_0/ISehBiometricsFace\$Proxy.smali\" from /system/system/framework/services.jar"
        EVAL "rm \"$APKTOOL_DIR/system/framework/services.jar/smali_classes2/vendor/samsung/hardware/biometrics/face/V3_0/ISehBiometricsFace\\\$Proxy.smali\"" || LOGW "EVAL failed, skipping this step"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/vendor/samsung/hardware/biometrics/face/V3_0/ISehBiometricsFace\$Stub\$1.smali" "remove" || LOGW "SMALI_PATCH failed, skipping this step"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/vendor/samsung/hardware/biometrics/face/V3_0/ISehBiometricsFaceClientCallback\$Proxy.smali" "remove" || LOGW "SMALI_PATCH failed, skipping this step"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/vendor/samsung/hardware/biometrics/face/V3_0/ISehBiometricsFaceClientCallback.smali" "remove" || LOGW "SMALI_PATCH failed, skipping this step"
    fi
fi

# Support legacy SehLights HAL (pre-API 35)
# - Check for [lsr wD, wS, #0x18] to determine if the newer HAL is already in place
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "35" ]; then
    if [ -f "$WORK_DIR/vendor/bin/hw/vendor.samsung.hardware.light-service" ] && \
            ! xxd -p -c 4 "$WORK_DIR/vendor/bin/hw/vendor.samsung.hardware.light-service" | grep -q "1853$"; then
        PATCHED=true
        APPLY_PATCH "system" "system/framework/services.jar" \
            "$MODPATH/lights/services.jar/0001-Backport-legacy-SehLights-HAL-code.patch" || LOGW "APPLY_PATCH failed, skipping this step"
    fi
fi

# Ensure config_num_physical_slots is configured (pre-API 36)
# if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "36" ]; then
#     if [ ! "$(GET_PROP "ro.telephony.sim_slots.count")" ] && \
#             ! grep -q "ro.telephony.sim_slots.count" "$WORK_DIR/vendor/bin/secril_config_svc" && \
#             ! grep -q -r "config_num_physical_slots" "$WORK_DIR/vendor/overlay"; then
#         PATCHED=true
#         APPLY_PATCH "system" "system/framework/telephony-common.jar" \
#             "$MODPATH/ril/telephony-common.jar/0001-Backport-legacy-UiccController-code.patch" || LOGW "APPLY_PATCH failed, skipping this step"
#     fi
# fi

# Support legacy sdFAT kernel drivers (pre-API 35)
# https://android.googlesource.com/platform/system/vold/+/refs/tags/android-16.0.0_r2/fs/Vfat.cpp#150
# - Check for 'bogus directory:' to determine if newer sdFAT drivers are in place
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "35" ]; then
    EXTRACT_KERNEL_IMAGE || LOGW "EXTRACT_KERNEL_IMAGE failed, skipping this step"
    if grep -q "SDFAT" "$TMP_DIR/out/kernel" && \
        ! grep -q "bogus directory:" "$TMP_DIR/out/kernel"; then
        PATCHED=true
        # ",time_offset=%d" -> "NUL"
        HEX_PATCH "$WORK_DIR/system/system/bin/vold" "2c74696d655f6f66667365743d2564" "000000000000000000000000000000" || LOGW "HEX_PATCH failed, skipping this step"
    fi
fi

# Ensure IMAGE_CODEC_SAMSUNG support (pre-API 35)
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "35" ]; then
    if [ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_CAMERA_CONFIG_VENDOR_LIB_INFO")" ] && \
            [[ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_CAMERA_CONFIG_VENDOR_LIB_INFO")" != *"image_codec.samsung"* ]]; then
        PATCHED=true
        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_CAMERA_CONFIG_VENDOR_LIB_INFO" \
            "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_CAMERA_CONFIG_VENDOR_LIB_INFO"),image_codec.samsung.v1" || LOGW "SET_FLOATING_FEATURE_CONFIG failed, skipping this step"
    fi
fi

# Ensure Knox Matrix support
# - Check if target firmware runs on One UI 5.1.1 or above
# - Otherwise check for fkeymaster support in target firmware
TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
if [ "$(GET_PROP "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/build.prop" "ro.build.version.oneui")" -lt "50101" ] || \
        [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/vendor/bin/vendor.samsung.hardware.security.fkeymaster-service" ]; then
    PATCHED=true
    DELETE_FROM_WORK_DIR "system" "system/bin/fabric_crypto" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
    DELETE_FROM_WORK_DIR "system" "system/etc/init/fabric_crypto.rc" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
    DELETE_FROM_WORK_DIR "system" "system/etc/permissions/FabricCryptoLib.xml" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
    DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.kmxservice.xml" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
    DELETE_FROM_WORK_DIR "system" "system/etc/vintf/manifest/fabric_crypto_manifest.xml" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
    DELETE_FROM_WORK_DIR "system" "system/framework/FabricCryptoLib.jar" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
    DELETE_FROM_WORK_DIR "system" "system/lib64/com.samsung.security.fabric.cryptod-V1-cpp.so" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
    DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.fkeymaster-V1-cpp.so" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
    DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.fkeymaster-V1-ndk.so" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
    DELETE_FROM_WORK_DIR "system" "system/priv-app/KmxService" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
fi

# Ensure Heatmap support
# - GKI: check for samsung,sec_auth_sle956681/samsung,sec_auth_ds28e30 kernel drivers
# - Non-GKI: unsupported
if [ -f "$WORK_DIR/kernel/vendor_boot.img" ]; then
    EXTRACT_KERNEL_MODULES || LOGW "EXTRACT_KERNEL_MODULES failed, skipping this step"
    if ! grep -q "samsung,sec_auth" "$TMP_DIR/out/vendor_ramdisk"*; then
        PATCHED=true
        DELETE_FROM_WORK_DIR "system" "system/bin/heatmap" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
        DELETE_FROM_WORK_DIR "system" "system/etc/init/init.sec-heatmap.rc" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
        DELETE_FROM_WORK_DIR "system" "system/lib64/libectcore.so" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
        DELETE_FROM_WORK_DIR "system" "system/lib64/libparam_A55_250328.so" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
    fi
else
    PATCHED=true
    DELETE_FROM_WORK_DIR "system" "system/bin/heatmap" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
    DELETE_FROM_WORK_DIR "system" "system/etc/init/init.sec-heatmap.rc" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libectcore.so" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
    DELETE_FROM_WORK_DIR "system" "system/lib64/libparam_A55_250328.so" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
fi

# Ensure KSMBD support in kernel
# - 4.19.x and below: unsupported
# - 5.4.x-5.10.x: backport (https://github.com/namjaejeon/ksmbd.git)
# - 5.15.x and above: supported
if [ -f "$WORK_DIR/system/system/priv-app/StorageShare/StorageShare.apk" ]; then
    EXTRACT_KERNEL_IMAGE || LOGW "EXTRACT_KERNEL_IMAGE failed, skipping this step"
    if ! grep -q "ksmbd" "$TMP_DIR/out/kernel"; then
        PATCHED=true
        DELETE_FROM_WORK_DIR "system" "system/bin/ksmbd.addshare" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
        DELETE_FROM_WORK_DIR "system" "system/bin/ksmbd.adduser" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
        DELETE_FROM_WORK_DIR "system" "system/bin/ksmbd.control" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
        DELETE_FROM_WORK_DIR "system" "system/bin/ksmbd.mountd" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
        DELETE_FROM_WORK_DIR "system" "system/bin/ksmbd.tools" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
        DELETE_FROM_WORK_DIR "system" "system/etc/default-permissions/default-permissions-com.samsung.android.hwresourceshare.storage.xml" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
        DELETE_FROM_WORK_DIR "system" "system/etc/init/ksmbd.rc" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
        DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.hwresourceshare.storage.xml" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
        DELETE_FROM_WORK_DIR "system" "system/etc/sysconfig/preinstalled-packages-com.samsung.android.hwresourceshare.storage.xml" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
        DELETE_FROM_WORK_DIR "system" "system/etc/ksmbd.conf" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
        DELETE_FROM_WORK_DIR "system" "system/priv-app/StorageShare" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
    fi
fi

# Ensure Sem eBPF Smart Hotspot functionality (pre-API 35)
# - Check for TARGET_PLATFORM_SDK_VERSION < 35 as 4.14 kernel support has been deprecated in Android V
# - Disable "ro.kernel.version" == "4.14" leftover checks, 4.14 needs eBPF kernel backports anyway
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "35" ]; then
    EXTRACT_KERNEL_IMAGE || LOGW "EXTRACT_KERNEL_IMAGE failed, skipping this step"
    if grep -q "Linux version 4.14" "$TMP_DIR/out/kernel"; then
        PATCHED=true
        # [b.eq #0xXXXXXX] -> [nop]
        # - android::net::MobileBBController::hotspotOn(const std::string)
        HEX_PATCH "$WORK_DIR/system/system/bin/netd" "1f01096be0010054" "1f01096b1f2003d5" || LOGW "HEX_PATCH failed, skipping this step"
        # - android::net::MobileBBController::isMBBPathsPresent()
        HEX_PATCH "$WORK_DIR/system/system/bin/netd" "1f01096b20010054" "1f01096b1f2003d5" || LOGW "HEX_PATCH failed, skipping this step"
    fi
fi

# Ensure IQtiComposer support (pre-API 36)
# - Disable "ro.product.first_api_level" < 34 check
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "36" ]; then
    if [[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "qssi" ]] && \
            ! grep -q -r "IQtiComposer" "$WORK_DIR/vendor/etc/vintf"; then
        PATCHED=true
        # [b.lt #0x729be8] -> [nop]
        HEX_PATCH "$WORK_DIR/system/system/bin/surfaceflinger" "9f8a00712b03005400068052" "9f8a00711f2003d500068052"
    fi
fi

# Support schedtune cgroup controller (pre-API 36)
# - Check for TARGET_PLATFORM_SDK_VERSION < 36 as 4.19 kernel support has been deprecated in Android B
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "36" ]; then
    EXTRACT_KERNEL_IMAGE
    KERNEL_VERSION="$(grep -a -o -m 1 "Linux version [0-9]*\.[0-9]*" "$TMP_DIR/out/kernel" | awk '{print $3}')"
    LEGACY_KERNEL=false
    if [ "$KERNEL_VERSION" ]; then
        if [ "${KERNEL_VERSION%%.*}" -lt "4" ] || \
                { [[ "${KERNEL_VERSION%%.*}" == "4" ]] && [ "${KERNEL_VERSION#*.}" -le "19" ]; }; then
            LEGACY_KERNEL=true
        fi
    fi

    if $LEGACY_KERNEL; then
        PATCHED=true

        if ! grep -q "# Create energy-aware scheduler tuning nodes" "$WORK_DIR/system/system/etc/init/hw/init.rc"; then
            LOG "- Adding stune cgroup nodes to /system/system/etc/init/hw/init.rc"
            EVAL "sed -i \"/mkdir \/dev\/socket\/ot-daemon 0770 thread_network thread_network/a\\\\
\\\\
    # Create energy-aware scheduler tuning nodes\\\\
    mkdir /dev/stune/foreground\\\\
    mkdir /dev/stune/background\\\\
    mkdir /dev/stune/top-app\\\\
    mkdir /dev/stune/rt\\\\
    chown system system /dev/stune\\\\
    chown system system /dev/stune/foreground\\\\
    chown system system /dev/stune/background\\\\
    chown system system /dev/stune/top-app\\\\
    chown system system /dev/stune/rt\\\\
    chown system system /dev/stune/tasks\\\\
    chown system system /dev/stune/foreground/tasks\\\\
    chown system system /dev/stune/background/tasks\\\\
    chown system system /dev/stune/top-app/tasks\\\\
    chown system system /dev/stune/rt/tasks\\\\
    chown system system /dev/stune/cgroup.procs\\\\
    chown system system /dev/stune/foreground/cgroup.procs\\\\
    chown system system /dev/stune/background/cgroup.procs\\\\
    chown system system /dev/stune/top-app/cgroup.procs\\\\
    chown system system /dev/stune/rt/cgroup.procs\\\\
    chmod 0664 /dev/stune/tasks\\\\
    chmod 0664 /dev/stune/foreground/tasks\\\\
    chmod 0664 /dev/stune/background/tasks\\\\
    chmod 0664 /dev/stune/top-app/tasks\\\\
    chmod 0664 /dev/stune/rt/tasks\\\\
    chmod 0664 /dev/stune/cgroup.procs\\\\
    chmod 0664 /dev/stune/foreground/cgroup.procs\\\\
    chmod 0664 /dev/stune/background/cgroup.procs\\\\
    chmod 0664 /dev/stune/top-app/cgroup.procs\\\\
    chmod 0664 /dev/stune/rt/cgroup.procs\" \"$WORK_DIR/system/system/etc/init/hw/init.rc\""
        fi

        if ! grep -q "/dev/stune/audio-app" "$WORK_DIR/system/system/etc/init/hw/init.rc"; then
            LOG "- Adding audio-app stune group to /system/system/etc/init/hw/init.rc"
            EVAL "sed -i \"/chmod 0664 \/dev\/stune\/rt\/cgroup.procs/a\\\\
\\\\
    mkdir /dev/stune/audio-app\\\\
    chown system system /dev/stune/audio-app\\\\
    chown system system /dev/stune/audio-app/tasks\\\\
    chmod 0664 /dev/stune/audio-app/tasks\" \"$WORK_DIR/system/system/etc/init/hw/init.rc\""
        fi

        if ! grep -q "/dev/stune/camera-daemon" "$WORK_DIR/system/system/etc/init/hw/init.rc"; then
            LOG "- Adding camera-daemon stune group to /system/system/etc/init/hw/init.rc"
            EVAL "sed -i \"/chmod 0664 \/dev\/cpuctl\/camera-daemon\/cpu.shares/a\\\\
\\\\
    # Create an stune group for camera-specific processes\\\\
    mkdir /dev/stune/camera-daemon\\\\
    chown system system /dev/stune/camera-daemon\\\\
    chown system system /dev/stune/camera-daemon/tasks\\\\
    chown system system /dev/stune/camera-daemon/cgroup.procs\\\\
    chmod 0664 /dev/stune/camera-daemon/tasks\\\\
    chmod 0664 /dev/stune/camera-daemon/cgroup.procs\" \"$WORK_DIR/system/system/etc/init/hw/init.rc\""
        fi

        if ! grep -q "/dev/stune/nnapi-hal" "$WORK_DIR/system/system/etc/init/hw/init.rc"; then
            LOG "- Adding nnapi-hal stune group to /system/system/etc/init/hw/init.rc"
            EVAL "sed -i \"/chmod 0664 \/dev\/stune\/camera-daemon\/cgroup.procs/a\\\\
\\\\
    # Create an stune group for NNAPI HAL processes\\\\
    mkdir /dev/stune/nnapi-hal\\\\
    chown system system /dev/stune/nnapi-hal\\\\
    chown system system /dev/stune/nnapi-hal/tasks\\\\
    chown system system /dev/stune/nnapi-hal/cgroup.procs\\\\
    chmod 0664 /dev/stune/nnapi-hal/tasks\\\\
    chmod 0664 /dev/stune/nnapi-hal/cgroup.procs\\\\
    write /dev/stune/nnapi-hal/schedtune.boost 1\\\\
    write /dev/stune/nnapi-hal/schedtune.prefer_idle 1\" \"$WORK_DIR/system/system/etc/init/hw/init.rc\""
        fi

        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" \
            "system/etc/task_profiles/cgroups_28.json" 0 0 644 "u:object_r:cgroup_desc_file:s0"
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" \
            "system/etc/task_profiles/cgroups_29.json" 0 0 644 "u:object_r:cgroup_desc_file:s0"
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" \
            "system/etc/task_profiles/cgroups_30.json" 0 0 644 "u:object_r:cgroup_desc_file:s0"
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" \
            "system/etc/task_profiles/task_profiles_28.json" 0 0 644 "u:object_r:task_profiles_file:s0"
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" \
            "system/etc/task_profiles/task_profiles_29.json" 0 0 644 "u:object_r:task_profiles_file:s0"
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" \
            "system/etc/task_profiles/task_profiles_30.json" 0 0 644 "u:object_r:task_profiles_file:s0"
    fi

    unset KERNEL_VERSION LEGACY_KERNEL
fi

# Ensure sbauth support in target firmware
TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
if [ -f "$WORK_DIR/system/system/bin/sbauth" ] && \
        [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/bin/sbauth" ]; then
    PATCHED=true
    DELETE_FROM_WORK_DIR "system" "system/bin/sbauth" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
    DELETE_FROM_WORK_DIR "system" "system/etc/init/sbauth.rc" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
fi

# Ensure PASS support (pre-API 35)
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "35" ]; then
    if ! grep -q "sec_pass_data_file" "$WORK_DIR/vendor/etc/selinux/vendor_file_contexts"; then
        PATCHED=true
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali/com/android/server/StorageManagerService.smali" "return" \
            'isPassSupport()Z' 'false' || LOGW "SMALI_PATCH failed, skipping this step"
    fi
fi

# Support legacy usb_notify kernel drivers (pre-API 36)
# https://github.com/salvogiangri/UN1CA/discussions/519
# - Check for 'SKY_DEFAULT' to determine if newer usb_notify drivers are in place
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "36" ]; then
    VBOOT_MISSING=true
    KERNEL_MISSING=true

    if [ -f "$WORK_DIR/kernel/vendor_boot.img" ]; then
        # Check for GKI devices
        EXTRACT_KERNEL_MODULES || LOGW "EXTRACT_KERNEL_MODULES failed, skipping this step"
        if grep -q "SKY_DEFAULT" "$TMP_DIR/out/vendor_ramdisk"*; then
            VBOOT_MISSING=false
        fi
    fi

    # Check for legacy devices
    EXTRACT_KERNEL_IMAGE || LOGW "EXTRACT_KERNEL_IMAGE failed, skipping this step"
    if grep -q "SKY_DEFAULT" "$TMP_DIR/out/kernel"; then
        KERNEL_MISSING=false
    fi

    if $VBOOT_MISSING && $KERNEL_MISSING; then
        PATCHED=true
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/com/android/server/usb/UsbHostRestrictor.smali" "replace" \
            "isFinishLockTimer()Z" \
            "RAINY_RESTRICT_MODE" \
            "2" || LOGW "SMALI_PATCH failed, skipping this step"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/com/android/server/usb/UsbHostRestrictor.smali" "replace" \
            "onKeyguardStateChanged(Z)V" \
            "CLOUDY_WORK_MODE" \
            "1" || LOGW "SMALI_PATCH failed, skipping this step"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/com/android/server/usb/UsbHostRestrictor\$1.smali" "replace" \
            "onChange(Z)V" \
            "CLOUDY_WORK_MODE" \
            "1" || LOGW "SMALI_PATCH failed, skipping this step"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/com/android/server/usb/UsbHostRestrictor\$8.smali" "replace" \
            "handleMessage(Landroid/os/Message;)V" \
            "SUNNY_WORK_MODE" \
            "0" || LOGW "SMALI_PATCH failed, skipping this step"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/com/android/server/usb/UsbHostRestrictor\$8.smali" "replace" \
            "handleMessage(Landroid/os/Message;)V" \
            "RAINY_RESTRICT_MODE" \
            "2" || LOGW "SMALI_PATCH failed, skipping this step"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/com/android/server/usb/UsbService\$Lifecycle.smali" "replace" \
            "onBootPhase(I)V" \
            "RAINY_RESTRICT_MODE" \
            "2" || LOGW "SMALI_PATCH failed, skipping this step"
        SMALI_PATCH "system" "system/framework/services.jar" \
            "smali_classes2/com/android/server/usb/UsbService\$Lifecycle.smali" "replace" \
            "onBootPhase(I)V" \
            "CLOUDY_WORK_MODE" \
            "1" || LOGW "SMALI_PATCH failed, skipping this step"
    fi

    unset VBOOT_MISSING KERNEL_MISSING
fi

# Support legacy LED Cover level
# - Replace deprecated 'android.nfc.NfcAdapter' APIs with 'com.samsung.android.nfc.adapter.ISamsungNfcAdapter'
if [ -f "$WORK_DIR/system/system/priv-app/LedCoverService/LedCoverService.apk" ]; then
    if [ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_NFC_LED_COVER_LEVEL")" -ge "30" ] && \
            [ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_NFC_LED_COVER_LEVEL")" -lt "100" ]; then
        PATCHED=true
        APPLY_PATCH "system" "system/priv-app/LedCoverService/LedCoverService.apk" \
            "$MODPATH/ledcover/LedCoverService.apk/0001-Switch-to-ISamsungNfcAdapter-interface.patch" || LOGW "APPLY_PATCH failed, skipping this step"
    fi
fi

# Upgrade Segmentation models (pre-API 34)
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "34" ]; then
    if grep -q "default_lowtier" "$WORK_DIR/system/system/cameradata/portrait_data/single_bokeh_feature.json" &&
            [ -f "$WORK_DIR/system/system/cameradata/portrait_data/SRIB_HumanInsSeg_FP16_V008.snf" ]; then
        PATCHED=true
        DELETE_FROM_WORK_DIR "system" "system/cameradata/portrait_data/SRIB_HumanInsSeg_FP16_V008.snf" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
        ADD_TO_WORK_DIR "a17xxx" "system" \
            "system/cameradata/portrait_data/SRIB_BanetLite_FP16_V400.snf" 0 0 644 "u:object_r:system_file:s0" || LOGW "ADD_TO_WORK_DIR failed, skipping this step"
        LOG "- Patching /system/system/cameradata/portrait_data/single_bokeh_feature.json"
        EVAL "sed -i \"0,/HumanInsSeg_FP16_V008/s//BanetLite_FP16_V400/\" \"$WORK_DIR/system/system/cameradata/portrait_data/single_bokeh_feature.json\"" || LOGW "EVAL failed, skipping this step"
        EVAL "sed -i \"0,/008/s//400/\" \"$WORK_DIR/system/system/cameradata/portrait_data/single_bokeh_feature.json\"" || LOGW "EVAL failed, skipping this step"
        EVAL "sed -i \"0,/QASYMM8/s//FLOAT16/\" \"$WORK_DIR/system/system/cameradata/portrait_data/single_bokeh_feature.json\"" || LOGW "EVAL failed, skipping this step"
    fi
fi

# Pre-API 35
# - Upgrade MIDAS models
#
# Pre-API 36
# - Update midas_config.json
if ! grep -q "\"version\": \"4\." "$WORK_DIR/vendor/etc/midas/midas_config.json"; then
    if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "35" ]; then
        PATCHED=true
        DELETE_FROM_WORK_DIR "vendor" "etc/midas" || LOGW "DELETE_FROM_WORK_DIR failed, skipping this step"
        ADD_TO_WORK_DIR "a73xqxx" "vendor" \
            "etc/midas" 0 2000 755 "u:object_r:vendor_configs_file:s0" || LOGW "ADD_TO_WORK_DIR failed, skipping this step"
    fi
    if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "36" ]; then
        PATCHED=true
        ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" \
            "etc/midas/midas_config.json" 0 0 644 "u:object_r:vendor_configs_file:s0" || LOGW "ADD_TO_WORK_DIR failed, skipping this step"
    fi
fi

# Upgrade Single Take models (pre-API 35)
if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "35" ]; then
    if [ -f "$WORK_DIR/system/system/cameradata/singletake/service-feature.xml" ]; then
        if [ ! -d "$WORK_DIR/vendor/etc/singletake/ClarityScorer" ]; then
            PATCHED=true
            if [ -d "$WORK_DIR/vendor/etc/singletake/aifilter" ]; then
                DELETE_FROM_WORK_DIR "vendor" "etc/singletake/aifilter"
            fi
            if [ -d "$WORK_DIR/vendor/etc/singletake/bestmoment" ]; then
                DELETE_FROM_WORK_DIR "vendor" "etc/singletake/bestmoment"
            fi
            ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" \
                "etc/singletake/ClarityScorer" 0 2000 755 "u:object_r:vendor_configs_file:s0"
        fi
    else
        PATCHED=true
   fi
fi

if ! $PATCHED; then
    LOG "\033[0;33m! Nothing to do\033[0m"
fi

if [ -d "$TMP_DIR" ]; then
    EVAL "rm -rf \"$TMP_DIR\"" || LOGW "EVAL failed, skipping this step"
fi

unset PATCHED TARGET_FIRMWARE_PATH
unset -f BACKPORT_SF_PROPS EXTRACT_KERNEL_IMAGE EXTRACT_KERNEL_MODULES
