#  Dockerfile for building sdrconnect docker image
#
#  D.G. Adams 2023-09-28
#
# The SDR devices need USB read/write permissions.
# Add: SUBSYSTEMS=="usb", ATTRS{idVendor}=="1df7", MODE="0666"
# to a file in /etc/udev/rules.d to allow read/write access.
#

FROM --platform=linux/amd64 debian:bookworm-slim
WORKDIR /sdr
COPY ./SDRconnect_linux-x64_f795c3df0.run sdrc.run

RUN \
    apt-get update && \
    apt-get install -y swig libasound2-dev libusb-1.0-0 uuid-runtime libicu72  && \
    adduser --disabled-login --disabled-password --quiet sdr && \
    adduser --quiet sdr sdr && \
    chmod +x sdrc.run && \
    ./sdrc.run --tar xvf . && \
    rm sdrc.run && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER sdr
ENTRYPOINT  ["/sdr/SDRconnect", "--server"]
