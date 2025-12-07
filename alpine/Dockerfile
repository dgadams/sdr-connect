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
FROM alpine:latest AS dga-build
WORKDIR /sdr

# SDR Connect 1.0.5
ADD https://sdrplay.com/software/SDRconnect_linux-x64_e077f2ebe.run  sdrc.run

RUN <<EOR
    apk update
    apk add --no-cache libusb swig alsa-lib libuuid icu icu-libs icu-data-full 
    apk add --no-cache gcompat libucontext musl-obstack libc++ libgcc bash

	chmod +x sdrc.run
    ./sdrc.run --tar xvf .

    /bin/bash <<END_BASH
        shopt -s extglob        # bash extension to allow rf !(...)

#       Remove files/directories except those needed
        cd /                && rm -rf !(sdr|dev|proc|run|usr|bin|etc|sbin|lib|sys)
        cd /usr             && rm -rf !(bin|sbin|lib)
        cd /usr/lib         && rm -rf !(libusb*|libswig|libas*|libuuid*|icu*|libicu*|libresolv*|libucontext*|libobstack*|libstdc++*|libgcc*)
        cd /lib             && rm -rf apk firmware modules-load.d sysctl.d
        cd /etc             && rm -rf !(group|passwd|shadow)
        rm /sbin/apk
        cd /usr/bin && rm getconf getent iconv ldd scanelf ssl_client
        cd /bin && rm bash
        mkdir /lib64 && ln -s /lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
        
END_BASH
    cd /sdr
    rm -f *.ico *.txt *.dbg install.sh sdrc.run
    ln -s libHarfBuzzSharp.so /usr/lib
    ln -s libSkiaSharp.so /usr/lib
    ln -s swig_bindings.so /usr/lib
EOR

###################################################
# Building from scratch with a copy removes empty space.

FROM scratch AS install
WORKDIR /sdr
COPY --from=dga-build / /
COPY connect.sh .
USER nobody
ENTRYPOINT ["/sdr/connect.sh"]
