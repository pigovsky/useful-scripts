#!/bin/bash
# Adds extra digital clocks to the XFCE panel, each showing a different timezone.
# Requires: xfce4-panel (with libclock.so), xfconf-query. Run on the machine's own
# X session (not over plain SSH) so xfce4-panel can be reloaded afterwards.
#
# Usage: ./setup.sh
# Customize the CLOCKS array below to add/remove timezones or change labels.

set -euo pipefail

PANEL_ID="${PANEL_ID:-panel-1}"

# label:timezone pairs (timezone must match a zoneinfo entry, e.g. from `timedatectl list-timezones`)
CLOCKS=(
  "Kyiv:Europe/Kyiv"
  "IST:Asia/Kolkata"
  "Berlin:Europe/Berlin"
)

if ! command -v xfconf-query >/dev/null 2>&1; then
  echo "xfconf-query not found. This script requires XFCE." >&2
  exit 1
fi

# Find the next free plugin id by inspecting existing /plugins/plugin-N entries.
next_plugin_id() {
  local max=0
  while read -r line; do
    id="${line#/plugins/plugin-}"
    id="${id%%/*}"
    if [[ "$id" =~ ^[0-9]+$ ]] && (( id > max )); then
      max=$id
    fi
  done < <(xfconf-query -c xfce4-panel -p /plugins -l 2>/dev/null)
  echo $((max + 1))
}

# Read current plugin-ids array for the panel.
current_ids=()
while read -r line; do
  [[ "$line" =~ ^[0-9]+$ ]] && current_ids+=("$line")
done < <(xfconf-query -c xfce4-panel -p "/panels/${PANEL_ID}/plugin-ids" 2>/dev/null | tail -n +2)

if [ ${#current_ids[@]} -eq 0 ]; then
  echo "Could not read plugin-ids for /panels/${PANEL_ID}. Is the panel name correct?" >&2
  exit 1
fi

new_ids=("${current_ids[@]}")

for entry in "${CLOCKS[@]}"; do
  label="${entry%%:*}"
  tz="${entry#*:}"

  plugin_id=$(next_plugin_id)
  echo "Adding clock plugin-${plugin_id}: ${label} (${tz})"

  xfconf-query -c xfce4-panel -p "/plugins/plugin-${plugin_id}" -n -t string -s "clock"
  xfconf-query -c xfce4-panel -p "/plugins/plugin-${plugin_id}/timezone" -n -t string -s "${tz}"
  xfconf-query -c xfce4-panel -p "/plugins/plugin-${plugin_id}/digital-layout" -n -t int -s 3
  xfconf-query -c xfce4-panel -p "/plugins/plugin-${plugin_id}/digital-format" -n -t string -s "${label} %H:%M"
  xfconf-query -c xfce4-panel -p "/plugins/plugin-${plugin_id}/digital-time-format" -n -t string -s "${label} %H:%M"

  new_ids+=("${plugin_id}")
done

# Rebuild the plugin-ids array with all ids (existing + newly created).
set_args=()
for id in "${new_ids[@]}"; do
  set_args+=(-t int -s "${id}")
done
xfconf-query -c xfce4-panel -p "/panels/${PANEL_ID}/plugin-ids" -n "${set_args[@]}" --create

echo "Reloading xfce4-panel..."
xfce4-panel -r

echo "Done. Added ${#CLOCKS[@]} clock(s) to ${PANEL_ID}."
