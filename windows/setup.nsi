; 上班鼓励器 · Windows 安装包脚本（NSIS 3，Unicode）
Unicode true

!define APPNAME "上班鼓励器"
!define COMPANY "qishuai6"
!define EXE "上班鼓励器.exe"
!define VERSION "1.1.0"

Name "${APPNAME} ${VERSION}"
OutFile "../release/WorkCheer-Windows-v1.1-Setup.exe"
InstallDir "$LOCALAPPDATA\WorkCheer"
InstallDirRegKey HKCU "Software\${APPNAME}" "InstallDir"
RequestExecutionLevel user
SetCompressor /SOLID lzma

; 安装器外观
Icon "appIcon.ico"
Caption "${APPNAME} 安装向导"
BrandingText "${APPNAME} · 把工资折算到秒"

Page directory
Page instfiles

Section "安装"
  SetOutPath "$INSTDIR"
  File "/oname=${EXE}" "../windows/workcheer-win/dist/上班鼓励器/上班鼓励器-win_x64.exe"
  File "/oname=resources.neu" "../windows/workcheer-win/dist/上班鼓励器/resources.neu"
  File "/oname=使用说明.txt" "../windows/workcheer-win/pack/使用说明.txt"

  ; 开始菜单快捷方式
  CreateDirectory "$SMPROGRAMS\${APPNAME}"
  CreateShortcut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\${EXE}"
  CreateShortcut "$SMPROGRAMS\${APPNAME}\卸载${APPNAME}.lnk" "$INSTDIR\uninstall.exe"
  ; 桌面快捷方式
  CreateShortcut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\${EXE}"

  ; 写卸载信息（控制面板「应用和功能」可见）
  WriteRegStr HKCU "Software\${APPNAME}" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "Publisher" "${COMPANY}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayIcon" "$INSTDIR\${EXE}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; 装完直接运行
  Exec "$INSTDIR\${EXE}"
SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\${EXE}"
  Delete "$INSTDIR\resources.neu"
  Delete "$INSTDIR\使用说明.txt"
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR"
  Delete "$DESKTOP\${APPNAME}.lnk"
  Delete "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk"
  Delete "$SMPROGRAMS\${APPNAME}\卸载${APPNAME}.lnk"
  RMDir "$SMPROGRAMS\${APPNAME}"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
  DeleteRegKey HKCU "Software\${APPNAME}"
SectionEnd
