; Copyright Dolphin Emulator Project / Azahar Emulator Project / Eden Emulator Project / pflyly
; Licensed under GPLv3

; Require /DPRODUCT_TOOLCHAIN=<release-name> to makensis.
!ifndef PRODUCT_TOOLCHAIN
  !error "PRODUCT_TOOLCHAIN must be defined"
!endif

; Require /DPRODUCT_VERSION=<release-name> to makensis.
!ifndef PRODUCT_VERSION
  !error "PRODUCT_VERSION must be defined"
!endif

; Require /DPRODUCT_VARIANT=<release-name> to makensis.
!ifndef PRODUCT_VARIANT
  !error "PRODUCT_VARIANT must be defined"
!endif

!define PRODUCT_NAME "Eden Nightly"
!define PRODUCT_DISPLAY_NAME "${PRODUCT_NAME} (${PRODUCT_TOOLCHAIN})"
!define PRODUCT_PUBLISHER "Eden Emulator Developers"
!define PRODUCT_WEB_SITE "https://eden-emu.dev/"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\${PRODUCT_DISPLAY_NAME}.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_DISPLAY_NAME}"
!define BINARY_SOURCE_DIR "..\eden\build\bin"
!define MUI_ICON "..\eden\dist\eden.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; Setup MultiUser support:
!define MULTIUSER_EXECUTIONLEVEL Highest
!define MULTIUSER_INSTALLMODE_INSTDIR "${PRODUCT_DISPLAY_NAME}"
!define MULTIUSER_MUI
!define MULTIUSER_INSTALLMODE_COMMANDLINE
!define MULTIUSER_USE_PROGRAMFILES64

!include "MultiUser.nsh"
!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "FileFunc.nsh"

; Variables
Var InstallOptionPageDialog
Var DesktopShortcutCheckbox
Var DesktopShortcut
Var PortableModeCheckbox
Var PortableMode
Var CleanInstallCheckbox
Var CleanInstall
Var BackupUserDataCheckbox
Var BackupUserData
Var CustomFinishPageDialog
Var LaunchEdenCheckbox
Var LaunchEden
Var UninstallerPageDialog
Var CleanUninstallCheckbox
Var CleanUninstall
Var UnFinishPageDialog
Var OpenLatestCheckbox
Var OpenLatest

Name "${PRODUCT_DISPLAY_NAME}"
OutFile "Eden-${PRODUCT_VERSION}-Windows-${PRODUCT_TOOLCHAIN}-${PRODUCT_VARIANT}-Installer.exe"
BrandingText "${PRODUCT_DISPLAY_NAME} Installer v${PRODUCT_VERSION} (${PRODUCT_VARIANT})"
SetCompressor /SOLID lzma
ShowInstDetails show
ShowUnInstDetails show
ManifestDPIAware true

; License page
!insertmacro MUI_PAGE_LICENSE "..\LICENSE"

; All/Current user selection page
!define MULTIUSER_PAGE_CUSTOMFUNCTION_LEAVE InstallModeLeave
!insertmacro MULTIUSER_PAGE_INSTALLMODE

; Directory page
!insertmacro MUI_PAGE_DIRECTORY

; Install option page
Page custom InstallOptionPageCreate InstallOptionPageLeave

; Instfiles page
!insertmacro MUI_PAGE_INSTFILES

; Finish page
Page custom CustomFinishPageCreate CustomFinishPageLeave

; Clean Uninstall page
UninstPage custom un.CleanUninstallPageCreate un.CleanUninstallPageLeave

; Uninstall page
!insertmacro MUI_UNPAGE_INSTFILES

; Uninstaller finish page
UninstPage custom un.CustomFinishPageCreate un.CustomFinishPageLeave

