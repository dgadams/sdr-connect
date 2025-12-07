#!/bin/sh
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT='1'
cd /sdr
/sdr/SDRconnect --server
