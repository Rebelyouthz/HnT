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
; Online play: the son reads his number to dad - shown right away.
!define MUI_FINISHPAGE_SHOWREADME ""
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Visa min IP för onlinespel (sonen läser upp den för pappa)"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION ShowMyIP
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Swedish"

Section "Install"
  ; First clear out every other copy: old installs, old Setup.exe files,
  ; zips and loose game folders (never this running Setup.exe, never a
  ; developer working copy with project.godot / .git). The save stays.
  InitPluginsDir
  File "/oname=$PLUGINSDIR\Cleanup.ps1" "Cleanup.ps1"
  DetailPrint "Tar bort gamla versioner och gamla setup-filer..."
  nsExec::ExecToLog 'powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$PLUGINSDIR\Cleanup.ps1" -Mode install -Keep "$EXEPATH"'
  Pop $0
  SetOutPath "$INSTDIR"
  File "..\..\build\windows\FatherAndSon.exe"
  File "Cleanup.ps1"
  File "..\..\assets\icon\fns.ico"
  File "MyIP.ps1"
  File "MyIP.cmd"
  File "OpenFirewall.cmd"
  ; Windows firewall: let the game take the online connection (the son's PC
  ; hosts). Asks once for permission; saying no just means Windows asks
  ; again the first time the game hosts.
  ExecShell "runas" "$INSTDIR\OpenFirewall.cmd" "" SW_HIDE
  CreateDirectory "$SMPROGRAMS\Father & Son"
  CreateShortCut "$SMPROGRAMS\Father & Son\Father & Son.lnk" "$INSTDIR\FatherAndSon.exe" "" "$INSTDIR\fns.ico" 0
  CreateShortCut "$DESKTOP\Father & Son.lnk" "$INSTDIR\FatherAndSon.exe" "" "$INSTDIR\fns.ico" 0
  CreateShortCut "$SMPROGRAMS\Father & Son\Father & Son - Min IP (online).lnk" "$INSTDIR\MyIP.cmd" "" "$INSTDIR\fns.ico" 0
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  CreateShortCut "$SMPROGRAMS\Father & Son\Avinstallera Father & Son.lnk" "$INSTDIR\Uninstall.exe" "" "$INSTDIR\fns.ico" 0
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FatherAndSon" "DisplayName" "Father & Son"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FatherAndSon" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FatherAndSon" "DisplayIcon" "$INSTDIR\fns.ico"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FatherAndSon" "Publisher" "FnS"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FatherAndSon" "DisplayVersion" "0.4.0"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FatherAndSon" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FatherAndSon" "NoRepair" 1
SectionEnd

Function ShowMyIP
  ExecShell "" "$INSTDIR\MyIP.cmd" "" SW_HIDE
FunctionEnd

Section "Uninstall"
  ; Everything: this install, every other installed copy, old Setup.exe
  ; files and zips, shortcuts, the firewall rule. A developer working copy
  ; (project.godot / .git) is never touched. The save goes only on "Ja".
  InitPluginsDir
  CopyFiles /SILENT "$INSTDIR\Cleanup.ps1" "$PLUGINSDIR\Cleanup.ps1"
  StrCpy $1 ""
  MessageBox MB_YESNO|MB_ICONQUESTION|MB_DEFBUTTON2 "Ta bort sparfilen också (all progress i spelet)?$\n$\nNej = sparfilen ligger kvar om du installerar igen." IDNO +2
  StrCpy $1 "-Saves"
  nsExec::ExecToLog 'powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$PLUGINSDIR\Cleanup.ps1" -Mode uninstall $1'
  Pop $0
  Delete "$DESKTOP\Father & Son.lnk"
  Delete "$SMPROGRAMS\Father & Son\Father & Son.lnk"
  RMDir "$SMPROGRAMS\Father & Son"
  Delete "$INSTDIR\FatherAndSon.exe"
  Delete "$INSTDIR\Uninstall.exe"
  Delete "$INSTDIR\fns.ico"
  Delete "$INSTDIR\MyIP.ps1"
  Delete "$INSTDIR\MyIP.cmd"
  Delete "$INSTDIR\OpenFirewall.cmd"
  Delete "$SMPROGRAMS\Father & Son\Father & Son - Min IP (online).lnk"
  Delete "$SMPROGRAMS\Father & Son\Avinstallera Father & Son.lnk"
  RMDir "$SMPROGRAMS\Father & Son"
  Delete "$INSTDIR\Cleanup.ps1"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\FatherAndSon"
SectionEnd
