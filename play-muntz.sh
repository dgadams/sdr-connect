#!/bin/bash

#   remove unneeded files - do a little muntzing.
#   This works in conjuction with the filesystem build layer to allow
#   us to remove any file from the debian distribution

#   This is rather ugly and was created by iteratively removing and testing
#   until things broke.  Then put it back.  This is called muntzing.
#   Need to add extended globbing so rm !() works
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
