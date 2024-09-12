#  Dockerfile for building sdrconnect docker image
#
#  D.G. Adams 2023-09-28
#
# The SDR devices need USB read/write permissions.
# Add: SUBSYSTEMS=="usb", ATTRS{idVendor}=="1df7", MODE="0666"
# to a file in /etc/udev/rules.d to allow read/write access.
#

FROM --platform=linux/amd64 alpine:latest
WORKDIR /sdr
COPY ./SDRconnect_linux-x64_f795c3df0.run sdrc.run

RUN apk add swig alsa-lib-dev libusb libuuid icu gcompat && \
    adduser -D sdr && \
    adduser sdr sdr && \
    chmod +x sdrc.run && \
    ./sdrc.run --tar xvf . && \
    rm sdrc.run

USER sdr
ENTRYPOINT  ["/sdr/SDRconnect", "--server"]
