import time

import picamera

with picamera.PiCamera() as camera:

    camera.start_preview()

    time.sleep(5)

    camera.capture('/home/pi/Desktop/image.jpg')

    camera.stop_preview()
