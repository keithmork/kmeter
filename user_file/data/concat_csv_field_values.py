import csv
import sys

if len(sys.argv) < 3:
    print('Usage: {} CSV_FILE COL_NAME [ITEMS_PER_LINE=10] [MAX_LINES=1000]'.format(sys.argv[0]))
    sys.exit(1)

CSV_FILE = sys.argv[1]
COL_NAME = sys.argv[2]
NEW_COL_NAME = sys.argv[3] if len(sys.argv) >= 4 else COL_NAME + 's'
ITEMS_PER_LINE = int(sys.argv[3]) if len(sys.argv) >= 4 else 10
MAX_LINES = int(sys.argv[4]) if len(sys.argv) >= 5 else 1000

lines_in_new_file = []
with open(CSV_FILE, encoding='utf-8') as handle:
    reader = csv.DictReader(handle)
    if COL_NAME not in reader.fieldnames:
        print('[ERROR] Cannot find {} in {}'.format(COL_NAME, CSV_FILE))
        sys.exit(1)

    new_lines_count = 0
    new_line_content = {NEW_COL_NAME: []}
    items_per_line_count = 0

    for line in reader:
        if new_lines_count < MAX_LINES:
            item = line[COL_NAME]
            items = new_line_content[NEW_COL_NAME]

            if items_per_line_count < ITEMS_PER_LINE:
                items.append(item)
                items_per_line_count += 1
            else:
                new_line_content.update({NEW_COL_NAME: ','.join(str(element) for element in items)})
                lines_in_new_file.append(new_line_content)
                new_lines_count += 1
                print(new_line_content)

                del items
                new_line_content = {NEW_COL_NAME: [item]}
                items_per_line_count = 1

with open(NEW_COL_NAME + '.csv', 'w', encoding='utf-8') as handle:
    writer = csv.DictWriter(handle, fieldnames=[NEW_COL_NAME])
    writer.writeheader()
    for line in lines_in_new_file:
        writer.writerow(line)
