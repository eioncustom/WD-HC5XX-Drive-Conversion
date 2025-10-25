# Western Digital (WD) HC5XX 512e Drive Conversion to 4Kn for Utilization in DDN EXASCALER Appliances

# TOC
[Automation Scripts](#automating-and-performing-changes-to-multiple-drives)  
[hdparm Peculiarities](#hdparm-peculiarities)  
> I wrote all these scripts to automate the re-shaping of the drive sectors from 512e to 4Kn.

<ins>***This WILL NOT work on 512n drives and WD is very clear about this in their documentation.***</ins>

## Background / My Story  
I support several HPC Cluster that utilize LustreFS as our hot storage. Over the years, we finally had Data Direct Networks (DDN, Inc.) Exascaler appliance that were no long part of a support contract. Of course it was a matter of time before we had spinning disc drive failures.  

I reached out DDN for a quote for replacement drives and wasn't super happy with the prices. They do come with the drive carriers, but since I may have to move the appliances from one location to another at some point, I have always swapped the drive carrier anyways. Mark me, *not sold*. I still do recommend getting the drives from DDN as they do some with validated firmware that is guarenteed to work with your appliace. This process is my work around for budget constraints.

Instead of purchasing from DDN I went out shopping and found a good price on a case of 14TiB WD HC550 drives, the appliance was shipped with WD HC530 14TiB 4Kn drives. The assumption is that the HC550s should function the same as the HC530 drives. Upon arrival of the case of drives, WD in their infinite wisdom shipped all the drives with the geometry set to 512Kn.  

The adventure started with hdparm and a handful of other formatting tools, NONE of them worked to shape the drive the way that the DDN Appliance was looking for.  

### HUGO and wdckit have entered the chat...

After I had already opened a support case with Western Digital, they told me they their response SLA was 2 days. To heck with that... I did lots of forum hunting and came across HUGO. HUGO is an older disk manager from WD, this ended up being a dead end. It worked fine for some older drives like the HC520, but not the HC550. That is when I came across [this](https://support-en.wd.com/app/answers/detailweb/a_id/50708/~/wdckit-drive-utility-download-and-instructions-for-internal-drives) documentation about wdckit. This is the utility that you will need to reshape the geometry of these HC550 drives.  

There is two ways to get wdckit:
1) From Western Digital, **(Disaclamer: NO COMMAND SUPPORT FROM TECHNICAL SUPPORT)**
   > Western Digital provided me with v3.2.0.0 [Linux](https://downloads.wdc.com/wdapp/wdckit_lin.zip) & [Windows](https://downloads.wdc.com/wdapp/wdckit_win.zip)
3) From storage nerds like myself that crowd source utilities like [HDD Gurus](https://files.hddguru.com/download/Software/Western%20Digital/)

Now with utility. drives, and a spare server with a SAS Contoller in it... It was time to figure out this utility and test in the DDN Appliance once complete.

WDCKIT has lots of useful commands to tinker with your drives, be careful as there are many commands that can break your drive.  
-->  **USE AT YOUR OWN RISK**  <--


For these HC5xx drives you don't need much. If you want to do this manually, you will need to:
1) Install the correct package for your OS, I am using Ubuntu 22.04 LTS at this point and all the scripts are written around BASH. Powershell peeps, you're on your own. (But the wdckit command should be the same)
2) Once installed you can check the drives in your machine with ```wdckit show```

```CLI
root@ddn-converter:/home/user# wdckit show
wdckit Version 3.2.0.0 [x86_64 build]
Copyright (C) 2019-2025 Western Digital Technologies, Inc.
Western Digital ATA/SCSI command line utility.
10/24/2025 21:23:13.395

DUT  Device    Port  Capacity       State          BootDevice  Serial Number         Model Number     Firmware  Lnk Spd Cap/Cur
---  --------  ----  -------------  -------------  ----------  --------------------  ---------------  --------  ---------------------------
0    /dev/sda  SAS   2.00 TB        Good           Yes         Z1X1MMC00000C425CL55  MB2000FCWDF      HPD5      Gen3,Gen3/Gen3,unknown
1    /dev/sdb  SAS   14.0 TB        Good           No          6JG467AT              WUH721814AL5204  C8C2      Gen4,Gen4/Gen4,unknown
2    /dev/sdc  SAS   14.0 TB        Good           No          6JG4DWUT              WUH721814AL5204  C8C2      Gen4,Gen4/Gen4,unknown
3    /dev/sdd  SAS   14.0 TB        Good           No          6JG4DXET              WUH721814AL5204  C8C2      Gen4,Gen4/Gen4,unknown
4    /dev/sde  SCSI  unretrievable  unretrievable  No                                LUN 00 Media 0   2.10      unretrievable/unretrievable
5    /dev/sg0  SCSI  unretrievable  unretrievable  No          PDNLH0BRH8W4S8        P440ar           7.00      unretrievable/unretrievable
6    /dev/sg5  SCSI  unretrievable  unretrievable  No          PDNLH0BRH8W4S8        P440ar           7.00      unretrievable/unretrievable
```
> Here we can see all the drive and the Device IDs, we will need the Device ID and the Serial Numbers of the drive(s) you wish to modify.

4) To check the current geometry of a specfic drive, run ```wdckit show --geometry```  

