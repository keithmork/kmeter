@echo off
setlocal enabledelayedexpansion

rem [IMPORTANT!] Set JMETER_HOME environment variable first, or define it here
rem The path of JMeter should contain NO space
rem "JMETER_HOME="

rem JMeter exec
set "JMETER=%JMETER_HOME%/bin/jmeter.bat"

rem ---------------------------------------------------------------------------
rem Checks
rem ---------------------------------------------------------------------------

rem Check JMETER_HOME
if "%JMETER_HOME%" == "" (
    echo [ERROR] Cannot find environment variable JMETER_HOME
    pause && exit /b 1
)

rem Check JMeter exec
if not exist "%JMETER%" (
    echo [ERROR] Cannot find JMeter executable: %JMETER%
    echo Please check your JMETER_HOME environment variable!
    pause && exit /b 1
)

rem ---------------------------------------------------------------------------
rem Run
rem ---------------------------------------------------------------------------

set "base_dir=%~dp0/../.."
set "lib_dir=%base_dir%/lib"
set "report_dir=%base_dir%/result"

if not exist "%report_dir%" md "%report_dir:/=\%"

rem 如果遇上这错误：
rem ERROR - jmeter.engine.ClientJMeterEngine: java.rmi.ConnectException: Connection refused to host: 127.0.0.1
rem 加上 -Djava.rmi.server.hostname=xxx.xxx.xxx.xxx
call "%JMETER%" -s -j "%report_dir%/jmeter-server.log" "-Juser.classpath=%lib_dir%/ext;%lib_dir%;%JMETER_HOME%/lib/ext;%JMETER_HOME%/lib" "-Jsearch_paths=%lib_dir%/ext" "-Jincludecontroller.prefix=%base_dir%/user_file/testplan/" -q "%base_dir%/conf/user.properties"
