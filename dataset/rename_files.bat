@echo off
setlocal enabledelayedexpansion

set "folder=../dataset"  REM Replace with the path to your folder
set "extension=.jpg"  REM Replace with the file extension of your files
set "prefix=daunjambubiji"

cd "%folder%"

set /a count=1

for %%f in (*%extension%) do (
    set "name=%%~nf"
    set "name=!name: =!"
    set "name=!name:(=!"
    set "name=!name:)=!"
    ren "%%~ff" "!prefix!!count!!extension!"
    set /a count+=1
    if !count! gtr 200 (
        goto :EOF
    )
)
