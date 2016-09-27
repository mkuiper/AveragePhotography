#!/bin/bash
# A simple script to install some useful programs on the Raspberry pi for Average photography


sudo apt-get update
sudo apt-get -y upgrade

sudo apt-get install -y imagemagick
sudo apt-get install -y enfuse
sudo apt-get install -y gnome-schedule
sudo apt-get install -y eog 

sudo apt-get install -y wicd-gtk

# Increase swapsize
sudo sed -i 's/.*CONF_SWAPSIZE=.*/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile
sudo /etc/init.d/dphys-swapfile stop
sudo /etc/init.d/dphys-swapfile start

# Edit the /boot/config.txt
sudo cp  /boot/config.txt /boot/config.txt.bup
sudo sed -i 's/.*start_x=.*/start_x=1/' /boot/config.txt
