#!/bin/bash

# 本文件仅供其他shell脚本source调用，不要加执行权限

# 前提：系统环境变量里必须已设置好JMETER_HOME，值为JMeter所在目录
# 也可以在这里定义：
#JMETER_HOME="/usr/local/jmeter"

# ---------------------------------------------------------------------------
# JVM参数配置
# ---------------------------------------------------------------------------
# 如果被测后台服务是Java（或Scala等基于JVM的语言）写的，推荐把JVM参数设成跟被测程序保持一致
# 注意被测程序在测试环境的JVM参数也要跟线上保持一致

server="-server"
heap="-Xms1024m -Xmx1024m"
use_g1gc="-XX:+UseG1GC"
use_utf8="-Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8"
prefer_ipv4="-Djava.net.preferIPv4Stack=true -Djava.net.preferIPv6Addresses=false"
dump="-XX:+HeapDumpOnOutOfMemoryError"

JVM_ARGS="${server} ${heap} ${use_g1gc} ${prefer_ipv4} ${use_utf8} ${dump}"

# ---------------------------------------------------------------------------
# oh-my-jmeter默认配置
# ---------------------------------------------------------------------------

# JMeter启动脚本
readonly JMETER="${JMETER_HOME}/bin/jmeter"

# oh-my-jmeter家目录（脚本所在目录的上级目录）
[[ "$(dirname "$0")" == "." ]] && readonly BASE_DIR="$(dirname "$(pwd)")" \
    || readonly BASE_DIR="$(dirname "$(dirname "$0")")"
# 配置文件目录
readonly CONFIG_DIR="${BASE_DIR}/conf"
# 测试报告输出目录
readonly REPORT_DIR="${BASE_DIR}/results"
# 库目录
readonly LIB_DIR="${BASE_DIR}/lib"
# 存放用户自己的文件的目录
readonly USER_FILE_DIR="${BASE_DIR}/user-files"

# 测试计划（JMeter脚本）目录
readonly TEST_PLAN_DIR="${USER_FILE_DIR}/testplans"
# 测试计划需要的数据文件目录
readonly DATA_DIR="${USER_FILE_DIR}/data"
# 测试计划需要的外部脚本文件目录
readonly SCRIPT_DIR="${USER_FILE_DIR}/scripts"

# JMeter用户配置文件
readonly user_config="${CONFIG_DIR}/user.properties"

# JMeter监听器配置文件
# oh-my-jmeter默认，适合大多数情况
readonly listener_config_default="${CONFIG_DIR}/listeners.properties"
# 仅记录最少必要的字段，注意：无法利用JMeter自带的生成HTML报告的功能
readonly listener_config_min="${CONFIG_DIR}/listeners-min.properties"
# 记录所有字段，调试用
readonly listener_config_debug="${CONFIG_DIR}/listeners-debug.properties"
# 测试记录保存为XML格式，可以记录请求和返回内容，只适用于接口功能测试
readonly listener_config_functional="${CONFIG_DIR}/functional_test/listeners-xml.properties"

# 查找jar包的路径
readonly user_classpath="-Juser.classpath=${LIB_DIR}/ext:${LIB_DIR}:${JMETER_HOME}/lib/ext:${JMETER_HOME}/lib"
readonly search_paths="-Jsearch_paths=${LIB_DIR}/ext"

# 测试计划需要引用外部JMeter脚本文件（.jmx）的默认路径
readonly include_controller_prefix="-Jincludecontroller.prefix=${TEST_PLAN_DIR}/"
# 指定的路径必须用 / 结尾，因为测试计划里都写相对路径（开头什么也不加）
# http://jmeter.apache.org/usermanual/component_reference.html#Include_Controller
# http://jmeter.apache.org/usermanual/properties_reference.html#include_controller

JMETER_PROPS="-q ${user_config} ${user_classpath} ${search_paths} ${include_controller_prefix}"

# ---------------------------------------------------------------------------
# JMeter运行设置
# ---------------------------------------------------------------------------
# JMeter命令行参数说明 http://jmeter.apache.org/usermanual/get-started.html#options

