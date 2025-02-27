@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b 0
)

ping -n 1 -4 1.1.1.1 | find "time=" > nul 2>&1
if !errorlevel! == 1 (
	echo You must have an internet connection to use this script.
	pause
	exit /b
)

set /P DNS1="Set primary DNS Server (e.g. 1.1.1.1): "
set /P DNS2="Set alternate DNS Server (e.g. 1.0.0.1): "
for /f "tokens=4" %%a in ('netsh int show interface ^| find "Connected"') do set DeviceName=%%a
for /f "tokens=3" %%a in ('netsh int ip show config name^="!DeviceName!" ^| findstr "IP Address:"') do set LocalIP=%%a
for /f "tokens=3" %%a in ('netsh int ip show config name^="!DeviceName!" ^| findstr "Default Gateway:"') do set DHCPGateway=%%a
for /f "tokens=2 delims=()" %%a in ('netsh int ip show config name^="!DeviceName!" ^| findstr /r "(.*)"') do for %%i in (%%a) do set DHCPSubnetMask=%%i

:: set static ip
netsh int ipv4 set address name="!DeviceName!" static !LocalIP! !DHCPSubnetMask! !DHCPGateway! > nul 2>&1
netsh int ipv4 set dns name="!DeviceName!" static !DNS1! primary > nul 2>&1
netsh int ipv4 add dns name="!DeviceName!" !DNS2! index=2 > nul 2>&1

:: display details about the connection
echo Interface: !DeviceName!
echo Private IP: !LocalIP!
echo Subnet Mask: !DHCPSubnetMask%!
echo Gateway: !DHCPGateway!
echo Primary DNS: !DNS1!
echo Alternate DNS: !DNS2!
echo.
echo If this information appears to be incorrect or is blank, please report it on Discord or Github.

choice /c:yn /n /m "Do you want to disable static ip services (break internet icon)? [Y/N] "
if !errorlevel! == 1 goto staticIPS
if !errorlevel! == 2 goto staticIPC
goto staticIPS

:staticIPS
!setSvcScript! Dhcp 4
!setSvcScript! netprofm 4
!setSvcScript! NlaSvc 4

:staticIPC
echo Finished, please reboot your device for changes to apply.
pause
exit /b