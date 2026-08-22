#!/bin/bash

if [ -z "$BASH_VERSION" ]; then
    echo "Error: This script must be run with Bash." >&2
    exit 1
fi

set -Eeuo pipefail

#######################################
# CONFIG
#######################################

SDRCONNECT_GITBUILD="93b44446f"
RIGCONTROL_GITBUILD="74fbbe8"

SDRCONNECT_DIR="/opt/sdrconnect"
RIGCONTROL_DIR="/opt/rigcontrol"

SDRCONNECT_TAR_X86_64="sdrconnect_linux-x64_${SDRCONNECT_GITBUILD}.tar.gz"
SDRCONNECT_TAR_ARM64="sdrconnect_linux-arm64_${SDRCONNECT_GITBUILD}.tar.gz"

RIGCONTROL_TAR_X86_64="rigcontrol_linux-x64_${RIGCONTROL_GITBUILD}.tar.gz"
RIGCONTROL_TAR_ARM64="rigcontrol_linux-arm64_${RIGCONTROL_GITBUILD}.tar.gz"

SDRCONNECT_URL_X86_64="https://www.sdrplay.com/software/${SDRCONNECT_TAR_X86_64}"
SDRCONNECT_URL_ARM64="https://www.sdrplay.com/software/${SDRCONNECT_TAR_ARM64}"

RIGCONTROL_URL_X86_64="https://www.sdrplay.com/software/${RIGCONTROL_TAR_X86_64}"
RIGCONTROL_URL_ARM64="https://www.sdrplay.com/software/${RIGCONTROL_TAR_ARM64}"

PROFILE_SCRIPT="/etc/profile.d/sdrconnect.sh"
UDEV_RULES="/etc/udev/rules.d/66-sdrplay.rules"
OLD_UDEV_RULES="/etc/udev/rules.d/66-mirics.rules"

ICON_PATH="/usr/share/icons/hicolor/64x64/apps"

DOC1="/usr/share/doc/sdrconnect"
DOC2="/usr/share/doc/rigcontrol"

UNINSTALLER="${SDRCONNECT_DIR}/sdrconnect-uninstall.sh"
MANIFEST="${SDRCONNECT_DIR}/install-manifest.txt"

#######################################
# DESKTOP ENTRIES
#######################################
DESKTOP_ENTRIES=(
"sdrconnect|SDRconnect|/opt/sdrconnect/SDRconnect|sdrconnect|Utility;"
"rigcontrol|RigControl|/opt/rigcontrol/RigControl|rigcontrol|Utility;"
"nrspadministrator|NRSPAdministrator|/opt/sdrconnect/NRSPAdministrator|nrspadministrator|Utility;"
"nrspupdater|NRSPUpdater|/opt/sdrconnect/NRSPUpdater|nrspupdater|Utility;"
)

#######################################
# SYSTEMD SERVICES
#######################################
SYSTEMD_SERVICES=(
"sdrconnectserver|/opt/sdrconnect/SDRconnect --server|SDRconnect Server Service"
)

