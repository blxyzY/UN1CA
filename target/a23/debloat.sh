# Copyright (c) 2026 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# Debloat list for Galaxy A23 (a23)
# - Add entries inside the specific partition containing that file (<PARTITION>_DEBLOAT+="")
# - DO NOT add the partition name at the start of any entry (eg. "/system/dpolicy_system")
# - DO NOT add a slash at the start of any entry (eg. "/dpolicy_system")

# Overlays
SYSTEM_DEBLOAT+="
system/app/WifiRROverlayAppLls
"

# HDCP
SYSTEM_DEBLOAT+="
system/bin/dhkprov
system/bin/qchdcpkprov
system/etc/init/dhkprov.rc
system/lib64/vendor.samsung.hardware.security.hdcp.keyprovisioning@1.0.so
"

# GameDriver
SYSTEM_DEBLOAT+="
system/priv-app/GameDriver-SM8450
"

# LinkToWindows Debload
SYSTEM_DEBLOAT+="
system/priv-app/YourPhone_Stub
system/priv-app/LinkToWindowsService
"

# Esim Debload
SYSTEM_DEBLOAT+="
system/priv-app/EsimClient
system/priv-app/EsimKeyString
system/priv-app/EuiccService
system/priv-app/EuiccGoogle
system/etc/permissions/privapp-permissions-com.samsung.euicc.xml
system/etc/permissions/privapp-permissions-com.samsung.android.app.esimkeystring.xml
system/etc/permissions/privapp-permissions-com.samsung.android.app.telephonyui.esimclient.xml
system/etc/privapp-permissions-com.samsung.android.app.telephonyui.esimclient.xml
system/etc/sysconfig/preinstalled-packages-com.samsung.euicc.xml
system/etc/sysconfig/preinstalled-packages-com.samsung.android.app.esimkeystring.xml
system/etc/autoinstalls/autoinstalls-com.google.android.euicc
system/etc/default-permissions/default-permissions-com.google.android.euicc.xml
"

# Usesles feature Debload
SYSTEM_DEBLOAT+="
system/priv-app/Moments
system/app/KidsHome_Installer
system/app/ParentalCare
"

