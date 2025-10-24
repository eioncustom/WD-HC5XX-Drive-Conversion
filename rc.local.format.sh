#!/bin/bash

#-- Logging location can be set to whereever you would like.
LOGFILE="/var/log/ddn_format.log"
SHUTDOWN_FLAG=0

echo "[$(date '+%F %T')] Starting WUH drive format check..." | tee -a "$LOGFILE"

# Cache wdckit show once
WDINFO=$(wdckit show 2>/dev/null)
WUH_DRIVES=$(echo "$WDINFO" | awk '/WUH/ {print $2}')

#--- Adjust the "WUH" to the beginning three drive model letters that your specific drive may have. 
#--- WUH was selected here as all the WD HC530, HC540, & HC550 drives share this lettering.

if [ -z "$WUH_DRIVES" ]; then
    echo "[$(date '+%F %T')] ERROR: No drives found with model starting with 'WUH'." | tee -a "$LOGFILE"
    echo "[$(date '+%F %T')] Exiting without shutdown." | tee -a "$LOGFILE"
    exit 0
fi

for dev in $WUH_DRIVES; do
    echo "[$(date '+%F %T')] Checking $dev..." | tee -a "$LOGFILE"

    GEOMETRY=$(wdckit show "$dev" --geometry 2>/dev/null)
    if [ -z "$GEOMETRY" ]; then
        echo "[$(date '+%F %T')] WARNING: No geometry info for $dev." | tee -a "$LOGFILE"
        continue
    fi

    BLOCK_SIZE=$(echo "$GEOMETRY" | awk -v dev="$dev" '$1 == dev {print $2}' | grep -o '[0-9]\+')

    if [ -z "$BLOCK_SIZE" ]; then
        echo "[$(date '+%F %T')] WARNING: Could not determine Block Size for $dev." | tee -a "$LOGFILE"
        echo "---- geometry dump for $dev ----" | tee -a "$LOGFILE"
        echo "$GEOMETRY" | sed 's/^/    /' | tee -a "$LOGFILE"
        echo "--------------------------------" | tee -a "$LOGFILE"
        continue
    fi

    echo "[$(date '+%F %T')] Block Size for $dev: $BLOCK_SIZE Bytes" | tee -a "$LOGFILE"

    #-- Only format if Block Size == 512
    if [ "$BLOCK_SIZE" -ne 512 ]; then
        echo "[$(date '+%F %T')] Skipping $dev (Block Size != 512)." | tee -a "$LOGFILE"
        continue
    fi

    SERIAL=$(echo "$WDINFO" | grep "$dev" | awk '{print $8}')
    if [ -z "$SERIAL" ]; then
        echo "[$(date '+%F %T')] ERROR: Could not find serial for $dev." | tee -a "$LOGFILE"
        continue
    fi

    echo "[$(date '+%F %T')] Formatting $dev (Serial: $SERIAL)..." | tee -a "$LOGFILE"
    echo "[$(date '+%F %T')] Running: wdckit format --serial $SERIAL -b 4096 --fastformat" | tee -a "$LOGFILE"

    #-- Comment/Uncomment this to actually perform/not perform the format:
    wdckit format --serial "$SERIAL" -b 4096 --fastformat | tee -a "$LOGFILE"

    #-- Mark that we formatted at least one drive
    SHUTDOWN_FLAG=1
done

# Decision: shutdown or not
if [ "$SHUTDOWN_FLAG" -eq 1 ]; then
    echo "[$(date '+%F %T')] Formatting completed on one or more drives. Shutting down system..." | tee -a "$LOGFILE"
    shutdown -h now
else
    echo "[$(date '+%F %T')] No 512-byte WUH drives found. System will not shut down." | tee -a "$LOGFILE"
fi

echo "[$(date '+%F %T')] Completed WUH drive format check." | tee -a "$LOGFILE"