#######################################
# LICENSE
#######################################
LICENSE_TEXT=$(cat <<'EOF'
SDRconnect Installation
=======================

To continue with the installation, please review and accept this license agreement, use the SPACE BAR to page down, B to page up, UP and DOWN arrows to move one line at a time and Q will close the license agreement at any time or when you see END. Accept the license agreement by typing yes followed by pressing the RETURN or ENTER key when prompted.

SDRPLAY LIMITED END USER LICENCE AGREEMENT

IMPORTANT: READ CAREFULLY

The SDRplay software ('Software') you are about to install, run and/or use is licensed by SDRplay Limited, a company registered in England (No. 09035244), whose registered office is 21 Lenten Street, ALTON, GU34 1HG ('SDRplay'), and is subject to the following licence terms ('Licence'). 
"You" (or "Your") shall mean an individual or Legal Entity exercising permissions granted by this License.

By proceeding to install, run and/or use the Software, you confirm that you accept and agree to be bound by the terms of this Licence. If you do not agree to any of the terms of this Licence, SDRplay is unwilling to provide access to the Software to you and you should not proceed further and may not use the Software.

1.  Licence To Use The Software.
1.1  Grant of Licence.  
Subject to the terms and conditions of this License, SDRplay hereby grants to you a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable license to publicly display, publicly perform the Software in Object form.

1.2  Restrictions.
1.2.1  Except as described in 1.2.2 below, you may use the Software only with SDRplay hardware radio products which are produced and distributed by SDRplay Limited. 
1.2.2  If you use the EXTIO interface of SDRuno, which is available in versions 1.05 and earlier, you may use the Software with radio hardware from any supplier that supports the EXTIO interface. 
1.2.3  You may not:  modify, disassemble, decompile or reverse engineer the Software, except to the extent specifically authorised under applicable law notwithstanding contractual prohibition.

1.3  Open Source Software.  The Software may contain code, commonly referred to as open source software, which is distributed under any of the many known variations of open source licence terms, including terms which allow the free distribution and modification of the relevant software's source code and/or which require all distributors to make such source code freely available upon request, including any contributions or modifications made by such distributor (collectively, 'Open Source Software'). To the extent that the Software contains any Open Source Software, that element only is licensed to you pursuant to the relevant licence terms of the applicable third party licensor ('Open Source Licence Terms') and not pursuant to this Licence, and you accept and agree to be bound by such terms. A copy of the Open Source Licence Terms will be made available upon request.

2.  Confidentiality Obligations.  You acknowledge that the Software contains confidential, proprietary and trade secret information belonging to SDRplay and you agree to hold such information, and any other confidential or proprietary information of SDRplay (collectively, "Confidential Information") in strict confidence and agree not to disclose any Confidential Information to any third party. You will have no obligation to maintain the confidentiality of any information which: (a) is or becomes publicly available without breach of this Licence; (b) is rightfully received by you from a third party without an obligation of confidentiality and without breach of this Licence; (c) is required to be disclosed by law or regulation or by court order; or (d) has been approved for release by written permission of SDRplay. 

3.  Ownership.  You acknowledge and agree that SDRplay or its third party licensors (including in particular Mirics Limited) own all rights, title and interest in and to the Software and all modifications, enhancements and derivative works SDRplay may develop to or from the Software and any and all intellectual property rights in all of the foregoing. You agree not to use any of SDRplay's or Mirics' trademarks or other business names included in the Software for any purpose. You acknowledge that, except as expressly set out in this Licence, nothing in this Licence will give you rights in respect of any intellectual property rights owned by SDRplay or its licensors. All intellectual property rights and other rights of SDRplay and its licensors which are not expressly granted to you by this Licence are reserved. 

4.  Limited Warranty.  SDRplay warrants that the Software will, under normal operating conditions, operate substantially in accordance with SDRplay's published specification for the Software. SDRplay does not represent or warrant that: (a) the use of the Software will be secure, timely, uninterrupted or error-free or compatible in combination with any other hardware, software, system or data; (b) the Software will meet your expectations; (c) errors or defects in the Software will be corrected; or that (d) the Software is free of viruses or other harmful components. SDRplay makes no representation and gives no warranty in respect of any Open Source Software component of the Software.

Except as expressly set out in this Licence, no implied conditions, warranties or other terms, including any implied terms relating to satisfactory quality or fitness for any purpose, will apply to the Software and, to the maximum extent permitted by applicable law, are excluded by SDRplay.

5.  SDRplay's Liability.  Nothing in this Licence will limit or exclude SDRplay's liability to you: (a) for death or personal injury caused by SDRplay's negligence; (b) for fraud; (c) for breach of any obligations implied by section 12 of the Sale of Goods Act 1979 or section 2 of the Supply of Goods and Services Act 1982; or (d) for any other liability that may not, under applicable law, be limited or excluded. Subject to this, in no event will SDRplay be liable to you for any indirect or consequential losses, or for any loss of profit, revenue, contracts, data, goodwill or other similar losses, and any liability SDRplay does have for losses you suffer arising under or in connection with this Licence and/or the Software is strictly limited to losses that were reasonably foreseeable. 

6.  Data.   The Software may, without further notification, transmit details of any radio device using the Software, other than through the EXTIO or other interface, to an SDRplay server, and may update data held on any such device, and alert users to any available firmware updates.

7.  General.    You may not transfer or assign any or all of your rights and/or obligations under this Licence. All notices given by you to SDRplay must be given in writing to SDRplay's registered office address. If SDRplay fails to enforce any of our rights, that does not result in a waiver of that right. If any provision of these terms and conditions is found to be unenforceable, all other provisions shall remain unaffected. The terms of this Licence may not be varied except with SDRplay's express written consent. The terms of this Licence represent the entire agreement between you and SDRplay in relation to the subject matter of this Licence. The terms of this Licence shall be governed by English law and you agree that any claim you may have against SDRplay arising under or in connection with this Licence and/or the Software may only be dealt with by the English courts, provided that, if you are a consumer: (a) and you live in a part of the United Kingdom other than England, the applicable law of that part of the United Kingdom will govern and any claim may be brought by you before the courts there; or (b) you live in another member state of the European Union, any claim may be brought by you before the courts there.

Effective 12 Jan 2021

Type 'yes' to accept.
EOF
)

