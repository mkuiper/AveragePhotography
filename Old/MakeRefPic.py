import time
import picamera

cam = picamera.PiCamera()

cam.iso = 200
cam.resolution = cam.MAX_RESOLUTION
cam.preview_fullscreen=False

cam.start_preview()
cam.exposure_compensation = 0 
time.sleep(5)           
cam.capture('Ref_image.jpg')

cam.stop_preview()


