@echo off
rem Father & Son: let the game take online connections (son hosts, dad joins).
set EXE=%~dp0FatherAndSon.exe
netsh advfirewall firewall delete rule name="Father and Son" >nul 2>&1
netsh advfirewall firewall add rule name="Father and Son" dir=in action=allow program="%EXE%" enable=yes profile=any >nul
netsh advfirewall firewall add rule name="Father and Son" dir=in action=allow protocol=UDP localport=24567,24569 enable=yes profile=any >nul
netsh advfirewall firewall add rule name="Father and Son" dir=in action=allow protocol=TCP localport=8787,8789 enable=yes profile=any >nul
