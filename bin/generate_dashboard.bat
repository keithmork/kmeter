@echo off
setlocal enabledelayedexpansion

rem Check JMETER_HOME
if "%JMETER_HOME%" == "" (
    echo [ERROR] Cannot find environment variable JMETER_HOME
    pause && exit /b 1
)

rem JMeter exec
set "JMETER=%JMETER_HOME%/bin/jmeter.bat"

rem Check JMeter exec
if not exist "%JMETER%" (
    echo [ERROR] Cannot find JMeter executable: %JMETER%
    echo Please check your JMETER_HOME environment variable!
    pause && exit /b 1
)

rem Help
if "%~1" == "" call :show_help_info && exit /b 0
if "%~1" == "help" call :show_help_info && exit /b 0
if "%~1" == "--help" call :show_help_info && exit /b 0
if "%~1" == "-h" call :show_help_info && exit /b 0
if "%~1" == "/h" call :show_help_info && exit /b 0
if "%~1" == "/?" call :show_help_info && exit /b 0

set "script_dir=%~dp0"
rem the csv file to parse
set "result_log_file=%~1"

rem use the directory of the result log file
set "output_dir=%~dp1"

rem get date (eg. %date%: 02/27/2017 Mon -> 02/27/2017)
for /f "delims= " %%i in ("%date%") do (
    set "today=%%i"
    goto :break
)
:break
rem eg. 02/27/2017 -> 02-27-2017, %time% 14:06:28.06 -> 140628
set "date_time=%today:/=-%_%time:~0,2%%time:~3,2%%time:~6,2%"

if exist "%output_dir%/dashboard" (
    set "dashboard_dir=%output_dir%/dashboard_%date_time%"
) else (
    set "dashboard_dir=%output_dir%/dashboard"
)

rem generate HTML report
call "%JMETER%" -g "%result_log_file%" -o "%dashboard_dir%" -j "%output_dir%/generate_report.log" -q "%script_dir%/../../conf/user.properties" %~2 %~3 %~4 %~5 %~6 %~7 %~8 %~9

rem check if file exists
if exist "%dashboard_dir%/index.html" (
    echo SUCCESS
    echo See: %dashboard_dir%/index.html
) else (
    echo FAILED
)

goto :eof

rem ---------------------------------------------------------------------------
rem Functions
rem ---------------------------------------------------------------------------

:show_help_info
    echo Usage: generate_html_dashboard.bat result_log_file [other_jmeter_args]
exit /b 0
