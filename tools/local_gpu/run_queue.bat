@echo off
cd /d %~dp0
call venv\Scripts\activate
python local_wan.py --list
python local_wan.py
pause
