.class public Lio/mesalabs/unica/settings/extra/ScreenResolutionPreferenceController;
.super Lcom/android/settings/core/BasePreferenceController;
.source "ScreenResolutionPreferenceController.java"


# interfaces
.implements Landroidx/preference/Preference$OnPreferenceChangeListener;


# direct methods
.method public constructor <init>(Landroid/content/Context;Ljava/lang/String;)V
    .locals 0

    invoke-direct {p0, p1, p2}, Lcom/android/settings/core/BasePreferenceController;-><init>(Landroid/content/Context;Ljava/lang/String;)V

    return-void
.end method

.method private static currentSixths()I
    .locals 6

    :try_start_0
    invoke-static {}, Landroid/view/WindowManagerGlobal;->getWindowManagerService()Landroid/view/IWindowManager;

    move-result-object v0

    new-instance v1, Landroid/graphics/Point;

    invoke-direct {v1}, Landroid/graphics/Point;-><init>()V

    new-instance v2, Landroid/graphics/Point;

    invoke-direct {v2}, Landroid/graphics/Point;-><init>()V

    const/4 v3, 0x0

    invoke-interface {v0, v3, v1}, Landroid/view/IWindowManager;->getInitialDisplaySize(ILandroid/graphics/Point;)V

    invoke-interface {v0, v3, v2}, Landroid/view/IWindowManager;->getBaseDisplaySize(ILandroid/graphics/Point;)V

    iget v3, v2, Landroid/graphics/Point;->x:I

    mul-int/lit8 v3, v3, 0x6

    iget v4, v1, Landroid/graphics/Point;->x:I

    div-int/lit8 v5, v4, 0x2

    add-int/2addr v3, v5

    div-int/2addr v3, v4
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    const/4 v4, 0x4

    if-ge v3, v4, :cond_0

    move v3, v4

    :cond_0
    const/4 v4, 0x6

    if-le v3, v4, :cond_1

    move v3, v4

    :cond_1
    return v3

    :catch_0
    const/4 v0, 0x6

    return v0
.end method

.method private static applySixths(I)Z
    .locals 9

    const/4 v3, 0x4

    if-lt p0, v3, :cond_bad

    const/4 v3, 0x6

    if-gt p0, v3, :cond_bad

    :try_start_0
    invoke-static {}, Landroid/view/WindowManagerGlobal;->getWindowManagerService()Landroid/view/IWindowManager;

    move-result-object v0

    invoke-static {}, Landroid/os/UserHandle;->myUserId()I

    move-result v1

    const/4 v2, 0x0

    if-ne p0, v3, :cond_scale

    invoke-interface {v0, v2}, Landroid/view/IWindowManager;->clearForcedDisplaySize(I)V

    invoke-interface {v0, v2, v1}, Landroid/view/IWindowManager;->clearForcedDisplayDensityForUser(II)V

    const/4 v0, 0x1

    return v0

    :cond_scale
    new-instance v3, Landroid/graphics/Point;

    invoke-direct {v3}, Landroid/graphics/Point;-><init>()V

    invoke-interface {v0, v2, v3}, Landroid/view/IWindowManager;->getInitialDisplaySize(ILandroid/graphics/Point;)V

    invoke-interface {v0, v2}, Landroid/view/IWindowManager;->getInitialDisplayDensity(I)I

    move-result v4

    iget v5, v3, Landroid/graphics/Point;->x:I

    mul-int/2addr v5, p0

    div-int/lit8 v5, v5, 0x6

    iget v6, v3, Landroid/graphics/Point;->y:I

    mul-int/2addr v6, p0

    div-int/lit8 v6, v6, 0x6

    mul-int/2addr v4, p0

    div-int/lit8 v4, v4, 0x6

    invoke-interface {v0, v2, v5, v6}, Landroid/view/IWindowManager;->setForcedDisplaySize(III)V

    invoke-interface {v0, v2, v4, v1}, Landroid/view/IWindowManager;->setForcedDisplayDensityForUser(III)V
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    const/4 v0, 0x1

    return v0

    :catch_0
    :cond_bad
    const/4 v0, 0x0

    return v0
.end method

# virtual methods
.method public displayPreference(Landroidx/preference/PreferenceScreen;)V
    .locals 2

    invoke-super {p0, p1}, Lcom/android/settings/core/BasePreferenceController;->displayPreference(Landroidx/preference/PreferenceScreen;)V

    iget-object v0, p0, Lcom/android/settings/core/BasePreferenceController;->mPreferenceKey:Ljava/lang/String;

    invoke-virtual {p1, v0}, Landroidx/preference/PreferenceGroup;->findPreference(Ljava/lang/CharSequence;)Landroidx/preference/Preference;

    move-result-object v0

    if-eqz v0, :cond_0

    check-cast v0, Landroidx/preference/ListPreference;

    invoke-static {}, Lio/mesalabs/unica/settings/extra/ScreenResolutionPreferenceController;->currentSixths()I

    move-result v1

    invoke-static {v1}, Ljava/lang/String;->valueOf(I)Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v0, v1}, Landroidx/preference/ListPreference;->setValue(Ljava/lang/String;)V

    invoke-virtual {v0, p0}, Landroidx/preference/Preference;->setOnPreferenceChangeListener(Landroidx/preference/Preference$OnPreferenceChangeListener;)V

    :cond_0
    return-void
.end method

.method public getAvailabilityStatus()I
    .locals 1

    const/4 v0, 0x0

    return v0
.end method

.method public getSummary()Ljava/lang/CharSequence;
    .locals 4

    :try_start_0
    invoke-static {}, Landroid/view/WindowManagerGlobal;->getWindowManagerService()Landroid/view/IWindowManager;

    move-result-object v0

    new-instance v1, Landroid/graphics/Point;

    invoke-direct {v1}, Landroid/graphics/Point;-><init>()V

    const/4 v2, 0x0

    invoke-interface {v0, v2, v1}, Landroid/view/IWindowManager;->getBaseDisplaySize(ILandroid/graphics/Point;)V

    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    iget v2, v1, Landroid/graphics/Point;->x:I

    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    const-string v2, " x "

    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    iget v1, v1, Landroid/graphics/Point;->y:I

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    return-object v0

    :catch_0
    const/4 v0, 0x0

    return-object v0
.end method

.method public onPreferenceChange(Landroidx/preference/Preference;Ljava/lang/Object;)Z
    .locals 1

    check-cast p2, Ljava/lang/String;

    invoke-static {p2}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

    move-result v0

    invoke-static {v0}, Lio/mesalabs/unica/settings/extra/ScreenResolutionPreferenceController;->applySixths(I)Z

    move-result v0

    return v0
.end method