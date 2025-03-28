@echo off

call project_env\Scripts\activate

cd /d %~dp0

python API\app.py

pause