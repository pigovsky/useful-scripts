#!/bin/bash

git log --pretty=format:"%ad | %an | %s" --date=short "$@"
