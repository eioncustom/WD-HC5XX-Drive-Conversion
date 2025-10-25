#!/bin/bash
LOGFILE="/var/log/ddn_format.log"
#-- Adjust the MODEL to match your drives.
MODEL="WUH721814AL5204"

echo "[$(date '+%F %T')] Starting WD format check..." | tee -a "$LOGFILE"

# Run wdckit show once, store it for reuse
WDINFO=$(wdckit show)

# Check if any drives match the model
if ! echo "$WDINFO" | grep -q "$MODEL"; then
    echo "[$(date '+%F %T')] ERROR: No drives with model '$MODEL' found. Exiting." | tee -a "$LOGFILE"
    exit 1
fi

# Process each drive from b..d
for i in {b..d}; do
    line=$(echo "$WDINFO" | grep "/dev/sd$i" | grep "$MODEL")
    if [ -n "$line" ]; then
        getsn=$(echo "$line" | awk '{print $8}')
        echo "[$(date '+%F %T')] Serial of drive sd$i: $getsn" | tee -a "$LOGFILE"
        echo "[$(date '+%F %T')] Running wdckit format --serial $getsn -b 4096 --fastformat" | tee -a "$LOGFILE"
        # Uncomment to actually run it:
        # wdckit format --serial "$getsn" -b 4096 --fastformat | tee -a "$LOGFILE"
    else
        echo "[$(date '+%F %T')] Skipping sd$i (model does not match $MODEL)" | tee -a "$LOGFILE"
    fi
done

echo "[$(date '+%F %T')] Completed wdckit format check." | tee -a "$LOGFILE"