```CLI
root@ddn-converter:/home/user# wdckit show --geometry
wdckit Version 3.2.0.0 [x86_64 build]
Copyright (C) 2019-2025 Western Digital Technologies, Inc.
Western Digital ATA/SCSI command line utility.
10/24/2025 21:26:54.229

Device    Block Size     Max LBA        Size           Boot Device
--------  -------------  -------------  -------------  -----------
/dev/sda  512 Bytes      3907029167     2.00 TB        Yes
/dev/sdb  512 Bytes      27344764927    14.0 TB        No
/dev/sdc  512 Bytes      27344764927    14.0 TB        No
/dev/sdd  512 Bytes      27344764927    14.0 TB        No
/dev/sde  unretrievable  unretrievable  unretrievable  No
/dev/sg0  unretrievable  unretrievable  unretrievable  No
/dev/sg5  unretrievable  unretrievable  unretrievable  No
```  
> Observe in the verison of wdckit I am using the relevate information is found in the second coloumn. 

6) Time to format, you will need to run this command; ```wdckit format --serial SERIAL -b 4096 --fastformat```
```CLI
root@ddn-converter:/home/user# wdckit format --serial 6JG4DWUT -b 4096 --fastformat
wdckit Version 3.2.0.0 [x86_64 build]
Copyright (C) 2019-2025 Western Digital Technologies, Inc.
Western Digital ATA/SCSI command line utility.
10/24/2025 21:32:31.663

Drives with changed capacities:
Serial Number  Old Capacity                 New Capacity
-------------  ---------------------------  ---------------------------
6JG4DWUT       14.0 TB (512 x 27344764927)  14.0 TB (4096 x 3418095615)

The format command will result in loss of data on the specified device.

Are you sure you want to format these devices?

Do you want to continue (Y/N)? y

Format on 1 device(s) started...
Progress: 0%
Progress: 100%
Success: Format completed on: 6JG4DWUT
/dev/sdc: Success
```
> Depending on the size of your drive this can take minutes to complete.

8) Now you can verify the drive(s) that you selected have been reshaped.
```
root@ddn-converter:/home/user# wdckit show --geometry
wdckit Version 3.2.0.0 [x86_64 build]
Copyright (C) 2019-2025 Western Digital Technologies, Inc.
Western Digital ATA/SCSI command line utility.
10/24/2025 21:34:13.064

Device    Block Size     Max LBA        Size           Boot Device
--------  -------------  -------------  -------------  -----------
/dev/sda  512 Bytes      3907029167     2.00 TB        Yes
/dev/sdb  512 Bytes      27344764927    14.0 TB        No
/dev/sdc  4096 Bytes     3418095615     14.0 TB        No
/dev/sdd  512 Bytes      27344764927    14.0 TB        No
/dev/sde  unretrievable  unretrievable  unretrievable  No
/dev/sg0  unretrievable  unretrievable  unretrievable  No
/dev/sg5  unretrievable  unretrievable  unretrievable  No
```
> As you can see I have done one drive and it showing the correct geometry for a 4Kn drive.

