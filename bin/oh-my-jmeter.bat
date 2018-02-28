@echo off
setlocal EnableDelayedExpansion

rem [IMPORTANT!] Set JMETER_HOME environment variable first, or define it here.
rem The path of JMeter should contain NO space.
rem "JMETER_HOME="


rem ---------------------------------------------------------------------------
rem Command line args
rem ---------------------------------------------------------------------------

set "TEST_PLAN_FILE=%~1"

rem %~2 to %~9 can be any JMeter args


rem ---------------------------------------------------------------------------
rem Help
rem ---------------------------------------------------------------------------

if "%~1" == "help" call :show_help_info && exit /b
if "%~1" == "--help" call :show_help_info && exit /b
if "%~1" == "-h" call :show_help_info && exit /b
if "%~1" == "/h" call :show_help_info && exit /b
if "%~1" == "/?" call :show_help_info && exit /b


rem ---------------------------------------------------------------------------
rem Checks
rem ---------------------------------------------------------------------------

rem Check JMETER_HOME
if "%JMETER_HOME%" == "" (
	echo [ERROR] Cannot find environment variable JMETER_HOME
	pause && exit /b 1
)

rem JMeter executable
set "JMETER=%JMETER_HOME%/bin/jmeter.bat"

if not exist "%JMETER%" (
	echo [ERROR] Cannot find JMeter executable: %JMETER%
	echo Please make sure the path in your JMETER_HOME environment variable is correct!
	pause && exit /b 1
)

if not "%TEST_PLAN_FILE%" == "" (
	if not exist "%TEST_PLAN_FILE%" (
		echo Not a valid test plan file: %TEST_PLAN_FILE%
	    exit /b 1
	)
)


rem ---------------------------------------------------------------------------
rem Default configs
rem ---------------------------------------------------------------------------

rem oh-my-jmeter home -- parent dir of this script
set "BASE_DIR=%~dp0/.."

set "CONFIG_DIR=%BASE_DIR%/conf"
set "GENERAL_CONFIG_FILE=%CONFIG_DIR%/general.properties"
set "SAVE_RESULT_CONFIG_FILE=%CONFIG_DIR%/save_result.properties"
set "REMOTE_TESTING_CONFIG_FILE=%CONFIG_DIR%/remote.properties"

set "LIB_DIR=%BASE_DIR%/lib"
set "PLUGIN_DIR=%BASE_DIR%/lib/ext"

set "USER_FILE_DIR=%BASE_DIR%/user_file"
set "TEST_PLAN_DIR=%USER_FILE_DIR%/test_plan"
set "DATA_DIR=%USER_FILE_DIR%/data"
set "SCRIPT_DIR=%USER_FILE_DIR%/script"
set "BODY_DIR=%USER_FILE_DIR%/response_body"

set "REPORT_DIR=%BASE_DIR%/report"

if not exist "%REPORT_DIR%" md "%REPORT_DIR:/=\%"


rem ---------------------------------------------------------------------------
rem JVM args
rem ---------------------------------------------------------------------------
rem see %JMETER_HOME%/bin/jmeter.bat for more info

set "heap=-Xms1g -Xmx1g"
set "meta=-XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=512m"

set "general=-Djava.net.preferIPv4Stack=true -XX:-UseBiasedLocking -XX:AutoBoxCacheMax=20000 -XX:+AlwaysPreTouch"
set "system_props=-Djava.security.egd=file:/dev/urandom"

set "gc=-XX:+UseG1GC -XX:MaxGCPauseMillis=250 -XX:G1ReservePercent=20"

rem set "verbose_gc=-XX:+PrintGC -XX:+PrintGCDetails"
rem set "gc_log=-Xloggc:%REPORT_DIR%/gc.log"

set "dump=-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=%REPORT_DIR% -XX:ErrorFile=%REPORT_DIR%/hotspot_err_%p.log"

set "use_utf8=-Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8"

rem set "debug=-XX:+PrintCommandLineFlags"

set "JVM_ARGS=%heap% %meta% %general% %gc% %verbose_gc% %gc_log% %dump% %use_utf8% %system_props% %debug%"


rem ---------------------------------------------------------------------------
rem Run
rem ---------------------------------------------------------------------------

