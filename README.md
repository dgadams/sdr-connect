# sdrconnect
## Containerized SDRconnect server for AMD64.
### Allows for remote operation of an SDRplay device
- Version 1.0.10  of SDRconnect.
- Based on Debian Linux Trixie.
- This image allows either server or websocket mode depending
  on the compose script used.  The image contains both SDRconnect
  and SDRconnect_headless.  The command section of each compose script
  run the executable and provide needed arguments.
 - Github link: https://github.com/dgadams/sdr-connect

### example /etc/udev/rules.d/66-sdrplay.rules file that must live on the docker host machine.
```
SUBSYSTEMS=="usb", ATTRS{idVendor}=="1df7", MODE:="0666"
```
#### Notes:
 - This is an AMD64 image and will not work on a raspberry pi.
 - Caution if running other docker containers that talk to the sdrplay device
   he who gets the resource first, wins.
 - The commands in each compose script are required.  See help.txt for possible
   other commands when running in server mode.
 - Headless and Server containers can run at the same time but depending on your websocket application
   they may not be able to share the same SDR device.
 - This project uses licensed software from https://sdrplay.com.
    See the license.txt file.
