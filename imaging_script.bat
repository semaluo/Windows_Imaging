::Part 1 - Assign Drive letter to System Partition
md C:\Boot
IF EXIST c:\boot\Assign-S_diskpart.txt del c:\boot\Assign-S_diskpart.txt

echo Select disk 0 > c:\boot\Assign-S_diskpart.txt
echo select partition 1 >> c:\boot\Assign-S_diskpart.txt
echo assign letter s >> c:\boot\Assign-S_diskpart.txt
echo exit >> c:\boot\Assign-S_diskpart.txt

diskpart /s c:\boot\Assign-S_diskpart.txt

::Part 2 - Copy WinPE files to System Partition

net use n: \\bsp-nas2.its.bethel.edu\bsp-altiris\images\winPE_Embedded /user:bu\bsp-altiris-user maydGad9 /persistent:no

mkdir s:\winPE_Embedded
copy n:\boot\boot.sdi s:\winPE_Embedded\boot.sdi
copy n:\sources\boot.wim s:\winPE_Embedded\boot.wim

net use n: /delete

::Part 3 Image with .bat file

REM Create customAction.bat for WinPE to use

echo net use i: "\\bsp-nas2.its.bethel.edu\bsp-altiris\Images" /user:BU\bsp-altiris-user maydGad9 /persistent:no > S:\customAction.bat
echo call I:\Win7x32Aug11.bat >> S:\customAction.bat

:::Contents of .bat file
diskpart /s "\\bsp-nas2.its.bethel.edu\bsp-altiris\images\diskpartWin7.txt"
"\\bsp-nas2.its.bethel.edu\bsp-altiris\Images\imagex.exe" /apply "\\bsp-nas2.its.bethel.edu\bsp-altiris\images\Windows\Win7x32Aug11.wim" 1 C:
c:\windows\system32\bcdboot C:\windows
exit


::Part 4 - Remove Drive Letter from System Partition

IF EXIST c:\boot\Assign-S_diskpart.txt del c:\boot\Assign-S_diskpart.txt

echo Select disk 0 > c:\boot\Assign-S_diskpart.txt
echo select partition 1 >> c:\boot\Assign-S_diskpart.txt
echo remove letter s >> c:\boot\Assign-S_diskpart.txt
echo exit >> c:\boot\Assign-S_diskpart.txt

diskpart /s c:\boot\Assign-S_diskpart.txt
del c:\boot\Assign-S_diskpart.txt


::Part 5 - Backup the Pre-WinPE BCD store to file

BCDEdit /export "C:\Boot\Pre-WinPE_BCD"


::Part 6 - Create BCD Entry for WinPE as Default

BCDEdit /create {ramdiskoptions}
BCDedit /set {ramdiskoptions} description "Windows PE"
BCDedit /set {ramdiskoptions} ramdisksdidevice partition=\Device\HarddiskVolume1
BCDedit /set {ramdiskoptions} ramdisksdipath \winPE_Embedded\boot.sdi

for /f "tokens=7" %%a in ('BCDEdit /copy {default} /d "Windows PE"') do set guid=%%a
set _result=%guid:.=%
set guid=%_result%
BCDEdit /set %guid% device ramdisk=[\Device\HarddiskVolume1]\winPE_Embedded\boot.wim,{ramdiskoptions}
BCDEdit /set %guid% osdevice ramdisk=[\Device\HarddiskVolume1]\winPE_Embedded\boot.wim,{ramdiskoptions}
BCDEdit /set %guid% winpe yes
BCDEdit /set %guid% detecthal on

BCDEdit /default %guid%
BCDEdit /timeout 0


::Part 7 - Reboot
shutdown /f /r /t 0