#######################################
# GLOBALS
#######################################
DRY_RUN=0
ARCH=""
SUDO=""
TMP_DIR="$(mktemp -d)"
ROLLBACK=()

#######################################
# OUTPUT
#######################################
if [[ -t 1 ]]; then
RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; NC=$'\033[0m'
else
RED=""; GREEN=""; YELLOW=""; NC=""
fi

info(){ echo -e "${GREEN}[INFO]${NC} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $*"; }
error(){ echo -e "${RED}[ERROR]${NC} $*" >&2; }

#######################################
# ARGS
#######################################
for arg in "$@"; do
    [[ "$arg" == "--dry-run" ]] && DRY_RUN=1
done

#######################################
# CLEANUP + ROLLBACK
#######################################
cleanup(){ rm -rf "$TMP_DIR"; }
rollback(){
    error "Failure - rolling back"
    for ((i=${#ROLLBACK[@]}-1;i>=0;i--)); do eval "${ROLLBACK[$i]}" || true; done
}
trap cleanup EXIT
trap rollback ERR

#######################################
# PLATFORM
#######################################
check_platform(){
    [[ "$(uname -s)" == "Linux" ]] || { error "Linux only"; exit 1; }
    case "$(uname -m)" in
        x86_64|amd64) ARCH="x86_64";;
        aarch64|arm64) ARCH="arm64";;
        *) error "Unsupported arch"; exit 1;;
    esac
}

#######################################
# SUDO
#######################################
setup_sudo(){ [[ "$EUID" -ne 0 ]] && SUDO="sudo"; }

ensure_sudo(){
    [[ -z "$SUDO" || "$DRY_RUN" -eq 1 ]] && return
    info "Requesting sudo..."
    sudo -v
}

run(){ [[ "$DRY_RUN" -eq 1 ]] && echo "[DRY-RUN] $*" || "$@"; }
run_root(){ [[ "$DRY_RUN" -eq 1 ]] && echo "[DRY-RUN] $SUDO $*" || ${SUDO:-} "$@"; }

#######################################
# DEPENDENCIES
#######################################
check_dependencies(){
    [[ "${NOTSUPPORTED:-0}" == "1" ]] && { info "Skipping dependency checks"; return; }

    . /etc/os-release
    [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *debian* ]] || { error "Unsupported OS"; exit 1; }

    info "Checking dependencies"
    pkgs=(curl tar ca-certificates gzip libusb-1.0-0 libasound2t64 libuuid1 libudev1 libmp3lame-dev libhamlib-dev)
    missing=()

    for p in "${pkgs[@]}"; do
        dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
    done

    [[ ${#missing[@]} -eq 0 ]] && return

    warn "Installing missing dependencies: ${missing[*]}"
    ensure_sudo
    run_root apt-get update -y
    run_root apt-get install -y "${missing[@]}"
}

#######################################
# LICENSE
#######################################
show_license() {
    if [[ "${ACCEPTLICENSE:-0}" == "1" ]]; then
        info "Licence auto-accepted via ACCEPTLICENSE=1"
        return
    fi

    local width="${COLUMNS:-80}"
    [[ "$width" =~ ^[0-9]+$ && "$width" -ge 20 ]] || width=80

    # Only page if running interactively
    if [[ -t 0 && -t 1 ]]; then

        if command -v less >/dev/null 2>&1; then
            # -R: allow colours if present
            # -F: exit if fits on one screen
            # -X: don't clear screen on exit
	    # -E: exit when EOF reached
	    # -M: more verbose prompts
	    # --mouse: enables mouse input
            printf "%s\n" "$LICENSE_TEXT" | fold -s -w "$width" | less -RFXEM --mouse

        elif command -v more >/dev/null 2>&1; then
            printf "%s\n" "$LICENSE_TEXT" | fold -s -w "$width" | more

        else
            printf "%s\n" "$LICENSE_TEXT" | fold -s -w "$width"
        fi

    else
        # Non-interactive terminal (CI, pipes, etc.)
        printf "%s\n" "$LICENSE_TEXT" | fold -s -w "$width"
    fi

    echo
    read -rp "Do you accept the licence? (yes/no): " reply

    case "$reply" in
        yes|y|Y)
            info "Licence accepted"
            ;;
        *)
            error "Licence not accepted"
            exit 1
            ;;
    esac
}