; Language files
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Arabic"
!insertmacro MUI_LANGUAGE "Catalan"
!insertmacro MUI_LANGUAGE "Czech"
!insertmacro MUI_LANGUAGE "Danish"
!insertmacro MUI_LANGUAGE "Dutch"
!insertmacro MUI_LANGUAGE "Finnish"
!insertmacro MUI_LANGUAGE "French"
!insertmacro MUI_LANGUAGE "German"
!insertmacro MUI_LANGUAGE "Greek"
!insertmacro MUI_LANGUAGE "Hungarian"
!insertmacro MUI_LANGUAGE "Indonesian"
!insertmacro MUI_LANGUAGE "Italian"
!insertmacro MUI_LANGUAGE "Japanese"
!insertmacro MUI_LANGUAGE "Korean"
!insertmacro MUI_LANGUAGE "Norwegian"
!insertmacro MUI_LANGUAGE "Polish"
!insertmacro MUI_LANGUAGE "Portuguese"
!insertmacro MUI_LANGUAGE "PortugueseBR"
!insertmacro MUI_LANGUAGE "Russian"
!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "Spanish"
!insertmacro MUI_LANGUAGE "SpanishInternational"
!insertmacro MUI_LANGUAGE "Swedish"
!insertmacro MUI_LANGUAGE "TradChinese"
!insertmacro MUI_LANGUAGE "Turkish"
!insertmacro MUI_LANGUAGE "Ukrainian"
!insertmacro MUI_LANGUAGE "Vietnamese"

Function .onInit
  !insertmacro MULTIUSER_INIT
  !insertmacro MUI_LANGDLL_DISPLAY
FunctionEnd

Function un.onInit
  !insertmacro MULTIUSER_UNINIT
  ${If} $MultiUser.InstallMode == "AllUsers"
    SetShellVarContext all
  ${Else}
    SetShellVarContext current
  ${EndIf}
FunctionEnd

!macro ResetCleanInstall
  StrCpy $CleanInstall 0
  ${NSD_SetState} $CleanInstallCheckbox $CleanInstall
  Abort
!macroend

!macro ResetCleanUninstall
  StrCpy $CleanUninstall 0
  ${NSD_SetState} $CleanUninstallCheckbox $CleanUninstall
  Abort
!macroend

Function InstallModeLeave
  ; Read previous install path from registry
  ReadRegStr $R0 HKCU "${PRODUCT_UNINST_KEY}" "InstallLocation"
  ${If} $R0 == ""
    ReadRegStr $R0 HKLM "${PRODUCT_UNINST_KEY}" "InstallLocation"
  ${EndIf}
  ${If} $R0 != ""
    StrCpy $INSTDIR "$R0"
  ${EndIf}
FunctionEnd
    
Function InstallOptionPageCreate
  !insertmacro MUI_HEADER_TEXT "Installation Options" "Customize your Eden installation"
  nsDialogs::Create 1018
  Pop $InstallOptionPageDialog
  ${If} $InstallOptionPageDialog == error
    Abort
  ${EndIf}

  ${NSD_CreateCheckbox} 0u 0u 100% 12u "Create a desktop shortcut"
  Pop $DesktopShortcutCheckbox
  ${NSD_SetState} $DesktopShortcutCheckbox $DesktopShortcut

  ${NSD_CreateCheckbox} 0u 16u 100% 12u "Enable portable mode (Store Eden user data in install folder)"
  Pop $PortableModeCheckbox
  ${NSD_SetState} $PortableModeCheckbox $PortableMode

  ${NSD_CreateCheckbox} 0u 32u 100% 12u "Clean install (Remove previous installation files and user data)"
  Pop $CleanInstallCheckbox
  ${NSD_SetState} $CleanInstallCheckbox $CleanInstall

  ${NSD_CreateCheckbox} 0u 48u 100% 12u "Back up user data"
  Pop $BackupUserDataCheckbox
  ${NSD_SetState} $BackupUserDataCheckbox $BackupUserData
  ShowWindow $BackupUserDataCheckbox ${SW_HIDE}

  GetFunctionAddress $0 ClickCleanInstall
  nsDialogs::OnClick $CleanInstallCheckbox $0
  GetFunctionAddress $0 ClickBackupUserData
  nsDialogs::OnClick $BackupUserDataCheckbox $0
  
  nsDialogs::Show
