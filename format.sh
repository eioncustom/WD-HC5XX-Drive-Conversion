#!/bin/bash
##This script requires the end user to provide the "WDCKIT" from Western Digital (WD)
##WDCKIT can be found by opening a Technical Support request with WD. This requires a drive under warranty.
##The end user can also find this toolkit from numerous sources.

#---This is written using Ubuntu 22.04 LTS and a HPE DL360 to allow serial formatting of the data tables. 
#Adjust the '{b..d}' to adjust for your specific system layout. This is highly portable between numerous systems.

for DRIVE in  {b..d};do
getsn=$(wdckit show /dev/sd$DRIVE | grep dev | awk '{print $8}')

echo "Serial of drive sd$DRIVE: $getsn"

echo "Running wdckit format --serial $getsn -b 4096 --fastformat"
#--- I suggest commenting out the line below until you test and see the output from the echo above to ensure the commands are forming correctly.
wdckit format --serial $getsn -b 4096 --fastformat
done
