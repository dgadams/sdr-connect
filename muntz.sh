#!/bin/bash
shopt -s extglob        #bash extesion to allow , rm -rf !(except-files|...)

# remove all libraries except ...
cd /usr/lib/x86_64-linux-gnu
	EXC="!(libc.*|ld-linux*|libresolv.*"
	EXC+="|libdl.*|librt.*|libm.*|libpthread.*"		# For SDRconnect
	EXC+="|libasound.*|libusb*|libicu*|libudev.*"
	EXC+="|libuuid.*|libstdc++.*|libgcc_s.*)"
rm -rf $EXC

cd /var && rm -rf *
cd /etc && rm -rf !(passwd|group|gshadow|shadow)
cd /usr && rm -rf !(lib|bin|sbin|lib64|libexec)
cd /usr/lib && rm -rf !(x86_64-linux-gnu)
cd /usr/sbin && rm -rf *
cd /usr/bin  && rm -rf !(busybox) # Must come last
