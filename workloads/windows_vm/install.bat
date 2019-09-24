@echo off

REM Change into whatever directory path the batch file was launched from
cd %~dp0

REM Launch Installation With Silent Install Configuration
SQLServer2017-SSEI-Expr.exe /ConfigurationFile="%cd%\InstallConfig.ini" /Q /IAcceptSQLServerLicenseTerms

REM Install GUI Management Tools
SSMS-Setup-ENU.exe /passive /norestart

pause