#######################################
# DOWNLOAD
#######################################
pushd(){
    command pushd "$@" > /dev/null
}

popd(){
    command popd "$@" > /dev/null
}

download(){
    if [[ "${DONOTDOWNLOAD:-0}" == "1" ]]; then
        info "Using local install files via DONOTDOWNLOAD=1"
        if [ -e "$3" ]; then
            info "Using local $3"
            run cp "$3" "$2"
        else
            error "Cannot find $3"
            exit 1
        fi
        if [ -e "$3.sha256" ]; then
            info "Using local $3.sha256"
            run cp "$3.sha256" "$2.sha256"
        else
            error "Cannot find $3.sha256"
            exit 1
        fi
    else
        run curl -fL --retry 3 -o "$2" "$1"
        run curl -fL --retry 3 -o "$2.sha256" "$1.sha256"
    fi
    pushd "${TMP_DIR}"
    if sha256sum -c "$3.sha256"; then
        info "Checksum successful"
        popd
    else
        error "Checksum failed"
	popd
	exit 1
    fi
}

#######################################
# INSTALL CORE
#######################################
install_tar(){
    run_root mkdir -p "$2"
    ROLLBACK+=("${SUDO:-} rm -rf '$2'")
    run_root tar -xzf "$1" -C "$2" --strip-components=1
}

#######################################
# SYSTEM FILES
#######################################
install_profile(){
run_root bash -c "cat > $PROFILE_SCRIPT <<'EOF'
export SDRCONNECT_HOME=/opt/sdrconnect
export RIGCONTROL_HOME=/opt/rigcontrol
export PATH=\"\$SDRCONNECT_HOME:\$RIGCONTROL_HOME:\$PATH\"
EOF"
ROLLBACK+=("${SUDO:-} rm -f '$PROFILE_SCRIPT'")
}

install_udev(){
run_root bash -c "cat > $UDEV_RULES <<'EOF'
SUBSYSTEM==\"usb\",ENV{DEVTYPE}==\"usb_device\",ATTRS{idVendor}==\"1df7\",ATTRS{idProduct}==\"2500\",MODE:=\"0666\"
SUBSYSTEM==\"usb\",ENV{DEVTYPE}==\"usb_device\",ATTRS{idVendor}==\"1df7\",ATTRS{idProduct}==\"3000\",MODE:=\"0666\"
SUBSYSTEM==\"usb\",ENV{DEVTYPE}==\"usb_device\",ATTRS{idVendor}==\"1df7\",ATTRS{idProduct}==\"3010\",MODE:=\"0666\"
SUBSYSTEM==\"usb\",ENV{DEVTYPE}==\"usb_device\",ATTRS{idVendor}==\"1df7\",ATTRS{idProduct}==\"3020\",MODE:=\"0666\"
SUBSYSTEM==\"usb\",ENV{DEVTYPE}==\"usb_device\",ATTRS{idVendor}==\"1df7\",ATTRS{idProduct}==\"3030\",MODE:=\"0666\"
SUBSYSTEM==\"usb\",ENV{DEVTYPE}==\"usb_device\",ATTRS{idVendor}==\"1df7\",ATTRS{idProduct}==\"3040\",MODE:=\"0666\"
SUBSYSTEM==\"usb\",ENV{DEVTYPE}==\"usb_device\",ATTRS{idVendor}==\"1df7\",ATTRS{idProduct}==\"3050\",MODE:=\"0666\"
SUBSYSTEM==\"usb\",ENV{DEVTYPE}==\"usb_device\",ATTRS{idVendor}==\"1df7\",ATTRS{idProduct}==\"3060\",MODE:=\"0666\"
EOF"
run_root rm -f "$OLD_UDEV_RULES"
ROLLBACK+=("${SUDO:-} rm -f '$UDEV_RULES'")
}

