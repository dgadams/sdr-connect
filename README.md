# sdr-connect 
## Containerized SDRconnect server.  
### Allows for remote operation of an SDRplay device
- Version 1.0.7  of SDRconnect.
- Based on Debian Linux, bookworm.  Size 195 MB.

### Running with docker compose yml file:
```
#  D.G. Adams 2025-08-06
#
# The SDR devices need USB read/write permissions.
# Add: SUBSYSTEMS=="usb", ATTRS{idVendor}=="1df7", MODE="0666"
# to a file in /etc/udev/rules.d to allow read/write access.
#
name: sdrconnect

services:
  rsp-dx:
    container_name: rsp-dx
    image: dgadams/sdr-connect:latest
    restart: unless-stopped
    ports:
      - 50000:50000
    devices:
      - /dev/bus/usb
    command:
      - "--port=50000"
      - "--centerfrequency=95500000"
      - "--antenna=1"
      - "--hwser=2103083B44"
#
# Commands are optional.  See help.txt for a list of sdrConnect command line arguments.
```
### example /etc/udev/rules.d/66-sdrplay.rules file that must live on the docker host machine.
```
SUBSYSTEMS=="usb", ATTRS{idVendor}=="1df7", MODE:="0666"

```
#### Notes:
 - Caution if running other docker containers that talk to the sdrplay device.  
He who gets the resource first, wins.
 - This project uses licensed software from https://sdrplay.com.
See the license.txt file.
