@echo off

rem GUI模式只应该用来调试，正式测试请用命令行

rem 检查JMETER_HOME环境变量 
if "%JMETER_HOME%" == "" (
  echo Missing environment variable JMETER_HOME
  pause && exit 1
)

rem ---------------------------------------------------------------------------
rem JVM参数设置
rem ---------------------------------------------------------------------------

set "JVM_ARGS=-Xms512m -Xmx512m -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8"

rem ---------------------------------------------------------------------------
rem 默认配置（一般不用动）
rem ---------------------------------------------------------------------------

rem JMeter启动脚本
set "jmeter=%JMETER_HOME%/bin/jmeter.bat"

rem bin目录（本文件所在目录）
set "bin_dir=%~dp0"
rem MyJMeter根目录
set "base_dir=%bin_dir%/.."
rem 输出目录
set "output_dir=%base_dir%/reports"
rem 类库目录
set "lib_dir=%base_dir%/lib"

rem 自定义JMeter配置文件
set "user_config=%base_dir%/conf/user.properties"

rem ---------------------------------------------------------------------------
rem 运行测试
rem ---------------------------------------------------------------------------

%jmeter% -j "%output_dir%/jmeter-GUI.log" -q "%user_config%" -J "user.classpath=%JMETER_HOME%/lib;%JMETER_HOME%/lib/ext;%lib_dir%;"

rem 参数说明 http://jmeter.apache.org/usermanual/get-started.html#options
