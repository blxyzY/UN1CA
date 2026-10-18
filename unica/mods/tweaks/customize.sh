# Disable app compaction
# Guard the patch as the source firmware might have this already disabled
LOG "- Applying \"Disable app compaction\" to /system/system/framework/services.jar"
APPLY_PATCH "system" "system/framework/services.jar" \
    "$MODPATH/appcompactor/services.jar/0001-Disable-app-compaction.patch" &> /dev/null || true

# Disable FM Radio country restrictions
if [[ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FMRADIO_CONFIG_CHIP_VENDOR")" != "0" ]]; then
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FMRADIO_CONFIG_AVOID_REGION" --delete

    SMALI_PATCH "system" "system/framework/samsungfmradiolib.jar" \
        "smali/com/samsung/frameworks/fmradio/FMRadioImpl.smali" "return" \
        'isRadioNotSupportedInRegion()Z' \
        'false'
fi

# Rebalance the shade blur (window vs. content)
# The radius constants are rescaled starting from the values found in the firmware,
# so no stock value has to be known. 100 leaves a constant untouched.
# NOTE: Blur Intensity Scale (SecQpBlurController) still multiplies the result at runtime
SHADE_WINDOW_BLUR_PCT=100
SHADE_CONTENT_BLUR_PCT=200

DECODE_APK "system_ext" "priv-app/SystemUI/SystemUI.apk"

SYSTEMUI_RES="$APKTOOL_DIR/system_ext/priv-app/SystemUI/SystemUI.apk/res"

for ENTRY in "max_shade_window_blur_radius:$SHADE_WINDOW_BLUR_PCT" \
        "max_shade_content_blur_radius:$SHADE_CONTENT_BLUR_PCT"; do
    DIMEN_NAME="${ENTRY%%:*}"
    DIMEN_PCT="${ENTRY##*:}"

    if [[ "$DIMEN_PCT" == "100" ]]; then
        continue
    fi

    DIMEN_FILES="$(find "$SYSTEMUI_RES" -path "*/values*/*.xml" ! -name "public.xml" \
        -exec grep -l "name=\"$DIMEN_NAME\"" {} + 2> /dev/null || true)"

    if [ -z "$DIMEN_FILES" ]; then
        LOGW "Dimen \"$DIMEN_NAME\" not found in SystemUI.apk, skipping"
        continue
    fi

    while IFS= read -r f; do
        LOG "- Scaling \"$DIMEN_NAME\" to $DIMEN_PCT% in \"${f#"$SYSTEMUI_RES"/}\""
        awk -v NAME="$DIMEN_NAME" -v PCT="$DIMEN_PCT" '
            index($0, "name=\"" NAME "\"") && match($0, />-?[0-9]*\.?[0-9]+/) {
                val = substr($0, RSTART + 1, RLENGTH - 1) + 0
                sub(/>-?[0-9]*\.?[0-9]+/, sprintf(">%.1f", val * PCT / 100))
            }
            { print }
        ' "$f" > "$f.tmp"

        if cmp -s "$f" "$f.tmp"; then
            LOGW "\"$DIMEN_NAME\" in \"${f#"$SYSTEMUI_RES"/}\" is not a plain number, left untouched"
            rm -f "$f.tmp"
        else
            mv "$f.tmp" "$f"
        fi
    done <<< "$DIMEN_FILES"
done

unset SHADE_WINDOW_BLUR_PCT SHADE_CONTENT_BLUR_PCT SYSTEMUI_RES ENTRY DIMEN_NAME DIMEN_PCT DIMEN_FILES

