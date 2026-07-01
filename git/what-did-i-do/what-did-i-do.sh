#!/usr/bin/env bash
# Usage: what-did-i-do.sh [YYYY-MM]
# Defaults to the current month if no argument is given.

set -euo pipefail

ROOT_DIR="$(pwd)"

MONTH="${1:-$(date +%Y-%m)}"

# Validate format
if ! [[ "$MONTH" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
  echo "Usage: $0 [YYYY-MM]" >&2
  exit 1
fi

YEAR="${MONTH%-*}"
MON="${MONTH#*-}"
AFTER="${YEAR}-${MON}-01"
# Last day of month
BEFORE=$(date -d "${AFTER} +1 month" +%Y-%m-%d 2>/dev/null \
         || python3 -c "import datetime; d=datetime.date(int('$YEAR'),int('$MON'),1); import calendar; print(d.replace(day=calendar.monthrange(d.year,d.month)[1]) + datetime.timedelta(days=1))")

RESULTS=()

for dir in "$ROOT_DIR"/*/; do
  [ -d "$dir/.git" ] || continue
  repo=$(basename "$dir")
  while IFS=$'\t' read -r dt author msg; do
    RESULTS+=("$dt"$'\t'"$repo"$'\t'"$author"$'\t'"$msg")
  done < <(git -C "$dir" log \
    --after="${AFTER}" \
    --before="${BEFORE}" \
    --author="pigovsky" \
    --format="%ai%x09%an%x09%s" \
    2>/dev/null)
done

if [ ${#RESULTS[@]} -eq 0 ]; then
  echo "No commits found for $MONTH."
  exit 0
fi

# Sort by date (first field) and print
printf '%s\n' "${RESULTS[@]}" | sort | awk -F'\t' '{printf "%s, %s, %s, %s\n", $1, $2, $4, $3}'
