; https://gist.github.com/ijprest/3845947
GUID()
{ 
   format = %A_FormatInteger%       ; save original integer format 
   SetFormat Integer, Hex           ; for converting bytes to hex 
   VarSetCapacity(A,16) 
   DllCall("rpcrt4\UuidCreate","Str",A) 
   Address := &A 
   Loop 16 
   { 
      x := 256 + *Address           ; get byte in hex, set 17th bit 
      StringTrimLeft x, x, 3        ; remove 0x1 
      h = %x%%h%                    ; in memory: LS byte first 
      Address++ 
   } 
   SetFormat Integer, %format%      ; restore original format 
   h := SubStr(h,1,8) . "-" . SubStr(h,9,4) . "-" . SubStr(h,13,4) . "-" . SubStr(h,17,4) . "-" . SubStr(h,21,12)
   return h
} 

Start:
InputBox, _name, Your Name, Please enter your name., DONTHIDE, 320, 110

if ErrorLevel
    Exit


if !_name
{
    MsgBox, Name is required
    Goto, Start
}
    
if !RegExMatch(_name, "^[a-z ,A-Z'.]+$") {
    MsgBox, Invalid characters in name
    Exit
}

Email:
InputBox, _email, Your Email Address, Please enter your email address. We will send you an email if you win a prize, DONTHIDE, 320, 160
if ErrorLevel
    Exit

if !_email
{
    MsgBox, Email is required
    Goto, Email
}

if !RegExMatch(_email, "^[0-9a-z._-]+@{1}[0-9a-z.-]{2,}[.]{1}[a-z]{2,5}$") {
    MsgBox, Invalid Email Address
    Goto, Email
}
    
Company:
InputBox, _company, Your Company, Please enter your company name., DONTHIDE, 320, 110
if ErrorLevel
    Exit

if !_email
{
    MsgBox, Company is required
    Goto, Company
}


guid := GUID()

FileDelete, %APPDATA%\player.ini

FileAppend, %_name%`n, %APPDATA%\player.ini
FileAppend, %_email%`n, %APPDATA%\player.ini
FileAppend, %_company%`n, %APPDATA%\player.ini
FileAppend, %guid%`n, %APPDATA%\player.ini

Run, Mesen.exe /fullscreen smb.nes mesen.lua

Sleep, 2100
Run, sendkeys.bat "Mesen - smb" "", , Hide
