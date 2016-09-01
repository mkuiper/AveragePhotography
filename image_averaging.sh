#!/bin/bash 

#  a script to do the average processing of images in workdirectory.

LOCATION="TestKitchen"

TOPDIR=/$HOME/Desktop/AveragePhotography/
WRKDIR=/$TOPDIR/WorkingDirectory/
ARCHIVE=/$TOPDIR/FrameArchive/

START=`date +%Y-%m-%d_%H:%M`
echo $(printf "Start of image averaging: $s"  $START \n) > logfile.txt 


 cd $WRKDIR
 echo "-making daily average image"
 imgname=$(printf "%s_%s.tif" "$LOCATION" "$OLDDATE" )
 convert *.tif -average $imgname
 
 convert $imgname $TOPDIR/Ref_image.jpg
 mv $imgname $ARCHIVE  
 rm *.tif *.jpg

 echo $OLDDATE
 DATE=`date +%Y%m%d`
 OLDDATE=$DATE

 cd $TOPDIR
 echo $DATE, $OLDDATE, $d "done"

 FINISH=`date +%Y-%m-%d_%H:%M`
 echo $(printf "Finish of image averaging: $s \n"  $FINISH) >> logfile.txt 


