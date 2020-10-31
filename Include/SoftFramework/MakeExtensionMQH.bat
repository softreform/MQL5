@echo off

:
:	Get the current date and time in a format to show in the files
:
for /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set ldt=%%j
set ldt=%ldt:~0,4%-%ldt:~4,2%-%ldt:~6,2% %ldt:~8,2%:%ldt:~10,2%:%ldt:~12,2%

:
:	Make sure there is an Extensions folder here
:
if not exist Extensions\ goto :quit

:
:	Move into the extensions folder to start
:
cd Extensions

:
:	Remove any existing mqh files
:
del *.mqh

:
:	Step through the directories here and build up mqh files for each
:
for /D %%f in (*) do (
	call :makemqh %%f
)

:
: Build the AllExtensions file
:
call :makemqh .

goto :quit

:makemqh

set mcurrent=%cd%
set mpath1=%~f1
for %%f in (%mpath1%) do set mpath=%%~nxf
set msub=%mpath%/
if "%mcurrent%"=="%mpath1%" set msub=
set mfile=All%mpath%.mqh

echo /* > %mfile%
echo  	All%mn2%.mqh >> %mfile%
echo.  >> %mfile%
echo 	Copyright 2020, Soft Reform >> %mfile%
echo 	https://www.mql5.com >> %mfile%
echo.  >> %mfile%
echo 	Auto Generated at %ldt% >> %mfile%
echo.  >> %mfile%
echo */ >> %mfile%
echo.  >> %mfile%
echo // >> %mfile%
echo //	Extension %mn2% go here >> %mfile%
echo // >> %mfile%

for %%f in (%1\*.mqh) do (
	if not "%%~nxf"=="%mfile%" echo #include "%msub%%%~nxf" >> %mfile%
)
echo Built include file %mfile%

goto :eof

:quit
echo Finished
pause
goto :eof