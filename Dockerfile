# Dockerfile for building the sdrconnect docker image
#
# D.G. Adams   2026-11-05    Slim version using Claude AI
#              2026-08-21    SDRconnect 1.0.10
#
# The SDR devices need USB read/write permissions.
# Add: SUBSYSTEMS=="usb", ATTRS{idVendor}=="1df7", MODE="0666"
# to a file in the docker host /etc/udev/rules.d to allow read/write access.
# CHANGED: Documented cgroup requirement for non-root USB firmware re-enumeration.
# In docker-compose, include device_cgroup_rules: ['c 189:* rmw'] when running non-root.

#######################################################################
# Stage 1: install SDRconnect and its libraries into a clean Debian,
# then stage the final filesystem in /out.
#######################################################################
FROM debian:trixie-slim AS install

WORKDIR /sdr

# libicu76 is dropped: see DOTNET_SYSTEM_GLOBALIZATION_INVARIANT below.
RUN apt-get -yq update && apt-get -yq install --no-install-recommends \
        gzip libusb-1.0-0 libasound2t64 libuuid1 libudev1 libmp3lame0 \
        busybox

# CHANGED: Register 'sdruser' (1000:1000) with /tmp as its home directory
# so /etc/passwd and /etc/group work out-of-the-box without creating /home.
RUN groupadd -g 1000 sdruser && \
    useradd -u 1000 -g 1000 -d /tmp -s /bin/sh sdruser

ADD https://www.sdrplay.com/software/sdrconnect_linux-x64_93b44446f.tar.gz \
    sdrconnect.tar.gz

# SkiaSharp and HarfBuzzSharp are not needed, so they are removed.
RUN tar xzf sdrconnect.tar.gz \
    && rm -f sdrconnect.tar.gz libSkiaSharp.so libHarfBuzzSharp.so

#----------------------------------------------------------------------
# Build the final filesystem in /out by copying IN only what is needed.
# Nothing is deleted, so scratch gets a minimal, clean filesystem.
#
#   Step 1: copy in the files listed below
#   Step 2: add the busybox applets and the dynamic loader
#   Step 3: check that /out is self-contained
#----------------------------------------------------------------------
ENV OUT=/out

# ---------------------------------------------------------------------
# Step 1: create the directory layout, then copy in the listed paths.
# Paths are relative to /; cp --parents recreates each one under /out.
# Missing paths are skipped and reported ("skipping missing" in the log).
RUN <<'EOR'
#!/bin/bash
    set -euo pipefail
    shopt -s nullglob       # a glob that matches nothing is dropped

    # --- /out layout: same merged-/usr symlinks as Debian ---
    mkdir -p $OUT/lib64 $OUT/tmp
    chmod 1777 $OUT/tmp         # .NET and sdruser use /tmp as writable HOME
    ln -s usr/lib $OUT/lib
    ln -s usr/bin $OUT/bin

    cd /

    # The application: SDRconnect, SDRconnect_headless, swig_bindings.so, ...
    APP=(
        sdr/SDRconnect* sdr/swig* sdr/lib*
    )

    # Every library the image needs is named here; step 3 fails the build
    # if one is missing. The .NET runtime loads several of them at runtime.
    # ld-linux is left out: step 2 adds it. The */ matches the one
    # architecture directory (x86_64-linux-gnu).
    LIBS=(
        # C library
        usr/lib/*-linux-gnu/{libc.,libm.,libdl.,librt.,libpthread.,libresolv.}*

        # C++ runtime
        usr/lib/*-linux-gnu/{libstdc++,libgcc_s}*

        # .NET TLS and compression
        usr/lib/*-linux-gnu/{libssl,libcrypto,libz}*

        # USB access
        usr/lib/*-linux-gnu/{libusb,libudev,libcap}*

        # audio, mp3, uuid
        usr/lib/*-linux-gnu/{libasound,libmp3,libuuid}*
    )

    # Users for USER nobody and USER sdruser
    DATA=(
        etc/passwd etc/group
    )

    # Keep only the paths that exist, and report the ones that do not
    KEEP=()
    for p in "${APP[@]}" "${LIBS[@]}" "${DATA[@]}"; do
        if [ -e "$p" ]; then
            KEEP+=("$p")
        else
            echo "skipping missing: $p"
        fi
    done

    cp -a --parents -t $OUT "${KEEP[@]}"
    cp -a --parents -t $OUT usr/bin/busybox

    # CHANGED: Ensure /out/sdr is owned by 1000:1000 and readable/executable
    # by all users so both 'sdruser' and 'nobody' can run it.
    chmod -R a+rX $OUT/sdr $OUT/usr/lib
    chown -R 1000:1000 $OUT/sdr
EOR

# ---------------------------------------------------------------------
# Step 2: busybox applets and the dynamic loader. The loader is the one
# library the lists above leave out.
RUN <<'EOR'
#!/bin/bash
    set -euo pipefail

    /usr/bin/busybox --install -s $OUT/usr/bin
    cp -L --parents /lib64/ld-linux-x86-64.so.2 $OUT
EOR

# ---------------------------------------------------------------------
# Step 3: check that /out is self-contained. Libraries are resolved
# against /out only, as in the final image. The build stops on any
# missing library. Only the app and busybox are checked; libraries the
# .NET runtime loads with dlopen are not.
RUN <<'EOR'
#!/bin/bash
    set -euo pipefail

    check() {
        if chroot $OUT /lib64/ld-linux-x86-64.so.2 --list "$1" \
               2>/dev/null | grep 'not found'; then
            echo "^ MISSING LIBS for $1"
            exit 1
        fi
    }

    check /usr/bin/busybox

    for f in $(find $OUT/sdr -type f \( -executable -o -name '*.so*' \)); do
        check "${f#$OUT}"
    done
EOR

#######################################################################
# Stage 2: the final image. Only the needed files are copied in.
#######################################################################
FROM scratch

COPY --from=install /out/ /
USER sdruser
WORKDIR /sdr
# Skip ICU (saves ~35MB). Remove this line if culture-specific behaviour
# breaks.
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

# No entrypoint. Use command in docker compose to run /sdr/SDRconnect or
# /sdr/SDRconnect_headless.
