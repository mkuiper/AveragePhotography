#!/bin/bash
# A script to do the average processing of images in workdirectory.

cd /home/pi/Desktop/AveragePhotography/

if [ -f "Timelapse_Config.txt" ]; then
 source "Timelapse_Config.txt"
else 
 echo " Can't see configuration file: Timelapse_Config.txt. Exiting." 
 exit 
fi

#>---------------------------------------------------------------------
cd $WRKDIR 

DATE=`date +%Y-%m-%d`
TIME=`date +%H:%M`
time1=`date +%s`
FILECOUNT=$(find * -type f | wc -l)

echo $(printf "Start of image averaging: $s  $s"  "$DATE" "$TIME") >>logfile.txt
echo "-making daily average image"
imgname=$(printf "%s_%s.jpg" "$LOCATION" "$DATE" )
convert *.jpg -average $imgname

cp $imgname $TOPDIR/Ref_image.jpg
mv $imgname $ARCHIVE
rm *.jpg *.tif

echo $OLDDATE
DATE=`date +%Y%m%d`
OLDDATE=$DATEx

cd $TOPDIR
echo $DATE, $OLDDATE, $d "done"

FINISH=`date +%Y-%m-%d_%H:%M`
time2=`date +%s`
let time3=" $time2 - $time1 "
echo $(printf "Finish of image averaging: $s \n"  "$FINISH") >> logfile.txt 
echo $(printf "Processing time: %s seconds for %s images \n"  "$time3" "$FILECOUNT") >> logfile.txt

