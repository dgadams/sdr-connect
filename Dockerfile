#  Dockerfile for building sdrconnect docker image
#
#  D.G. Adams 2025-01-18
#
# Modified 2025-01-18 to make a multi level build using scratch.
#
# The SDR devices need USB read/write permissions.
# Add: SUBSYSTEMS=="usb", ATTRS{idVendor}=="1df7", MODE="0666"
# to a file in the docker host /etc/udev/rules.d to allow read/write access.
#
FROM debian:bookworm-slim AS dga-build
WORKDIR /sdr

# SDR Connect 1.0.5
ADD https://sdrplay.com/software//SDRconnect_linux-x64_e077f2ebe.run  sdrc.run
COPY muntz.sh .

RUN <<EOR
	apt-get -yq update
    apt-get -yq install libusb-1.0-0 swig libasound2 libuuid1 libicu72 busybox

	chmod +x sdrc.run
    ./sdrc.run --tar xvf .
    ./muntz.sh
    /bin/busybox --install -s
    rm -f *.ico *.txt *.dbg install.sh sdrc.run muntz.sh
EOR

###################################################
# Building from scratch with a copy removes empty space.

FROM scratch AS install
COPY --from=dga-build / /
WORKDIR /sdr
USER nobody
ENTRYPOINT ["/sdr/SDRconnect", "--server"]
