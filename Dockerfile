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

# SDR Connect 1.0.3
ADD https://sdrplay.com/software//SDRconnect_linux-x64_b6fce59a3.run sdrc.run

RUN <<EOR
	apt-get -yq update
    apt-get -yq install libusb-1.0-0 swig libasound2 libuuid1 libicu72 busybox
#	apt-get -yq install libfontconfig1 libfreetype6
	apt-get clean
	chmod +x sdrc.run
	./sdrc.run --tar xvf .
	rm -f *.ico *.txt *.dbg install.sh sdrc.run
EOR

# everything is in this layer so we can just clean it up
COPY play-muntz.sh .
RUN <<EOR
   ./play-muntz.sh
   /bin/busybox --install -s
   rm play-muntz.sh
EOR

###################################################
# Remember deleting files from build doesn't remove the space from the image.
# Thus create a scratch image and copy / which only copies the files and not the space.
# This saves about 30M in the install image.

FROM scratch AS install
COPY --from=dga-build / /
WORKDIR /sdr
USER nobody
ENTRYPOINT ["/sdr/SDRconnect", "--server"]
