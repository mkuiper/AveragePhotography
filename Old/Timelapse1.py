import time

import picamera

 

NO_OF_DAYS = 1

FRAMES_PER_HOUR = 60

FRAMES = FRAMES_PER_HOUR * 24 * NO_OF_DAYS

 

def capture_frame(frame):

    with picamera.PiCamera() as cam:

        time.sleep(2)

        cam.capture('/home/pi/Desktop/timelapse/frame%03d.jpg' % frame)

 

# Capture the images

for frame in range(FRAMES):

    # Note the time before the capture

    start = time.time()

    capture_frame(frame)

    # Wait for the next capture. Note that we take into

    # account the length of time it took to capture the

    # image when calculating the delay

    time.sleep(

        int(60 * 60 / FRAMES_PER_HOUR) - (time.time() - start)

)
