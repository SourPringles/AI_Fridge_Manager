@echo off

call project_env\Scripts\activate

cd /d %~dp0/API

python app.py

pause