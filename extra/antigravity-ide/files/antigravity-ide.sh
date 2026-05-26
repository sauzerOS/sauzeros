#!/bin/bash

readonly UNIT_NAME="antigravity-ide-$(date +%s)"

systemd-run --user \
  --scope \
  --unit="$UNIT_NAME" \
  --property=KillMode=mixed \
  --property=TimeoutStopSec=2 \
  /opt/Antigravity/antigravity-ide --disable-crash-reporter
