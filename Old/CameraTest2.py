from time import sleep
import picamera

# capture images for HDR processing

with picamera.PiCamera() as cam:
    cam.iso = 200
    cam.resolution = cam.MAX_RESOLUTION
    cam.preview_fullscreen=False

    n=0
    for i in (24, 0, -24):
        cam.exposure_compensation = i
        n+=1
        if n==3:
            cam.iso=100
        name = ('temp_image%d.jpg' %n)

        cam.start_preview()
        sleep(5)
        cam.capture(name)
        cam.stop_preview()

