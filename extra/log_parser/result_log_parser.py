# coding=utf-8

import csv
import sys
from enum import Enum
import pymongo

if len(sys.argv) < 2 or sys.argv[1] == '':
    print('[ERROR] You must specify a log file!')
    print('Usage: ' + sys.argv[0] + ' <result_log_file>')
    sys.exit(1)

RESULT_LOG_FILE = sys.argv[1]
REQUEST_STATS = {

}
TEST_SUMMARY = {
    'request_count': 0,
    'received_bytes': 0,
    'sent_bytes': 0
}

class TestSummary:
    pass


class Fields(Enum):
    TIMESTAMP = 'timeStamp'
    ELAPSED = 'elapsed'
    LABEL = 'label'
    RESPONSE_CODE = 'responseCode'
    RESPONSE_MESSAGE = 'responseMessage'
    THREAD_NAME = 'threadName'
    DATA_TYPE = 'dataType'
    SUCCESS = 'success'
    FAILURE_MESSAGE = 'failureMessage'
    BYTES = 'bytes'
    SENT_BYTES = 'sentBytes'
    GROUP_THREADS = 'grpThreads'
    ALL_THREADS = 'allThreads'
    URL = 'URL'
    FILENAME = 'Filename'
    LATENCY = 'Latency'
    ENCODING = 'Encoding'
    SAMPLE_COUNT = 'SampleCount'
    ERROR_COUNT = 'ErrorCount'
    HOSTNAME = 'Hostname'
    IDLE_TIME = 'IdleTime'
    CONNECT_TIME = 'Connect'


with open(RESULT_LOG_FILE) as csvfile:
    reader = csv.DictReader(csvfile)
    fieldnames = reader.fieldnames

    for line in reader:
        if Fields.THREAD_NAME in fieldnames:
            print('haha')
            print(line[Fields.THREAD_NAME])
            pass
        if Fields.LABEL in fieldnames:
            print('hehe')
            pass
        TEST_SUMMARY['request_count'] += 1
        pass
