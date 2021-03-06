#!/bin/bash
# A simple script to configure and install useful programs 
# on the Raspberry pi for Average photography

sudo apt-get update
sudo apt-get -y upgrade

# Useful image processing/viewing software
sudo apt-get install -y imagemagick
sudo apt-get install -y enfuse
sudo apt-get install -y eog 
sudo apt-get install -y gphoto2
sudo apt-get install -y vim
sudo apt-get install -y fswebcam

# User friendly scheduler and network manager
sudo apt-get install -y network-manager
sudo apt-get install -y gnome-schedule

sudo apt-get install -y ssmtp
sudo apt-get install -y mpack

# Increase swapsize
sudo sed -i 's/.*CONF_SWAPSIZE=.*/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile
sudo /etc/init.d/dphys-swapfile stop
sudo /etc/init.d/dphys-swapfile start

# Edit the /boot/config.txt to enable camera.
sudo cp  /boot/config.txt /boot/config.txt.bup
sudo sed -i 's/.*start_x=.*/start_x=1/' /boot/config.txt

echo " ToDo checklist:" 
echo " -make sure to check the date and time."
echo " -setup email settings  /etc/stmp/stmp.conf."