FunctionEnd
    
Function ClickCleanInstall
  Pop $R0
  ${NSD_GetState} $CleanInstallCheckbox $CleanInstall
  ${If} $CleanInstall == 1
    ShowWindow $BackupUserDataCheckbox ${SW_SHOW}
  ${Else}
    ShowWindow $BackupUserDataCheckbox ${SW_HIDE}
    StrCpy $BackupUserData 0
    ${NSD_SetState} $BackupUserDataCheckbox $BackupUserData
  ${EndIf}
FunctionEnd

Function ClickBackupUserData
  Pop $R0
  ${NSD_GetState} $BackupUserDataCheckbox $BackupUserData
  ${If} $BackupUserData == 1
    MessageBox MB_YESNO|MB_ICONQUESTION "Do you want to back up your Eden user data now?" IDYES continue
    StrCpy $BackupUserData 0
    ${NSD_SetState} $BackupUserDataCheckbox $BackupUserData
    Goto end 
    
    continue:
    Call DoBackupUserData
    EnableWindow $BackupUserDataCheckbox 0
  ${EndIf}
  end:
FunctionEnd

Function DoBackupUserData
  ${GetTime} "" "LS" $R1 $R2 $R3 $R4 $R5 $R6 $R7
  StrCpy $R8 "$R3-$R2-$R1_$R5-$R6-$R7"
  StrCpy $R9 "$DOCUMENTS\EdenBackup\$R8"
  CreateDirectory "$R9"

  ; Backup AppData user data
  SetShellVarContext current
  ${If} ${FileExists} "$APPDATA\eden"
    CreateDirectory "$R9\AppData"
    CopyFiles /SILENT "$APPDATA\eden\*" "$R9\AppData\"
  ${EndIf}

  ; Backup Portable user data
  ${If} ${FileExists} "$INSTDIR\user"
    CreateDirectory "$R9\Portable"
    CopyFiles /SILENT "$INSTDIR\user\*" "$R9\Portable\"
  ${EndIf}

  MessageBox MB_ICONINFORMATION "Your Eden user data has been backed up to:$\n$R9"
FunctionEnd

