import csv
import sys


if len(sys.argv) < 2 or sys.argv[1] == '':
    print('[ERROR] You must specify a log file! (default: results/<your_folder>/result.csv)')
    print('Usage: ' + sys.argv[0] + ' <result_log_file>')
    sys.exit(1)

logfile = sys.argv[1]

with open(logfile) as csvfile:
    reader = csv.DictReader(csvfile)
    for line in csvfile:
        pass