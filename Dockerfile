#  Dockerfile for building sdrconnect docker image
#
#  D.G. Adams   2026-11-05    Slim version using Claude AI
#               2026-08-21    SDRconnect 1.0.10
#
# The SDR devices need USB read/write permissions.
# Add: SUBSYSTEMS=="usb", ATTRS{idVendor}=="1df7", MODE="0666"
# to a file in the docker host /etc/udev/rules.d to allow read/write access.

FROM debian:trixie-slim AS stage1
WORKDIR /sdr
SHELL ["/bin/bash", "-c"]

# libicu76 dropped: see DOTNET_SYSTEM_GLOBALIZATION_INVARIANT below.
RUN apt-get -yq update && apt-get -yq install --no-install-recommends \
        gzip libusb-1.0-0 libasound2t64 libuuid1 libudev1 libmp3lame0 \
        libfontconfig1 busybox

ADD https://www.sdrplay.com/software/sdrconnect_linux-x64_93b44446f.tar.gz sdrconnect.tar.gz

RUN <<'EOR'
    set -euo pipefail
    shopt -s extglob        # bash extension for rm -rf !(except-files|...)

    tar xzf sdrconnect.tar.gz

#   remove unneeded files added by SDRconnect
    rm -rf !(SDRconnect*|lib*|swig*)
    rm -f /sdr/libSkiaSharp.so /sdr/libHarfBuzzSharp.so

    cd /usr/lib/x86_64-linux-gnu
    EXC="!(libc.*|ld-linux*|libresolv.*|libdl.*|librt.*|libm.*|libpthread.*|libmp3*"
    EXC+="|libasound*|libusb*|libudev*|libuuid*|libstdc++*|libgcc_s*|libcap*"
    EXC+="|libssl*|libcrypto*|libz*"
    EXC+="|libfontconfig*|libfreetype*|libexpat*"  
    EXC+=")"
    rm -rf $EXC

#   remove unneeded files/dirs except ...
    cd /            && rm -rf !(bin|dev|etc|lib|lib64|proc|run|sbin|sdr|sys|usr)
    cd /etc         && rm -rf !(passwd|group|gshadow|shadow|hosts|resolv.conf|fonts)
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
COPY --from=stage1 / /
USER nobody

# Skip ICU (saves ~35MB).  Remove this line if culture-specific behaviour breaks.
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

# No entrypoint.  Use command in docker compose to run /sdr/SDRconnect or /sdr/SDRconnect_headless