Function InstallOptionPageLeave
  ${NSD_GetState} $DesktopShortcutCheckbox $DesktopShortcut
  ${NSD_GetState} $PortableModeCheckbox $PortableMode
  ${NSD_GetState} $CleanInstallCheckbox $CleanInstall
  
  ; Detect both portable mode and appdata configs
  StrCpy $0 0 ; initial portable mode
  StrCpy $1 0 ; initial appdata exits

  ${If} ${FileExists} "$INSTDIR\user"
    StrCpy $0 1
  ${EndIf}

  SetShellVarContext current ; Set current due to eden default config location
  ${If} ${FileExists} "$APPDATA\eden"
    StrCpy $1 1
  ${EndIf}
  
  ${If} $CleanInstall == 1
    ${If} $0 == 0
      ${If} $1 == 0
        MessageBox MB_ICONINFORMATION "No previous user data was found! Clean install is not needed."
        !insertmacro ResetCleanInstall
      ${Else}
        MessageBox MB_ICONEXCLAMATION|MB_YESNO "Default mode user data detected in AppData at:$\n$APPDATA\eden$\n$\nDo you want to delete it?$\nThis will remove all user settings, caches, and saves." IDYES continue
        !insertmacro ResetCleanInstall
        continue:
      ${EndIf}
    ${ElseIf} $0 == 1
      ${If} $1 == 1
        MessageBox MB_ICONEXCLAMATION|MB_YESNO "Multiple user data folders were detected:$\n$\n- Portable mode: $INSTDIR\user$\n- Default mode: $APPDATA\eden$\n$\nDo you want to delete them both?$\nThis will remove all user settings, caches, and saves." IDYES continue2
        !insertmacro ResetCleanInstall
        continue2:
      ${Else}
        MessageBox MB_ICONEXCLAMATION|MB_YESNO "Portable mode user data detected at:$\n$INSTDIR\user$\n$\nDo you want to delete it?$\nThis will remove all user settings, caches, and saves." IDYES continue3
        !insertmacro ResetCleanInstall
        continue3:
      ${EndIf}
    ${EndIf}
  ${ElseIf} $PortableMode == 1
    ${If} $0 == 1
      ${If} $1 == 1
        MessageBox MB_ICONQUESTION|MB_YESNO "Portable mode selected, but multiple user data folders were detected:$\n$\n- Portable mode: $INSTDIR\user$\n- Default mode: $APPDATA\eden$\n$\nDo you want to use the AppData user data to overwrite the portable one?" IDYES use_appdata
        ; If user chose to keep portable mode user data
        RMDir /r "$APPDATA\eden"
        MessageBox MB_ICONINFORMATION "Default mode user data folders deleted. Using portable user data."
        Goto done_migration
        
        use_appdata:
          RMDir /r "$INSTDIR\user"
          CreateDirectory "$INSTDIR\user"
          CopyFiles /SILENT "$APPDATA\eden\*" "$INSTDIR\user\"
          MessageBox MB_ICONINFORMATION "Default mode user data migrated to portable mode."
        Goto done_migration
      ${Else}
        ; Only portable exists, do nothing
        MessageBox MB_ICONINFORMATION "Portable mode enabled. Existing user data will be used."
      ${EndIf}
    ${Else}
      ${If} $1 == 1
        MessageBox MB_YESNO|MB_ICONQUESTION "Portable mode selected, but default mode user data detected at:$\n$APPDATA\eden$\n$\nDo you want to migrate it to portable mode?" IDNO skip_migration
        CreateDirectory "$INSTDIR\user"
        CopyFiles /SILENT "$APPDATA\eden\*" "$INSTDIR\user\"
        RMDir /r "$APPDATA\eden"
        MessageBox MB_ICONINFORMATION "Default mode user data migrated to portable mode."
        skip_migration:
      ${Else}
        ; If none of previous user data exists, just create the user folder
        CreateDirectory "$INSTDIR\user"
        MessageBox MB_ICONINFORMATION "Portable mode enabled. A new user data folder was created."
      ${EndIf}
    ${EndIf}
  ${EndIf}
  done_migration:
FunctionEnd

Function CustomFinishPageCreate
  !insertmacro MUI_HEADER_TEXT "Installation Complete" "Eden has been installed successfully."
  nsDialogs::Create 1018
  Pop $CustomFinishPageDialog
  ${If} $CustomFinishPageDialog == error
    Abort
  ${EndIf}

  ${NSD_CreateCheckbox} 0u 0u 100% 12u "Launch Eden after install"
  Pop $LaunchEdenCheckbox
  ${NSD_SetState} $LaunchEdenCheckbox $LaunchEden

  nsDialogs::Show
FunctionEnd

Function CustomFinishPageLeave
  ${NSD_GetState} $LaunchEdenCheckbox $LaunchEden
  
  ${If} $LaunchEden == 1
    Exec "$INSTDIR\eden.exe"
  ${EndIf}
FunctionEnd

