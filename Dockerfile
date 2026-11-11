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

# libicu76 dropped: see DOTNET_SYSTEM_GLOBALIZATION_INVARIANT below.
RUN apt-get -yq update && apt-get -yq install --no-install-recommends \
        gzip libusb-1.0-0 libasound2t64 libuuid1 libudev1 libmp3lame0 busybox

ADD https://www.sdrplay.com/software/sdrconnect_linux-x64_93b44446f.tar.gz sdrconnect.tar.gz

# SkiaSharp and HarfBuzzSharp are not needed, so they are removed before copying
RUN tar xzf sdrconnect.tar.gz && rm -f sdrconnect.tar.gz libSkiaSharp.so libHarfBuzzSharp.so

###################################################
# Build the final filesystem in /out by copying IN only what is needed.
# Nothing is deleted, so scratch gets a minimal, clean filesystem.
#
# Steps:  1. copy the files in 
#         2. busybox and the loader
#         3. check that /out is self-contained

ENV OUT=/out

# ---------------------------------------------------------------
# Step 1: directory layout, then copy in everything on the lists below.
# The paths are relative to /, and cp --parents recreates each one under /out.
# A name that does not exist is skipped, and reported in the build log
# (look for "skipping missing").
RUN <<'EOR'
#!/bin/bash
    set -euo pipefail
    shopt -s nullglob       # unmatched globs vanish

#   --- layout: same merged-/usr symlinks as Debian ---
    mkdir -p $OUT/lib64 $OUT/tmp
    chmod 1777 $OUT/tmp         # .NET expects a /tmp
    ln -s usr/lib $OUT/lib
    ln -s usr/bin $OUT/bin

    cd /

#   the application: SDRconnect, SDRconnect_headless, swig_bindings.so, ...
    APP=( sdr/{SDRconnect*,swig*,lib*} )

#   Every library the image needs is named here. Step 3 fails the build if one is missing.
#   The .NET runtime loads several of them at runtime. ld-linux is left out: step 2 adds it.
    M=usr/lib/x86_64-linux-gnu
    LIBS=(
        $M/{libc.*,libm.*,libdl.*,librt.*,libpthread.*,libresolv.*}   # C library
        $M/{libstdc++*,libgcc_s*}                                     # C++ runtime
        $M/{libssl*,libcrypto*,libz*}                                 # .NET TLS, compression
        $M/{libusb*,libudev*,libcap*}                                 # USB access
        $M/{libasound*,libmp3*,libuuid*}                              # audio, mp3, uuid
    )

#   users for USER nobody
    DATA=( etc/{passwd,group} )

#   keep only the names that exist, and say which ones were skipped
    KEEP=()
    for p in "${APP[@]}" "${LIBS[@]}" "${DATA[@]}"; do
        if [ -e "$p" ]; then KEEP+=("$p"); else echo "skipping missing: $p"; fi
    done

    cp -a --parents -t $OUT "${KEEP[@]}"
    cp -a --parents -t $OUT usr/bin/busybox
EOR

# ---------------------------------------------------------------
# Step 2: busybox applets, and the dynamic loader.
# The loader is the one library the lists above leave out.
RUN <<'EOR'
#!/bin/bash
    set -euo pipefail

    /usr/bin/busybox --install -s $OUT/usr/bin      # every applet goes in /usr/bin
    cp -L --parents /lib64/ld-linux-x86-64.so.2 $OUT
EOR

# ---------------------------------------------------------------
# Step 3: check /out is self-contained. Libraries are resolved against /out only,
# as in the final image. The build stops on any missing library.
# Only the app and busybox are checked; the dlopen'd libraries are not.
RUN <<'EOR'
#!/bin/bash
    set -euo pipefail

    CHECK=(
        /usr/bin/busybox
        $(find $OUT/sdr -type f \( -executable -o -name '*.so*' \) | sed "s#^$OUT##")
    )
    for f in "${CHECK[@]}"; do
        if chroot $OUT /lib64/ld-linux-x86-64.so.2 --list "$f" 2>/dev/null | grep 'not found'; then
            echo "^ MISSING LIBS for $f"; exit 1
        fi
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
