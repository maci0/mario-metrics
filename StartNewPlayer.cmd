@echo off
set /p PlayerName="Enter your name: "
set /p PlayerEmail="Enter your email: "
set /p PlayerCompany="Enter your company name: "

setx PLAYERNAME "%PlayerName%"
setx PLAYEREMAIL "%PlayerEmail%"
setx PLAYERCOMPANY "%PlayerCompany%"

start Mesen.exe /fullscreen smb.nes mesen.lua
timeout /t 3
call sendkeys.bat "Mesen - smb" ""