Function un.CleanUninstallPageCreate
  !insertmacro MUI_HEADER_TEXT "Uninstallation Options" "Customize your Eden uninstallation"
  nsDialogs::Create 1018
  Pop $UninstallerPageDialog
  ${If} $UninstallerPageDialog == error
    Abort
  ${EndIf}

  ${NSD_CreateCheckbox} 0u 0u 100% 12u "Clean Uninstall (Remove all user data)"
  Pop $CleanUninstallCheckbox
  ${NSD_SetState} $CleanUninstallCheckbox 0 ; unchecked by default

  ${NSD_CreateCheckbox} 0u 16u 100% 12u "Back up user data"
  Pop $BackupUserDataCheckbox
  ${NSD_SetState} $BackupUserDataCheckbox $BackupUserData
  ShowWindow $BackupUserDataCheckbox ${SW_HIDE}

  GetFunctionAddress $0 un.ClickCleanUninstall
  nsDialogs::OnClick $CleanUninstallCheckbox $0
  GetFunctionAddress $0 un.ClickBackupUserData
  nsDialogs::OnClick $BackupUserDataCheckbox $0
  
  nsDialogs::Show
FunctionEnd

Function un.ClickCleanUninstall
  Pop $R0
  ${NSD_GetState} $CleanUninstallCheckbox $CleanUninstall
  ${If} $CleanUninstall == 1
    ShowWindow $BackupUserDataCheckbox ${SW_SHOW}
  ${Else}
    ShowWindow $BackupUserDataCheckbox ${SW_HIDE}
    StrCpy $BackupUserData 0
    ${NSD_SetState} $BackupUserDataCheckbox 0
  ${EndIf}
FunctionEnd
    
Function un.ClickBackupUserData
  Pop $R0
  ${NSD_GetState} $BackupUserDataCheckbox $BackupUserData
  ${If} $BackupUserData == 1
    MessageBox MB_YESNO|MB_ICONQUESTION "Do you want to back up your Eden user data now?" IDYES continue
    StrCpy $BackupUserData 0
    ${NSD_SetState} $BackupUserDataCheckbox $BackupUserData
    Goto end
    
    continue:
    Call un.DoBackupUserData
    EnableWindow $BackupUserDataCheckbox 0
  ${EndIf}
  end:
FunctionEnd

Function un.DoBackupUserData
  ${GetTime} "" "LS" $R1 $R2 $R3 $R4 $R5 $R6 $R7
  StrCpy $R8 "$R3-$R2-$R1_$R5-$R6-$R7"
  StrCpy $R9 "$DOCUMENTS\EdenBackup\$R8"
  CreateDirectory "$R9"

  ; Backup AppData user data
  SetShellVarContext current
  ${If} ${FileExists} "$APPDATA\eden"
    CreateDirectory "$R9\AppData"
    CopyFiles /SILENT "$APPDATA\eden\*" "$R9\AppData\"
  ${EndIf}

  ; Backup Portable user data
  ${If} ${FileExists} "$INSTDIR\user"
    CreateDirectory "$R9\Portable"
    CopyFiles /SILENT "$INSTDIR\user\*" "$R9\Portable\"
  ${EndIf}

  MessageBox MB_ICONINFORMATION "Your Eden user data has been backed up to:$\n$R9"
FunctionEnd
    
Function un.CleanUninstallPageLeave
  ${NSD_GetState} $CleanUninstallCheckbox $CleanUninstall

  ${If} $CleanUninstall == 1
    ; Detect both portable mode and appdata configs
    StrCpy $0 0 ; initial portable mode
    StrCpy $1 0 ; initial appdata exits

    ${If} ${FileExists} "$INSTDIR\user"
      StrCpy $0 1
    ${EndIf}

    SetShellVarContext current ; Set current due to eden default config location
    ${If} ${FileExists} "$APPDATA\eden"
      StrCpy $1 1
    ${EndIf}

    ${If} $0 == 0
      ${If} $1 == 0
        MessageBox MB_ICONINFORMATION "No user data was found! Clean uninstall is not needed."
        !insertmacro ResetCleanUninstall
      ${Else}
        MessageBox MB_ICONEXCLAMATION|MB_YESNO "User data detected in AppData at:$\n$APPDATA\eden$\n$\nDo you want to delete it?$\nThis will remove all user settings, caches, and saves." IDYES continue
        !insertmacro ResetCleanUninstall
        continue:
      ${EndIf}
    ${ElseIf} $0 == 1
      ${If} $1 == 1
        MessageBox MB_ICONEXCLAMATION|MB_YESNO "Multiple user data folders were detected:$\n$\n- Portable mode: $INSTDIR\user$\n- Default mode: $APPDATA\eden$\n$\nDo you want to delete them both?$\nThis will remove all user settings, caches, and saves." IDYES continue2
        !insertmacro ResetCleanUninstall
        continue2:
      ${Else}
        MessageBox MB_ICONEXCLAMATION|MB_YESNO "Portable mode user data detected at:$\n$INSTDIR\user$\n$\nDo you want to delete it?$\nThis will remove all user settings, caches, and saves." IDYES continue3
        !insertmacro ResetCleanUninstall
        continue3:
      ${EndIf}
    ${EndIf}
  ${EndIf}
