#  Dockerfile for building sdrconnect docker image
#
#  D.G. Adams   2025-12-05    Pulled muntz.sh inside Dockerfile
#               2025-01-18    Multi level build using scratch.
#
# The SDR devices need USB read/write permissions.
# Add: SUBSYSTEMS=="usb", ATTRS{idVendor}=="1df7", MODE="0666"
# to a file in the docker host /etc/udev/rules.d to allow read/write access.
#
FROM debian:bookworm-slim AS dga-build
WORKDIR /sdr

# SDR Connect 1.0.5
ADD https://sdrplay.com/software//SDRconnect_linux-x64_e077f2ebe.run  sdrc.run
RUN <<EOR
#!/bin/bash
	apt-get -yq update
    apt-get -yq install libusb-1.0-0 swig libasound2 libuuid1 libicu72 busybox

#   install and cleanup SDRconnect
	chmod +x sdrc.run
    ./sdrc.run --tar xvf .
    rm -f *.ico *.txt *.dbg install.sh sdrc.run

    shopt -s extglob # bash extesion for rm -rf !(except-files|...)

#   remove all libraries except ...
    cd /usr/lib/x86_64-linux-gnu
    EXC="!(libc.*|ld-linux*|libresolv.*|libdl.*|librt.*|libm.*|libpthread.*"
    EXC+="|libasound.*|libusb*|libicu*|libudev*|libuuid*|libstdc++*|libgcc_s*)"
    rm -rf $EXC

#   remove uneeded directories and files except ...
    cd /            && rm -rf !(bin|dev|etc|lib|lib64|proc|run|sbin|sdr|sys|usr)
    cd /etc         && rm -rf !(passwd|group|gshadow|shadow)
    cd /usr         && rm -rf !(lib|bin|sbin|lib64|libexec)
    cd /usr/lib     && rm -rf !(x86_64-linux-gnu)
    cd /usr/sbin    && rm -rf *
    cd /usr/bin     && rm -rf !(busybox|bash) # Must come last

    /bin/busybox --install -s
    rm /bin/bash
EOR

###################################################
# Building from scratch with a copy removes empty space.

FROM scratch
COPY --from=dga-build / /
USER nobody
ENTRYPOINT ["/sdr/SDRconnect", "--server"]
