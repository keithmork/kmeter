# coding=utf-8

import csv
import sys
import json


def generate_json_array(csv_file, field_name, count=10):
    json_array = []
    with open(csv_file, encoding='utf-8') as f:

        reader = csv.DictReader(f)
        for line in reader:
            if reader.line_num - 1 > count:
                break
            if line.get(field_name):
                json_array.append(line[field_name])

    return json.dumps(json_array, ensure_ascii=False)


if __name__ == '__main__':
    CSV_FILE = sys.argv[1]
    FIELD_NAME = sys.argv[2]
    COUNT = int(sys.argv[3]) if len(sys.argv) > 3 else 10

    print(generate_json_array(CSV_FILE, FIELD_NAME, COUNT))
