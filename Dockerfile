#  Dockerfile for building sdrconnect docker image
#
#  D.G. Adams   2026-11-10    Slim version using Claude AI
#               2026-08-21    SDRconnect 1.0.10
#
# The SDR devices need USB read/write permissions.
# Add: SUBSYSTEMS=="usb", ATTRS{idVendor}=="1df7", MODE="0666"
# to a file in the docker host /etc/udev/rules.d to allow read/write access.

FROM debian:trixie-slim AS stage1

# Need to use bash to allow shopt -s nullglob for allow-list below
SHELL ["/bin/bash", "-c"]

# libicu76 dropped: see DOTNET_SYSTEM_GLOBALIZATION_INVARIANT below.
RUN apt-get -yq update && apt-get -yq install --no-install-recommends \
        gzip libusb-1.0-0 libasound2t64 libuuid1 libudev1 libmp3lame0 \
        libfontconfig1 busybox

WORKDIR /sdr
ADD https://www.sdrplay.com/software/sdrconnect_linux-x64_93b44446f.tar.gz sdrconnect.tar.gz

###################################################
# Build the final filesystem in /out by copying IN only what is needed:
#   - SDRconnect, SDRconnect_headless, swig_bindings.so and the other app files
#   - an allow-list of libraries (the .NET runtime loads several with dlopen,
#     which ldd cannot see, so these are named here)
#   - every library ldd finds for the binaries, as a safety net
#   - Debian's dynamic busybox with all applets, plus /etc/passwd and /etc/group
# Nothing is deleted, so scratch gets a minimal, clean filesystem.

RUN <<'EOR'
    set -euo pipefail
    shopt -s nullglob

    OUT=/out
    LIBDIR=/usr/lib/x86_64-linux-gnu
    mkdir -p $OUT$LIBDIR $OUT/usr/bin $OUT/lib64 $OUT/etc $OUT/sdr $OUT/tmp
    chmod 1777 $OUT/tmp
    ln -s usr/lib $OUT/lib
    ln -s usr/bin $OUT/bin

#   app files. libSkiaSharp.so and libHarfBuzzSharp.so are left out on purpose.
    tar xzf sdrconnect.tar.gz
    for f in SDRconnect* lib* swig*; do
        case $f in libSkiaSharp.so|libHarfBuzzSharp.so) continue ;; esac
        cp -a "$f" $OUT/sdr/
    done

#   allow-list of libraries, copied with their symlinks.
#   some of these libraries are loaded by .NET and aren't found by ldd below
    cd $LIBDIR
    LIBS=(
        libc.* libm.* libdl.* librt.* libpthread.* libresolv.*
        libstdc++* libgcc_s*
        libusb* libudev* libcap* libuuid* libasound* libmp3*
        libssl* libcrypto* libz*
    )
    cp -a "${LIBS[@]}" $OUT$LIBDIR/
    
#   busybox: copy the dynamic binary, then create every applet symlink
    cp -a /usr/bin/busybox $OUT/usr/bin/busybox
    /usr/bin/busybox --install -s $OUT/usr/bin

#   users for USER nobody
    cp -a /etc/passwd /etc/group $OUT/etc/

#   safety net: copy any library ldd finds that isn't already in /out
#   (this also supplies the /lib64 loader and busybox's libraries)
    for f in $OUT/sdr/SDRconnect* $OUT/sdr/*.so /usr/bin/busybox; do
        ldd "$f" || true
    done > /tmp/ldd.txt

#   fail the build if any library is missing
    grep 'not found' /tmp/ldd.txt && { echo "missing libraries"; exit 1; }

#   copy every library path in the ldd output
    for lib in $(grep -o '/[^ ]*' /tmp/ldd.txt | sort -u); do
        [ -e "$OUT$lib" ] || cp -L --parents "$lib" $OUT
    done
EOR

###################################################
# Building from scratch means only the needed files are in the image.

FROM scratch
COPY --from=stage1 /out/ /
USER nobody

# Skip ICU (saves ~35MB).  Remove this line if culture-specific behaviour breaks.
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

# No entrypoint.  Use command in docker compose to run /sdr/SDRconnect or /sdr/SDRconnect_headless
