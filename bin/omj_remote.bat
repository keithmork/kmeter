@echo off

rem 检查JMETER_HOME环境变量 
if "%JMETER_HOME%" == "" (
  echo Missing environment variable JMETER_HOME
  pause && exit 1
)

rem ---------------------------------------------------------------------------
rem JVM参数设置
rem ---------------------------------------------------------------------------

rem 被测程序用什么参数这里也原样来一份 
rem （例外：有些系统/JVM版本必须加 -d64 参数才会运行在64位server模式下）
set "JVM_ARGS=-Xms1024m -Xmx1024m -XX:NewSize=128m -XX:MaxNewSize=128m -XX:+UseG1GC -Djava.net.preferIPv4Stack=true -Djava.net.preferIPv6Addresses=false -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8"

rem ---------------------------------------------------------------------------
rem 默认路径设置
rem ---------------------------------------------------------------------------

rem JMeter启动脚本
set "jmeter=%JMETER_HOME%/bin/jmeter.bat"

rem bin目录（本文件所在目录）
set "bin_dir=%~dp0"

rem MyJMeter根目录
set "base_dir=%bin_dir%/.."
rem 配置文件目录
set "config_dir=%base_dir%/conf"
rem 输出目录
set "output_dir=%base_dir%/reports"
rem 类库目录
set "lib_dir=%base_dir%/lib"

rem 自定义JMeter配置文件
set "user_config=%config_dir%/user.properties"

rem JMeter监听器配置文件
set "listener_config=%config_dir%/listeners.properties"
rem set "listener_config=%config_dir%/listeners-debug.properties"
rem set "listener_config=%config_dir%/listeners-min.properties"

rem 生成报告配置文件
set "report_config=%config_dir%/report.properties"

rem ---------------------------------------------------------------------------
rem 参数设置
rem ---------------------------------------------------------------------------

rem JMeter测试计划文件（命令行传的第1个参数）
set "test_plan_file=%1"

rem ---------------------------------------------------------------------------
rem 输出文件设置
rem ---------------------------------------------------------------------------

rem 获取测试计划文件名
for /f %%i in ("%test_plan_file%") do set "test_plan_name=%%~ni"
rem 获取当前日期时间，如 20161206_141610
set "datetime=%date:~6,4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%"

rem 创建报告目录
set "report_dir=%output_dir%/%test_plan_name%_%datetime%"
mkdir "%report_dir%"

rem JMeter测试记录文件
set "result_log_file=%report_dir%/result.csv"
rem JMeter自身的日志文件
set "jmeter_log_file=%report_dir%/jmeter.log"
rem 使用Generate Summary Results监听器输出到控制台的记录另存为的文件
set "summariy_log_file=%report_dir%/summariser.log"
rem 生成的HTML报告目录（必须不存在或为空）
set "dashboard_dir=%report_dir%/dashboard"

rem ---------------------------------------------------------------------------
rem 运行测试
rem ---------------------------------------------------------------------------

%jmeter% -n -t "%test_plan_file%" -l "%result_log_file%" -j "%jmeter_log_file%" ^
  -q "%user_config%" -q "%listener_config%" -q "%report_config%" ^
  -e -o "%dashboard_dir%" ^
  -Jlog_file.jmeter.reporters.Summariser="%summary_log_file%"

rem 参数说明 http://jmeter.apache.org/usermanual/get-started.html#options

rem Summariser说明
rem http://jmeter.apache.org/usermanual/component_reference.html#Generate_Summary_Results
rem log_file后面指定包名，省略org apache
rem http://jmeter.apache.org/usermanual/properties_reference.html#logging
rem https://jmeter.apache.org/api/org/apache/jmeter/reporters/Summariser.html