FunctionEnd

Function un.CustomFinishPageCreate
  !insertmacro MUI_HEADER_TEXT "Uninstallation Complete" "Eden has been removed from your computer."
  nsDialogs::Create 1018
  Pop $UnFinishPageDialog
  ${If} $UnFinishPageDialog == error
    Abort
  ${EndIf}

  ${NSD_CreateCheckbox} 0u 0u 100% 12u "Get the latest Eden nightly"
  Pop $OpenLatestCheckbox
  ${NSD_SetState} $OpenLatestCheckbox $OpenLatest

  nsDialogs::Show
FunctionEnd

Function un.CustomFinishPageLeave
  ${NSD_GetState} $OpenLatestCheckbox $OpenLatest
  ${If} $OpenLatest == 1
    ExecShell "open" "https://github.com/pflyly/eden-nightly/releases/latest"
  ${EndIf}
FunctionEnd

Section "Installation"
  SectionIn RO
  ; Initial InstallMode context
  ${If} $MultiUser.InstallMode == "AllUsers"
    SetShellVarContext all
  ${Else}
    SetShellVarContext current
  ${EndIf}
  
  ; Perform clean install if selected
  ${If} $CleanInstall == 1
    ${If} $INSTDIR != ""
      ${If} ${FileExists} "$INSTDIR\eden.exe"
        RMDir /r "$INSTDIR"
      ${EndIf}

      ; Attempt to clean portable mode data if exists
      ${If} ${FileExists} "$INSTDIR\user"
        RMDir /r "$INSTDIR\user"
      ${EndIf}
        
      ; Attempt to clean AppData config if exists
      ; Eden always uses current user context for AppData
      SetShellVarContext current
      ${If} ${FileExists} "$APPDATA\eden"
        DeleteRegKey HKCU "Software\eden"
        RMDir /r "$APPDATA\eden"
      ${EndIf}
      
      ; Recover InstallMode context
      ${If} $MultiUser.InstallMode == "AllUsers"
        SetShellVarContext all
      ${Else}
        SetShellVarContext current
      ${EndIf}

      ; Remove old start menu shortcuts
      Delete "$SMPROGRAMS\${PRODUCT_DISPLAY_NAME}\${PRODUCT_DISPLAY_NAME}.lnk"
      Delete "$SMPROGRAMS\${PRODUCT_DISPLAY_NAME}\Uninstall ${PRODUCT_DISPLAY_NAME}.lnk"
      RMDir /r "$SMPROGRAMS\${PRODUCT_DISPLAY_NAME}"

      ; Remove old desktop shortcut
      Delete "$DESKTOP\${PRODUCT_DISPLAY_NAME}.lnk" 
    ${EndIf}
  ${EndIf}

  ; Recreate $INSTDIR\user folder if clean install + portable mode
  ${If} $CleanInstall == 1
    ${If} $PortableMode == 1
      CreateDirectory "$INSTDIR\user"
    ${EndIf}
  ${EndIf}

  SetOutPath "$INSTDIR"
  File /r "${BINARY_SOURCE_DIR}\*"

  ; Create start menu and desktop shortcuts
  CreateDirectory "$SMPROGRAMS\${PRODUCT_DISPLAY_NAME}"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_DISPLAY_NAME}\${PRODUCT_DISPLAY_NAME}.lnk" "$INSTDIR\eden.exe"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_DISPLAY_NAME}\Uninstall ${PRODUCT_DISPLAY_NAME}.lnk" "$INSTDIR\uninst.exe" "/$MultiUser.InstallMode"
  ${If} $DesktopShortcut == 1
    CreateShortCut "$DESKTOP\${PRODUCT_DISPLAY_NAME}.lnk" "$INSTDIR\eden.exe"
  ${EndIf}

  SetAutoClose false