#######################################
# DESKTOP
#######################################
install_desktop_entry(){
    local id="$1" name="$2" exec="$3" icon="$4" cat="$5"
    local target="/usr/share/applications/${id}.desktop"

run_root bash -c "cat > $target <<EOF
[Desktop Entry]
Name=$name
Exec=$exec
Icon=$icon
Type=Application
Terminal=false
Categories=$cat
EOF"

ROLLBACK+=("${SUDO:-} rm -f '$target'")
}

install_all_desktops(){
    for e in "${DESKTOP_ENTRIES[@]}"; do
        IFS="|" read -r id name exec icon cat <<< "$e"
        install_desktop_entry "$id" "$name" "$exec" "$icon" "$cat"
    done
}

#######################################
# ICON
#######################################
install_icon(){
    run_root install -m 0644 "$SDRCONNECT_DIR/icons/64x64/sdrconnect.png" "$ICON_PATH/sdrconnect.png"
    run_root install -m 0644 "$RIGCONTROL_DIR/icons/64x64/rigcontrol.png" "$ICON_PATH/rigcontrol.png"
    run_root install -m 0644 "$SDRCONNECT_DIR/icons/64x64/nrspadministrator.png" "$ICON_PATH/nrspadministrator.png"
    run_root install -m 0644 "$SDRCONNECT_DIR/icons/64x64/nrspupdater.png" "$ICON_PATH/nrspupdater.png"
    ROLLBACK+=("${SUDO:-} rm -f '${ICON_PATH}/sdrconnect.png'")
    ROLLBACK+=("${SUDO:-} rm -f '${ICON_PATH}/rigcontrol.png'")
    ROLLBACK+=("${SUDO:-} rm -f '${ICON_PATH}/nrspadministrator.png'")
    ROLLBACK+=("${SUDO:-} rm -f '${ICON_PATH}/nrspupdater.png'")
}

#######################################
# DOCS
#######################################
install_docs(){
    run_root mkdir -p "$DOC1" "$DOC2"
    run_root rm -f "$DOC1/LICENCE.gz"
    run_root install -m 0644 "$SDRCONNECT_DIR/LICENCE" "$DOC1/LICENCE"
    run_root rm -f "$DOC2/Hamlib.COPYING.LIB.gz"
    run_root install -m 0644 "$RIGCONTROL_DIR/Hamlib.COPYING.LIB" "$DOC2/Hamlib.COPYING.LIB"
    run_root gzip "$DOC1/LICENCE"
    run_root gzip "$DOC2/Hamlib.COPYING.LIB"
    ROLLBACK+=("${SUDO:-} rm -rf '$DOC1'")
    ROLLBACK+=("${SUDO:-} rm -rf '$DOC2'")
}

#######################################
# SYSTEMD
#######################################
install_service(){
    local name="$1" exec="$2" desc="$3"
    local path="/etc/systemd/system/${name}.service"

run_root bash -c "cat > $path <<EOF
[Unit]
Description=$desc
After=network.target

[Service]
ExecStart=$exec
Restart=always

[Install]
WantedBy=multi-user.target
EOF"

    run_root systemctl daemon-reload
    run_root systemctl enable "$name"
    run_root systemctl start "$name"
    ROLLBACK+=("${SUDO:-} systemctl disable $name || true")
    ROLLBACK+=("${SUDO:-} rm -f '$path'")
}

