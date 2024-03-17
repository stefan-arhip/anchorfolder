@Echo Off
SetLocal

CD %cd%
Set Updated_App=Anchor
Set File1="Project1.exe"
Set File2="%Updated_App%.exe"
Set Server=\\servername\d$\stefan.arhip\updates\anchor
:: Color 9b
Color 17
D:

If Exist %File2% Del %File2%
Copy %File1% %File2%

Cls

Echo. GNU strip (GNU Binutils) 2.22
Echo. Copyright 2011 Free Software Foundation, Inc.
Echo. This program is free software; you may redistribute it under the terms of
Echo. the GNU General Public License version 3 or (at your option) any later version.
Echo. This program has absolutely no warranty.
Echo.
Echo.         File size         Ratio      Format      Name
Echo.   --------------------   ------   -----------   -----------

For /F "usebackq" %%A In ('%File1%') Do Set Size1=%%~zA
Strip %File2%
For /F "usebackq" %%A In ('%File2%') Do Set Size2=%%~zA
Set /a Ratio1=100* (%Size2%/ 1024)/ (%Size1%/ 1024)
Set /a Ratio2=100* 100* (%Size2%/ 1024)/ (%Size1%/ 1024) %% 100

Set /a Ratio1=100* (%Size2%/ 1024)/ (%Size1%/ 1024)
Set /a Ratio2=100* 100* (%Size2%/ 1024)/ (%Size1%/ 1024)
Set /a Ratio2=%Ratio2%-100*%Ratio1%
Echo.  %Size1% ^-^>   %Size2%  %Ratio1%.%Ratio2%%%                 %File2%
Echo.
Echo.---------------------------------------------------------------

Upx -9 %File2%
Echo.---------------------------------------------------------------

For /F "usebackq" %%A In ('%File2%') Do Set Size2=%%~zA
Set /a Ratio1=100* (%Size2%/ 1024)/ (%Size1%/ 1024)
Set /a Ratio2=100* 100* (%Size2%/ 1024)/ (%Size1%/ 1024) %% 100

Set /a Ratio1=100* (%Size2%/ 1024)/ (%Size1%/ 1024)
Set /a Ratio2=100* 100* (%Size2%/ 1024)/ (%Size1%/ 1024)
Set /a Ratio2=%Ratio2%-100*%Ratio1%
Echo.         File size         Ratio      Format      Name
Echo.   --------------------   ------   -----------   -----------
Echo.  %Size1% ^-^>   %Size2%    %Ratio1%.%Ratio2%%%                 %File2%

Set Exe_Filename=%cd%\%Updated_App%.exe
Set New_Filename=%Server%\%Updated_App%.ex_
Set Ver_Filename=%Server%\%Updated_App%.ver

For %%f In ("%Exe_Filename%") Do Set Filedatetime=%%~tf
Set Filedatetime=%Filedatetime:~6,4%%Filedatetime:~3,2%%Filedatetime:~0,2%-%Filedatetime:~11,2%%Filedatetime:~14,2%

Set Confirm=n
Color 1a

Echo .
Set /p Confirm=Upload new version for %Updated_App%? [y/N]: 
Echo .
If '%Confirm%'=='y' (
	Set Confirm=Y
)
If '%Confirm%'=='Y' (
	Echo [Version] > "%Ver_Filename%"
	Echo Last=%Filedatetime% >> "%Ver_Filename%"
	Echo Executable=%New_Filename% >> "%Ver_Filename%"
	Copy /y "%Exe_Filename%" "%New_Filename%"
)

Rem Pause