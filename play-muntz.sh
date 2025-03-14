#!/bin/bash
# This script uses a feature of bash - extglob which allows rm !(exception_list) to
# selectively remove any file in the current image layer except those listed.  
# Used for muntzing libraries and files down to the minimal set needed to run the application.

shopt -s extglob

#   Remove select libraries
    cd /usr/lib
    rm -rf !(x86_64-linux-gnu)

# remove all libraries except ...
	cd /usr/lib/x86_64-linux-gnu
	EXC="!(libc.*|ld-linux*"							# basic c library
#	EXC+="|libtinfo*"									# needed for bash
#	EXC+="|libselinux*|libacl.*|libattr.*|libpcre*"		# needed for cp
	EXC+="|libresolv.*"									# needed for busybox
	EXC+="|libdl.*|librt.*|libm.*|libpthread.*"			# For SDRconnect
	EXC+="|libasound.*|libusb*|libicu*|libudev.*"
	EXC+="|libuuid.*|libstdc++.*|libgcc_s.*"
	EXC+=")"
	rm -fr $EXC

#   Nuke some misc stuff, /usr/sbin and /usr/bin
    rm -rf /var/lib/dpkg
    rm -rf /var/lib/apt
    rm -rf /var/cache/debconf
	rm -rf /var/cache/apt
    rm -rf /usr/share
    rm -rf /usr/sbin/*

    cd /usr/bin
    rm !(busybox)
