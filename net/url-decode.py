#!/usr/bin/python3

import urllib.parse
import sys


if __name__ == '__main__':
    url = sys.argv[1]
    print(urllib.parse.unquote(url))
