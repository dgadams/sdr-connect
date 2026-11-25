# Dockerfile for building the sdrconnect docker image
#
# D.G. Adams   2026-11-24    Healthcheck built into the image
#              2026-11-05    Slim version using Claude AI
#              2026-08-21    SDRconnect 1.0.10
#
# The SDR devices need USB read/write permissions.
# Add: SUBSYSTEMS=="usb", ATTRS{idVendor}=="1df7", MODE="0666"
# to a file in the docker host /etc/udev/rules.d to allow read/write access.
# When running non-root, USB firmware re-enumeration also needs, in docker-compose:
#   device_cgroup_rules: ['c 189:* rmw']

#######################################################################
# Stage 1: install SDRconnect and its libraries into a clean Debian,
# then stage the final filesystem in /out.
#######################################################################
FROM debian:trixie-slim AS install

WORKDIR /sdr

# libicu is not installed: see DOTNET_SYSTEM_GLOBALIZATION_INVARIANT below.
# tar and gzip are already part of debian-slim.
RUN apt-get -yq update && apt-get -yq install --no-install-recommends \
        libusb-1.0-0 libasound2t64 libuuid1 libudev1 libmp3lame0 busybox

# The ADD assumes the location of sdrconnect is correct but it has
# changed between revisions.  This works for 1.0.10.
ADD https://www.sdrplay.com/software/sdrconnect_linux-x64_93b44446f.tar.gz \
    sdrconnect.tar.gz
RUN tar xzf sdrconnect.tar.gz && rm sdrconnect.tar.gz

#----------------------------------------------------------------------
# Build the final filesystem in /out by copying IN only what is needed.
# Nothing is deleted, so scratch gets a minimal, clean filesystem.
# Paths are relative to /; cp --parents recreates each one under /out.
# A missing plain path fails the build; a glob that matches nothing is
# dropped (nullglob), and the check in the next RUN catches any library
# the app actually needs.
#----------------------------------------------------------------------
ENV OUT=/out

RUN <<'EOR'
#!/bin/bash
    set -euo pipefail
    shopt -s nullglob

    # --- /out layout: same merged-/usr symlinks as Debian ---
    mkdir -p $OUT/lib64 $OUT/tmp $OUT/etc
    chmod 1777 $OUT/tmp         # writable HOME for .NET
    ln -s usr/lib $OUT/lib
    ln -s usr/bin $OUT/bin

    cd /

    # The application: SDRconnect, SDRconnect_headless, swig_bindings.so
    # and libSystem.IO.Ports.Native.so. libSkiaSharp.so and
    # libHarfBuzzSharp.so are not needed, so they are simply not listed.
    APP=(
        sdr/SDRconnect* sdr/swig* sdr/libSystem*
    )

    # Every library the image needs. ld-linux is added separately below.
    # The */ matches the one architecture directory (x86_64-linux-gnu).
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

    cp -a --parents -t $OUT "${APP[@]}" "${LIBS[@]}" usr/bin/busybox

    # busybox applets and the dynamic loader (the one lib not listed above)
    /usr/bin/busybox --install -s $OUT/usr/bin
    cp -L --parents /lib64/ld-linux-x86-64.so.2 $OUT

    # ---- Minimal user database, written directly (no Debian copy) ----
    # These two lines create /out/etc/passwd and /out/etc/group, which the
    # final COPY puts at /etc/passwd and /etc/group in the scratch image.
    # sdruser (1000) has /tmp as home so the app can write its config file.
    printf 'root:x:0:0:root:/root:/bin/sh\nsdruser:x:1000:1000::/tmp:/bin/sh\n' > $OUT/etc/passwd
    printf 'root:x:0:\nsdruser:x:1000:\n' > $OUT/etc/group

    # Readable by any user, owned by sdruser
    # (SDRconnect_headless needs to write in /sdr, so keep the chown)
    chmod -R a+rX $OUT/sdr
    chown -R 1000:1000 $OUT/sdr
EOR

# ---------------------------------------------------------------------
# Check that /out is self-contained. Libraries are resolved against /out
# only, as in the final image. The build stops on any missing library.
# Libraries the .NET runtime loads with dlopen are not checked.
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
#          The ENV invariant line is used in lieu of including the ICU
#          lib (saves about 35MB).
#          HOME=/tmp lets any uid (compose "user:" override) write its config.
#          No Entrypoint. Commands are specified in the compose file.
#######################################################################
FROM scratch
COPY --from=install /out/ /
USER sdruser
WORKDIR /sdr
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 \
    HOME=/tmp

# One check for both modes, chosen by which process is running:
#   SDRconnect_headless -> websocket port 5454
#   SDRconnect (server) -> port 50000
# The ports must match --websocket_port / --port in the compose command.
# nc -w 2 bounds the connect; 127.0.0.1 avoids an IPv6 localhost lookup.
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD { pidof SDRconnect_headless >/dev/null \
        && nc -w 2 127.0.0.1 5454 </dev/null; } \
   || { pidof SDRconnect >/dev/null \
        && nc -w 2 127.0.0.1 50000 </dev/null; } \
   || exit 1