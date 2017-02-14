# coding=utf-8

import re
import sys
import time
from datetime import datetime, timedelta

import matplotlib.pyplot as plt

# 发送请求数
request_counts = []
# 测试运行时间
durations = []
# 吞吐率（每秒请求数）
throughputs = []
# 平均响应时间
average_times = []
# 最小响应时间
min_times = []
# 最大响应时间
max_times = []
# 请求错误次数
error_counts = []


# 提取时间戳
def extract_timestamp(text):
    matcher = re.match(r'^.*\((\d+?)\)$', text)
    if matcher:
        return int(matcher.group(1))


# 时间戳转格式
def convert_timestamp_format(timestamp, time_format='%Y-%m-%d %H:%M:%S'):
    if timestamp is None:
        return ''
    length = len(str(timestamp))
    if length == 13:
        return datetime.fromtimestamp(timestamp / 1000.0).strftime(time_format)


# 检查参数
if len(sys.argv) < 2 or sys.argv[1] == '':
    print('[ERROR] You must specify a log file! (default: results/<your_folder>/summary.log)')
    print('Usage: ' + sys.argv[0] + ' <summary_log_file>')
    sys.exit(1)

# 解析文件
logfile = sys.argv[1]
with open(logfile) as f:
    start_time = None
    end_time = None
    for line in f:
        # 例：Starting the test @ Mon Feb 13 15:08:52 CST 2017 (1486969732322)
        if line.startswith('Starting the test'):
            start_time = extract_timestamp(line)

        # 例：summary =  13837 in 00:01:38 =  140.7/s Avg:   557 Min:     5 Max: 70233 Err:     0 (0.00%)
        if line.startswith('summary ='):
            columns = re.split(r'\s+', line)
            # 从0开始数
            request_counts.append(int(columns[2]))
            durations.append(columns[4])
            throughputs.append(float(columns[6][:-2]))
            average_times.append(int(columns[8]))
            min_times.append(int(columns[10]))
            max_times.append(int(columns[12]))
            error_counts.append(int(columns[14]))

        # 例：Tidying up ...    @ Mon Feb 13 15:10:31 CST 2017 (1486969831510)
        if line.startswith('Tidying up'):
            end_time = extract_timestamp(line)

# 字符串时间转秒数
durations_in_second = []
for duration in durations:
    t = time.strptime(duration, '%H:%M:%S')
    to_seconds = timedelta(hours=t.tm_hour, minutes=t.tm_min, seconds=t.tm_sec).total_seconds()

    durations_in_second.append(to_seconds)

# 生成图表
plt.figure()

# 画曲线，点的x坐标, y坐标
plt.plot(durations_in_second, average_times, 'ro--', label='Avg. Response Time (ms)')
plt.plot(durations_in_second, throughputs, 'gs--', label='Throughput (request/s)')
plt.plot(durations_in_second, min_times, 'b^--', label='Min Response time (ms)')
# plt.plot(durations_in_second, max_times, 'r^--', label='Max Response time (ms)')
# plt.plot(durations_in_second, request_counts, 'go--', label='Request Count')
plt.plot(durations_in_second, error_counts, 'bs--', label='Error Count')

# 坐标轴范围，'auto' 或 xmin, xmax, ymin, ymax
plt.axis('auto')

# x轴标签加上开始结束时间和时长说明
str_start_time = convert_timestamp_format(start_time)
str_end_time = convert_timestamp_format(end_time)
if str_start_time != '' and str_end_time != '':
    m, s = divmod(int((end_time - start_time) / 1000), 60)
    h, m = divmod(m, 60)
    # x轴标签
    plt.xlabel('Test Duration in Seconds ({} - {}, {} h {} min {} s)'.format(str_start_time, str_end_time, h, m, s))

# 图表标题
plt.title('JMeter Test Report')
# 显示图例说明
plt.legend(loc='best')
# 显示
plt.show()