SectionEnd

Section -RegisterUninstallerMetadata
  WriteUninstaller "$INSTDIR\uninst.exe"

  WriteRegStr SHCTX "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\eden.exe"

  ; Write metadata for add/remove programs applet
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "DisplayName" "${PRODUCT_DISPLAY_NAME}"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe /$MultiUser.InstallMode"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\eden.exe"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "InstallLocation" "$INSTDIR"
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD SHCTX "${PRODUCT_UNINST_KEY}" "EstimatedSize" "$0"
  WriteRegStr SHCTX "${PRODUCT_UNINST_KEY}" "Comments" "Nintendo Switch emulator"
SectionEnd

Section Uninstall
  
  ; Set InstallMode context
  ${If} $MultiUser.InstallMode == "AllUsers"
    SetShellVarContext all
  ${Else}
    SetShellVarContext current
  ${EndIf}

  ; Remove shortcuts
  Delete "$SMPROGRAMS\${PRODUCT_DISPLAY_NAME}\Uninstall ${PRODUCT_DISPLAY_NAME}.lnk"
  Delete "$DESKTOP\${PRODUCT_DISPLAY_NAME}.lnk"
  Delete "$SMPROGRAMS\${PRODUCT_DISPLAY_NAME}\${PRODUCT_DISPLAY_NAME}.lnk"
  RMDir /r "$SMPROGRAMS\${PRODUCT_DISPLAY_NAME}"
    
  ${If} $CleanUninstall == 1
    ; Attempt to clean portable mode data if exists
    ${If} ${FileExists} "$INSTDIR\user"
      RMDir /r "$INSTDIR\user"
    ${EndIf}
        
    ; Attempt to clean AppData config if exists
    ; Eden always uses current user context for AppData
    SetShellVarContext current
    ${If} ${FileExists} "$APPDATA\eden"
      DeleteRegKey HKCU "Software\eden"
      RMDir /r "$APPDATA\eden"
    ${EndIf}
    
    ; Recover InstallMode context
    ${If} $MultiUser.InstallMode == "AllUsers"
      SetShellVarContext all
    ${Else}
       SetShellVarContext current
    ${EndIf}

  ${EndIf}
    
  ; Remove installed files
  Delete "$INSTDIR\*.dll"
  Delete "$INSTDIR\eden.exe"
  Delete "$INSTDIR\uninst.exe"
  RMDir /r "$INSTDIR\generic"
  RMDir /r "$INSTDIR\iconengines"
  RMDir /r "$INSTDIR\imageformats"
  RMDir /r "$INSTDIR\networkinformation"
  RMDir /r "$INSTDIR\platforms"
  RMDir /r "$INSTDIR\styles"
  RMDir /r "$INSTDIR\tls"
  RMDir /r "$INSTDIR\translations"
  RMDir /r "$INSTDIR"

  DeleteRegKey HKCU "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKCU "${PRODUCT_DIR_REGKEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_DISPLAY_NAME}"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_DISPLAY_NAME}"

  SetAutoClose false
SectionEnd
