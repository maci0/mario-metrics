@echo off
set /p PlayerName="Enter your name: "
set /p PlayerEmail="Enter your email: "
set /p PlayerCompany="Enter your company name: "

setx PLAYERNAME "%PlayerName%"
setx PLAYEREMAIL "%PlayerEmail%"
setx PLAYERCOMPANY "%PlayerCompany%"

START /wait Mesen.exe /fullscreen smb.nes mesen.lue