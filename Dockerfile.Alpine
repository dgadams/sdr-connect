#  Dockerfile for building sdrconnect docker image
#
#  D.G. Adams 2025-01-02
#
# The SDR devices need USB read/write permissions.
# Add: SUBSYSTEMS=="usb", ATTRS{idVendor}=="1df7", MODE="0666"
# to a file in /etc/udev/rules.d to allow read/write access.
#
FROM alpine:latest
WORKDIR /sdr

RUN <<EOF
#   1.0.3
    URL="https://sdrplay.com/software//SDRconnect_linux-x64_b6fce59a3.run" 
#   V5
#    URL="https://sdrplay.com/software/SDRconnect_linux-x64_105b8f722.run"
#   V4
#    URL="https://sdrplay.com/software/SDRconnect_linux-x64_5dce37273.run"
#   V4 ARM64
#    URL="https://sdrplay.com/software//SDRconnect_linux-arm64_5dce37273.run" 
#   V3
#    URL="https://sdrplay.com/software/SDRconnect_linux-x64_f795c3df0.run"

    apk --no-cache add wget swig alsa-lib libusb libuuid icu gcompat 
    wget $URL -O sdrc.run
    chmod +x sdrc.run
    ./sdrc.run --tar xvf .
    rm -f *.ico *.txt *.dbg install.sh sdrc.run
    apk del wget
EOF

USER nobody
ENTRYPOINT  ["/sdr/SDRconnect", "--server"]
