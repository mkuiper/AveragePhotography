## AveragePhotography                        Feb 2018

This project is designed to run averaged timelapse photography
on a Raspberry pi with either a picam module or webcam.  

Regular timelapse usually strings together a series of sequential 
images to make a movie. Averaged timelapse photography differs by
averaging a series of images which are then used to make the 
timelapse movie. With the additional averaging step, many moving
objects such as cars and pedestrians disappear from the scene. 

There are a number of bash scripts in this directory whcih control 
the capturing of the timelapse sequence. They are designed to be
run using a crontab so that they automatically launch at various 
times of the day. 

./start_timelapse.sh   starts the timelapse
./stop_timelapse.sh    stops the timelapse
./image_averaging.sh   daily processesing of averaged images

Timelapse_Config.txt   contains parameters for running timelapse
TimelapseFunctions.sh  bash script containing timelapse functions

last_mesg.txt          contains last step message
log_file.txt           contains logs of timelapses sequence


The timelapse works by capturing a number of images for HDR 
(high dynamic range) photography, which typically blends the 
best exposed parts of over and under exposed images. 
The HDR images are then saved to "current_hdr_image.tif"
which is then in turn proportionally blended with 
"working _average_image.tif"  

At the end of the day, the "working_average_image.tif" is 
processed and saved in the FrameArchive folder. It is also 
proportially blended with the 7 and 30 day running average 
which are also saved in their respective folders. 





