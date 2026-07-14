# sdrconnect
## Containerized SDRconnect server for AMD64.
### Allows for remote operation of an SDRplay device
- Version 1.0.9  of SDRconnect.
- Based on Debian Linux Trixie.
- This image allows either server or websocket mode depending
  on the compose script used.  The image contains both SDRconnect
  and SDRconnect_headless.  The command section of each compose script
  run the executable and provide needed arguments.  

### Running server mode with docker compose yml file:
```
#  D.G. Adams 2025-08-06
#
# The SDR devices need USB read/write permissions.
# Add: SUBSYSTEMS=="usb", ATTRS{idVendor}=="1df7", MODE="0666"
# to a file in /etc/udev/rules.d to allow read/write access.
#
#
#
name: sdrconnect
services:
  rsp-dx:
    container_name: rsp-dx
    image: dgadams/sdrconnect
    restart: unless-stopped
    network_mode: host
    devices:
      - /dev/bus/usb
    command:
      - "/sdr/SDRconnect"
      - "--server"
      - "--port=50000"
```
### example /etc/udev/rules.d/66-sdrplay.rules file that must live on the docker host machine.
```
SUBSYSTEMS=="usb", ATTRS{idVendor}=="1df7", MODE:="0666"

```
### example docker compose file for headless websocket version
```
name: sdrconnect-headless
services:
  sdrconnect-headless:
    container_name: sdrconnect-headless
    image: dgadams/sdrconnect
    restart: unless-stopped
    init: true
    network_mode: host
    devices:
      - /dev/bus/usb
    command: 
      - "/sdr/SDRconnect_headless"
      - "--websocket_port=5454"
```
#### Notes:
 - This is built for AMD64 architecture CPUs and does not work on raspberry-pi.
 - Caution if running other docker containers that talk to the sdrplay device
   he who gets the resource first, wins.
 - The commands in each compose script are required.  See help.txt for possible
   other commands when running in server mode.
 - Headless and Server containers can run at the same time but depending on your websocket application
   they may not be able to share the same SDR device.
 - This project uses licensed software from https://sdrplay.com.
    See the license.txt file.