remove_service(){
    local name="$1"
    run_root systemctl stop "$name" || true
    run_root systemctl disable "$name" || true
    run_root rm -f "/etc/systemd/system/${name}.service"
    run_root systemctl daemon-reload
}

handle_systemd() {
    local mode="${SYSTEMD_MODE:-skip}"

    # If skipping, do nothing at all
    if [[ "$mode" == "skip" || -z "$mode" ]]; then
        info "Skipping systemd configuration"
        return
    fi

    # Only resolve target if we actually need it
    local target="${SYSTEMD_TARGET:-}"

    [[ -z "$target" ]] && {
        warn "SYSTEMD_TARGET not set, skipping systemd setup"
        return
    }

    case "$target" in
        sdrconnectserver) sel=("sdrconnectserver");;
        *)
            error "Invalid SYSTEMD_TARGET: $target"
            exit 1
            ;;
    esac

    case "$mode" in
        install)
            for s in "${SYSTEMD_SERVICES[@]}"; do
                IFS="|" read -r n exec d <<< "$s"
                for t in "${sel[@]}"; do
                    [[ "$n" == "$t" ]] && install_service "$n" "$exec" "$d"
                done
            done
            ;;
        remove)
            for t in "${sel[@]}"; do
                remove_service "$t"
            done
            ;;
        *)
            error "Invalid SYSTEMD_MODE: $mode"
            exit 1
            ;;
    esac
}

#######################################
# UNINSTALL
#######################################
create_uninstaller(){
cat <<EOF | run_root tee "$UNINSTALLER" >/dev/null
#!/usr/bin/env bash
while read -r p; do [ -e "\$p" ] && sudo rm -rf "\$p"; done < "$MANIFEST"
echo "SDRconnect & RigControl Uninstalled."
echo "Logout and Login again for paths to update."
EOF
run_root chmod +x "$UNINSTALLER"
}

write_manifest(){
printf "%s\n" \
"$SDRCONNECT_DIR" "$RIGCONTROL_DIR" \
"$PROFILE_SCRIPT" \
"/usr/share/applications/sdrconnect.desktop" \
"/usr/share/applications/rigcontrol.desktop" \
"/usr/share/applications/nrspadministrator.desktop" \
"/usr/share/applications/nrspupdater.desktop" \
"$ICON_PATH/sdrconnect.png" \
"$ICON_PATH/rigcontrol.png" \
"$ICON_PATH/nrspadministrator.png" \
"$ICON_PATH/nrspupdater.png" \
"$DOC1" "$DOC2" \
"$UNINSTALLER" "$MANIFEST" \
| run_root tee "$MANIFEST" >/dev/null
}

#######################################
# REFRESH
#######################################
refresh(){
    command -v update-desktop-database >/dev/null && run_root update-desktop-database || true
    command -v gtk-update-icon-cache >/dev/null && run_root gtk-update-icon-cache /usr/share/icons/hicolor || true
}

#######################################
# MAIN
#######################################
main(){
    check_platform
    setup_sudo
    show_license
    check_dependencies
    ensure_sudo

    [[ "$ARCH" == "x86_64" ]] && {
        U1="$SDRCONNECT_URL_X86_64"; U2="$RIGCONTROL_URL_X86_64"
        F1="$SDRCONNECT_TAR_X86_64"; F2="$RIGCONTROL_TAR_X86_64"
    } || {
        U1="$SDRCONNECT_URL_ARM64"; U2="$RIGCONTROL_URL_ARM64"
        F1="$SDRCONNECT_TAR_ARM64"; F2="$RIGCONTROL_TAR_ARM64"
    }

    T1="$TMP_DIR/$F1"
    T2="$TMP_DIR/$F2"

    info "Downloading software..."
    download "$U1" "$T1" "$F1"
    download "$U2" "$T2" "$F2"

    install_tar "$T1" "$SDRCONNECT_DIR"
    install_tar "$T2" "$RIGCONTROL_DIR"

    install_profile
    install_udev
    install_icon
    install_all_desktops
    install_docs

    handle_systemd

    create_uninstaller
    write_manifest
    refresh

    info "Install complete - logout and login for path update"
    info "To uninstall use: $UNINSTALLER"
}

main         abort
