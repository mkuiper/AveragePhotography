#!/bin/bash
#
# Enfuse test rendering
# 

if [ ! -d out ]; then
	echo "Creating directory out/"
	mkdir out || exit 1
fi
if [ ! -f files ]; then
	echo "Please create a file named files, which contains the file names of the pictures you'd like to add, in one line."
	echo "Example: ls *.jpg | xargs echo > files"
	echo
	echo "Output of files would be something like this:"
	echo "20140910_232946.tif.jpg 20140910_233016.tif.jpg 20140910_233106.tif.jpg 20140910_233116.tif.jpg 20140910_233336.tif.jpg 20140910_233416.tif.jpg 20140910_233526.tif.jpg 20140910_233536.tif.jpg 20140910_233616.tif.jpg 20140910_233636.tif.jpg"
	exit 1
fi

for type in average lightness l-star luminance pl-star value ; do 
	if [ ! -f "out/$type.jpg" ]; then
		enfuse -v -w --gray-projector=$type -o out/normal-$type.jpg `cat files`
	fi
	if [ ! -f "out/hardmask-$type.jpg" ]; then
		enfuse -v -w --hard-mask --gray-projector=$type -o out/hardmask-$type.jpg `cat files`
	fi
done

for mu in 0.00 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 1.00 ; do
	m=`echo $mu | sed 's/\.//'`
	file=out/mu-${m}.jpg
	if [ ! -f "$file" ]; then
 		enfuse -v -w --exposure-mu=$mu -o $file `cat files`
	fi
	file=out/hardmask-mu-${m}.jpg
	if [ ! -f "$file" ]; then
 		enfuse -v --hard-mask -w --exposure-mu=$mu -o $file `cat files`
	fi
done

for sigma in 0.00 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 1.00 ; do
	s=`echo $sigma | sed 's/\.//'`
	file=out/sigma-${s}.jpg
	if [ ! -f "$file" ]; then
 		enfuse -v -w --exposure-sigma=$sigma -o $file `cat files`
	fi
	file=out/hardmask-sigma-${s}.jpg
	if [ ! -f "$file" ]; then
 		enfuse -v -w --hard-mask --exposure-sigma=$sigma -o $file `cat files`
	fi
done

for mu in 0.00 0.25 0.50 0.75 1.00 ; do
	for sigma in 0.00 0.25 0.50 0.75 1.00 ; do
		s=`echo $sigma | sed 's/\.//'`
		m=`echo $mu | sed 's/\.//'`
		file=out/mu-${m}_sigma-${s}.jpg
		
		if [ ! -f "$file" ]; then
	 		enfuse -v -w --gray-projector=average --hard-mask --exposure-mu=$mu --exposure-sigma=$sigma -o $file `cat files`
		fi
		file=out/hardmask-mu-${m}_sigma-${s}.jpg
		
		if [ ! -f "$file" ]; then
	 		enfuse -v -w --hard-mask --gray-projector=average --hard-mask --exposure-mu=$mu --exposure-sigma=$sigma -o $file `cat files`
		fi
	done
done

