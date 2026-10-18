Unicode True
Name "Father & Son"
OutFile "..\..\build\windows\FatherAndSonSetup.exe"
InstallDir "$LOCALAPPDATA\FatherAndSon"
RequestExecutionLevel user
SetCompressor /SOLID lzma
SetCompressorDictSize 64

!include "MUI2.nsh"

!define MUI_ICON "..\..\assets\icon\fns.ico"
!define MUI_UNICON "..\..\assets\icon\fns.ico"
!define MUI_ABORTWARNING

BrandingText "FnS"

; One click: no folder question, it just installs, then offers to start.
!define MUI_FINISHPAGE_RUN "$INSTDIR\FatherAndSon.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Starta Father & Son nu"
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Swedish"

Section "Install"
  SetOutPath "$INSTDIR"
  File "..\..\build\windows\FatherAndSon.exe"
  File "..\..\assets\icon\fns.ico"
  CreateDirectory "$SMPROGRAMS\Father & Son"
  CreateShortCut "$SMPROGRAMS\Father & Son\Father & Son.lnk" "$INSTDIR\FatherAndSon.exe" "" "$INSTDIR\fns.ico" 0
  CreateShortCut "$DESKTOP\Father & Son.lnk" "$INSTDIR\FatherAndSon.exe" "" "$INSTDIR\fns.ico" 0
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FatherAndSon" "DisplayName" "Father & Son"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FatherAndSon" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FatherAndSon" "DisplayIcon" "$INSTDIR\fns.ico"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FatherAndSon" "Publisher" "FnS"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FatherAndSon" "DisplayVersion" "0.3.0"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FatherAndSon" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FatherAndSon" "NoRepair" 1
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\Father & Son.lnk"
  Delete "$SMPROGRAMS\Father & Son\Father & Son.lnk"
  RMDir "$SMPROGRAMS\Father & Son"
  Delete "$INSTDIR\FatherAndSon.exe"
  Delete "$INSTDIR\Uninstall.exe"
  Delete "$INSTDIR\fns.ico"
  RMDir "$INSTDIR"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FatherAndSon"
SectionEnd