9) Now you can place this drive in your DDN Appliance and format the drive from there to match the rest of the drives in that storage pool.
    *If you're not putting this in a DDN Appliance, you're just ready to create the file system on top that you would like.*

# Automating and Performing Changes to Multiple Drives  

I have spent some time building out a few scripts that can help make your life much easier when needing to do multiple drives in a machine.

1) [Manually Triggered Bash Script to Cycle through Dev Letters](https://github.com/eioncustom/WD-HC5XX-Drive-Conversion/blob/2dfba079d5a1b863251e877afb026381aa9e20fb/format.sh)
2) [Manually Triggered Bash Script to Find all Specific Drives of a Given Model w/logging](https://github.com/eioncustom/WD-HC5XX-Drive-Conversion/blob/2dfba079d5a1b863251e877afb026381aa9e20fb/loop_with_log.sh)
3) [Automated to sit in rc.local](https://github.com/eioncustom/WD-HC5XX-Drive-Conversion/blob/2012d2032cca1c8be8f04f9ccd03f2693adab053/rc.local.format.sh)

# hdparm Peculiarities
During all my research in to these drives, I was checking on them with ``hdparm``. There is a really good write up about it on [Arch Linux's Wiki](https://wiki.archlinux.org/title/Advanced_Format#Advanced_Format_hard_disk_drives).  

When I was checking them pre-change, it was reporting 512, and not showing the additiional modes as noted in Arch's Wiki. The logical size is always 512, never changing. Even post configuration change with wdckit hdparm 
```CLI
root@ddn-converter:/home/user# hdparm -I /dev/sdb

/dev/sdb:

ATA device, with non-removable media
Standards:
        Likely used: 1
Configuration:
        Logical         max     current
        cylinders       0       0
        heads           0       0
        sectors/track   0       0
        --
        **Logical/Physical Sector size:           512 bytes**
        device size with M = 1024*1024:           0 MBytes
        device size with M = 1000*1000:           0 MBytes
        cache/buffer size  = unknown
Capabilities:
        IORDY not likely
        Cannot perform double-word IO
        R/W multiple sector transfer: not supported
        DMA: not supported
        PIO: pio0

root@ddn-converter:/home/user# wdckit show --geometry /dev/sdb
wdckit Version 3.2.0.0 [x86_64 build]
Copyright (C) 2019-2025 Western Digital Technologies, Inc.
Western Digital ATA/SCSI command line utility.
10/24/2025 22:33:07.848

Device    Block Size  Max LBA     Size     Boot Device
--------  ----------  ----------  -------  -----------
/dev/sdb  4096 Bytes  3418095615  14.0 TB  No
```
> The data for these drives can not be trusted from hdparm
  
When the drive is placed in to a DDN Appliance it is read correctly and reports a 4Kn allowing you to finally format the drive to your correct file system.  

```CLUI
****************************
*     Physical Disk(s)     *
****************************


Enclosure|                                       |S|                                                  |Health |                              |Block|
Idx |Pos |Slot| Vendor |     Product ID     |Type|E|Capacity  | RPM|Revision|    Serial Number   |Pool| State | Idx |State |       WWN       |Size |
----------------------------------------------------------------------------------------------------------------------------------------------------
   3    3   63 WDC      WUH721814AL5204       SAS          0 B 7.2K C8C2     6JG4H34T             UNAS FRMTING    73 READY   5000cca40e0828b0   4k 
----------------------------------------------------------------------------------------------------------------------------------------------------
    |  NUM| Vendor |     Product ID     |Type|Capacity  | RPM|Revision|Block Size|
----------------------------------------------------------------------------------------------------------------------------------------------------
Found:   1 WDC      WUH721814AL5204       SAS        0 B 7.2K C8C2     4k  

Number of distinguished models:  1

Total Physical Disks:                          1
Total Assigned Disks:                          0
Total Unassigned Disks:                        1
  Total SAS Disks:                             1
```


