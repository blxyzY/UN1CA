# Copyright (c) 2026 Noir ZestUI
# SPDX-License-Identifier: GPL-3.0-or-later

# Debloat list for Galaxy A05s (a05s)
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

# General 
SYSTEM_DEBLOAT+="
system/app/WlanTest
system/app/AirGlance
system/app/AirReadingGlass
system/app/SOAgent77
system/priv-app/BixbyWakeup
system/priv-app/BlockchainBasicKit
system/priv-app/DictDiotekForSec
system/priv-app/EasymodeContactsWidget81
system/priv-app/Fast
system/priv-app/FunModeSDK
system/priv-app/KidsHome_Installer
system/priv-app/LinkSharing_v11
system/priv-app/MAPSAgent
system/priv-app/MdecService
system/priv-app/MinusOnePage
system/priv-app/MoccaMobile
system/priv-app/Netflix_stub
system/priv-app/Notes40
system/priv-app/ParentalCare
system/priv-app/VisionIntelligence3.7
system/priv-app/WebManual
system/priv-app/AutomationTest_FB
system/priv-app/FactoryTestProvider
"

# Samsung Features / Apps
SYSTEM_DEBLOAT+="
system/app/OneDrive_Samsung_v3
system/app/SamsungCarKeyFw
system/app/SamsungPassAutofill_v1
system/app/AirCommand
system/app/AppUpdateCenter
"

# Samsung AI / Smart
SYSTEM_DEBLOAT+="
system/app/Bixby
system/app/BixbyInterpreter
system/app/BixbyVisionFramework3.5
system/app/SettingsBixby
system/app/SmartEye
system/app/SmartPush
system/app/SmartPush_64
system/app/SmartThingsKit
system/app/SmartTouchCall
system/app/VisionIntelligence3.7
"

# Facebook
SYSTEM_DEBLOAT+="
system/app/FBAppManager_NS
system/app/FBInstaller_NS
system/app/FBServices
"

# Misc / Services
SYSTEM_DEBLOAT+="
system/app/Discover
system/app/DiscoverSEP
system/app/EasySetup
system/app/HashTagService
system/app/LedCoverService
system/app/LinkToWindowsService
system/app/MemorySaver_O_Refresh
system/app/OMCAgent5
system/app/OneStoreService
system/app/FactoryAirCommandManager
system/app/SOAgent7
system/app/SOAgent75
system/app/SOAgent76
system/app/SolarAudio-service
system/app/SPPPushClient
system/app/SumeNNService
system/app/SwiftkeyIme
system/app/SwiftkeySetting
system/app/SystemUpdate
system/app/TADownloader
system/app/TaPackAuthFw
system/app/Upday
system/app/YourPhone_P1_5
"

# Knox
SYSTEM_DEBLOAT+="
system/priv-app/Rampart
system/priv-app/KnoxFrameBufferProvider
"

# Fabric Crypto
SYSTEM_DEBLOAT+="
system/bin/fabric_crypto
system/etc/init/fabric_crypto.rc
system/etc/permissions/FabricCryptoLib.xml
system/etc/vintf/manifest/fabric_crypto_manifest.xml
system/framework/FabricCryptoLib.jar
system/framework/oat/arm/FabricCryptoLib.odex
system/framework/oat/arm/FabricCryptoLib.vdex
system/framework/oat/arm64/FabricCryptoLib.odex
system/framework/oat/arm64/FabricCryptoLib.vdex
system/lib64/com.samsung.security.fabric.cryptod-V1-cpp.so
system/lib64/vendor.samsung.hardware.security.fkeymaster-V1-ndk.so
system/priv-app/KmxService
"