if not "%TEST_PLAN_FILE%" == "" (
	call :run_in_command_line "%TEST_PLAN_FILE%"
) else (
	call :run_in_gui
)

exit /b


rem ---------------------------------------------------------------------------
rem Functions
rem ---------------------------------------------------------------------------

:show_help_info
	echo Usage: oh-my-jmeter.bat [TEST_PLAN_FILE] [other_jmeter_args]
exit /b


:run_in_command_line
	rem get basename  i.e. filename without path & suffix
	set "test_name=%~n1"
	rem eg. 12/03/2017 -> 12-03-2017, %time% 14:06:28.06 -> 140628
	set "start_time=%date:/=-%_%time:~0,2%%time:~3,2%%time:~6,2%"

	set "output_dir=%REPORT_DIR%/%test_name%__%start_time%"
	set "jmeter_log=%output_dir%/jmeter.log"
	md "%output_dir:/=\%"

	call :get_omj_props "%output_dir%"
	call :check_jmeter_version "%jmeter_log%"
	call "%JMETER%" -n -t "%TEST_PLAN_FILE%" -j "%jmeter_log%" -l "%output_dir%/result.csv" -e -o "%output_dir%/dashboard" %OMJ_PROPS% %~3 %~4 %~5 %~6 %~7 %~8 %~9
exit /b


:run_in_gui
	set "jmeter_log=%REPORT_DIR%/jmeter-gui.log"
	
	call :get_omj_props
	call :check_jmeter_version "%jmeter_log%"

	pushd "%TEST_PLAN_DIR%"
	call "%JMETER%" -j "%jmeter_log%" %OMJ_PROPS%
	popd
exit /b


:get_omj_props
	if "%~1" == "" (set "report_dir=%REPORT_DIR%") else (set "report_dir=%~1")

	rem http://jmeter.apache.org/usermanual/get-started.html#options

	set "jmeter_props="-Juser.classpath=%LIB_DIR%" "-Jsearch_paths=%PLUGIN_DIR%" "-Jincludecontroller.prefix=%TEST_PLAN_DIR%/" -q "%GENERAL_CONFIG_FILE%" "-G%GENERAL_CONFIG_FILE%" -q "%SAVE_RESULT_CONFIG_FILE%" "-G%SAVE_RESULT_CONFIG_FILE%" -q "%REMOTE_TESTING_CONFIG_FILE%" "-G%REMOTE_TESTING_CONFIG_FILE%" "

	rem http://jmeter.apache.org/usermanual/component_reference.html#Include_Controller
	rem http://jmeter.apache.org/usermanual/properties_reference.html#include_controller

	set "custom_props="-Jomj.testplanDir=%TEST_PLAN_DIR%" "-Gomj.testplanDir=%TEST_PLAN_DIR%" "-Jomj.dataDir=%DATA_DIR%" "-Gomj.dataDir=%DATA_DIR%" "-Jomj.scriptDir=%SCRIPT_DIR%" "-Gomj.scriptDir=%SCRIPT_DIR%" "-Jomj.libDir=%LIB_DIR%" "-Gomj.libDir=%LIB_DIR%" "-Jomj.reportDir=%report_dir%" "-Gomj.reportDir=%report_dir%" "-Jomj.baseDir=%BASE_DIR%" "-Gomj.baseDir=%BASE_DIR%" "-Jomj.bodyDir=%BODY_DIR%" "-Gomj.bodyDir=%BODY_DIR%""

	set "OMJ_PROPS=%jmeter_props% %custom_props%"
exit /b


:check_jmeter_version
	rem print JMeter version
	for /f "skip=4 delims=" %%i in ('%JMETER% -j "%~1" --version') do (
		set "line=%%i"
		goto :break
	)
	:break
	rem remove characters
	set "line=%line:/=%"
	set "line=%line:\=%"
	set "line=%line:_=%"
	set "line=%line:|=%"
	set "JMETER_VERSION=%line: =%"
	if %JMETER_VERSION:~0,1% lss 3 (
		echo JMeter version must be 3.0 or above. Current version: %JMETER_VERSION%
		exit /b 1
	) else (
		echo JMeter version: %JMETER_VERSION%
	)
exit /b