# oh-my-jmeter初始化配置
# 有参数按命令行运行配置，无参数按GUI运行配置
function omj_init() {
    local test_plan_file="$1"
    local listener_config="$2"

    if [[ -n "${test_plan_file}" ]]; then  # 命令行
        # 不带后缀的测试计划文件名
        local test_name="$(basename "${test_plan_file}" | cut -d "." -f 1)"
        local start_time="$(date +%Y%m%d_%H%M%S)"

        # 监听器和报告设置
        case "${listener_config}" in
            min)
                local log_format="csv"
                OUTPUT_DIR="${REPORT_DIR}/${test_name}__min_${start_time}"
                LISTENER_CONFIG="-q ${listener_config_min}"
                ;;
            debug)
                local log_format="csv"
                OUTPUT_DIR="${REPORT_DIR}/${test_name}__debug_${start_time}"
                # 在测试运行完后生成HTML报告，目录必须不存在或为空，由JMeter创建
                LISTENER_CONFIG="-q ${listener_config_debug} -e -o ${OUTPUT_DIR}/dashboard"
                ;;
            functional)
                local log_format="xml"
                OUTPUT_DIR="${REPORT_DIR}/${test_name}__functional_${start_time}"
                LISTENER_CONFIG="-q ${listener_config_functional}"
                ;;
            *)
                local log_format="csv"
                OUTPUT_DIR="${REPORT_DIR}/${test_name}_${start_time}"
                # 在测试运行完后生成HTML报告，目录必须不存在或为空，由JMeter创建
                LISTENER_CONFIG="-q ${listener_config_default} -e -o ${OUTPUT_DIR}/dashboard"
        esac

        # 创建输出目录
        mkdir "${OUTPUT_DIR}" || OUTPUT_DIR="${REPORT_DIR}"

        # JMeter测试记录文件
        local result_log="${OUTPUT_DIR}/result.${log_format}"
        # JMeter日志文件
        local jmeter_log="${OUTPUT_DIR}/jmeter.log"

        LOG_CONFIG="-j ${jmeter_log} -l ${result_log} ${summariser_log}"
    else  # GUI
        local OUTPUT_DIR="${REPORT_DIR}"
        LOG_CONFIG="-j ${OUTPUT_DIR}/jmeter-gui.log"
    fi

    OMJ_PROPS="-Jomj.testplanDir=${TEST_PLAN_DIR} \
        -Jomj.dataDir=${DATA_DIR} \
        -Jomj.scriptDir=${SCRIPT_DIR} \
        -Jomj.libDir=${LIB_DIR} \
        -Jomj.reportDir=${OUTPUT_DIR} \
        -Jomj.baseDir=${BASE_DIR}"
}

# 命令行模式运行JMeter测试
function run_in_commandline() {
    local test_plan_file="$1"
    local listener_config="$2"

    if [[ -f "${test_plan_file}" ]]; then
        omj_init "${test_plan_file}" "${listener_config}"

        JVM_ARGS="${JVM_ARGS}" "${JMETER}" -n -t "${test_plan_file}" \
            ${LISTENER_CONFIG} ${LOG_CONFIG} ${JMETER_PROPS} ${OMJ_PROPS} \
            | tee -a "${OUTPUT_DIR}/summary.log"

        echo
        echo "[INFO] See logs and reports at: ${OUTPUT_DIR}"
    else
        echo "[ERROR] Cannot find test plan file: ${test_plan_file}" >&2
        exit 1
    fi
}

# GUI模式运行JMeter
function run_in_gui() {
    omj_init
    pushd "${TEST_PLAN_DIR}" > /dev/null

    JVM_ARGS="${JVM_ARGS}" "${JMETER}" ${LOG_CONFIG} ${JMETER_PROPS} ${OMJ_PROPS}

    popd
}

function start_server() {
    JVM_ARGS="${JVM_ARGS}" "${JMETER}" ${LOG_CONFIG} ${JMETER_PROPS} ${OMJ_PROPS}
}
