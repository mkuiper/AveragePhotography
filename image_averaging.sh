#!/bin/bash
# A script to do the average processing of images in the working directory.

if [ -f "Timelapse_Config.txt" ]; then
 source "Timelapse_Config.txt"
else 
 echo " Can't see configuration file: Timelapse_Config.txt. Exiting." 
exit 
fi

#>---------------------------------------------------------------------

DATE=`date +%Y-%m-%d`
TIME=`date +%H:%M`
time1=`date +%s`

echo $(printf "Start image averaging: %s  %s"  "$DATE" "$TIME") >>logfile.txt
echo "-making daily average image"

#>---------------------------------------------------------------------
# Option to turn of HDMI to save power. 
if [ "$HDMI" == true ]; then
 tvservice -o
fi


cd $WRKDIR


# make a list of file names
fileArg=(`ls`)
num=${#fileArg[*]}
convert ${fileArg[0]} tmp.mpc
echo "${fileArg[0]}"

# make a composite image of sequential frames
# (taken from www.imagemaagick.org/discorse-server/viewtopic.php?t=21279)
i=1
while [ $i -lt $num ]; do
j=$((i+1))
new=`convert xc: -format "%[fx:100/$j]" info:`
old=`convert xc: -format "%[fx:100-$new]" info:`
composite -blend $old%x$new% tmp.mpc ${fileArg[$i]} tmp.mpc
echo "${fileArg[$i]}"
i=$((i+1))
done

AVEIMG=$(printf "%s_%s.jpg" "$LOCATION" "$DATE" )
convert tmp.mpc -quality 100 $AVEIMG

cp $AVEIMG $TOPDIR/Ref_image.jpg
cp $AVEIMG $ARCHIVE

rm tmp.mpc tmp.cache
rm *.jpg

cd $TOPDIR
FINISH=`date +%Y-%m-%d_%H:%M`
time2=`date +%s`
let time3=" $time2 - $time1 "

echo $(printf "Processing time: %s seconds for %s images \n"  "$time3" "$num") >> logfile.txt

