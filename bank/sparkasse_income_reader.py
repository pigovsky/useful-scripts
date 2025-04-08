import csv
import sys


if __name__ == '__main__':
    with open(sys.argv[1], newline='', encoding='latin-1') as csvfile:
        spamreader = csv.DictReader(csvfile, delimiter=';', quotechar='"')
        for row in spamreader:
            value = float(
                row['Betrag']
                    .replace(',', '.')
                    .strip()
            )
            if value > 0:
                print(f'{row['Buchungstag']}  {str(value).ljust(9)}{row['Verwendungszweck']}')
