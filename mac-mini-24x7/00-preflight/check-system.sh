#!/bin/bash

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MAC_RUNBOOK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
. "$MAC_RUNBOOK_ROOT/scripts/lib.sh"

is_supported_platform() {
    [ "$1" = "Darwin" ]
}

is_supported_macos_version() {
    version_major=${1%%.*}
    case "$version_major" in
        ''|*[!0-9]*) return 1 ;;
    esac
    [ "$version_major" -ge 12 ]
}

is_mac_mini() {
    [ "$1" = "Mac mini" ]
}

if [ "$1" = "--self-test-probes" ]; then
    is_supported_platform Darwin && \
        ! is_supported_platform Linux && \
        is_supported_macos_version 12.0 && \
        is_supported_macos_version 26.0 && \
        ! is_supported_macos_version 11.7 && \
        is_mac_mini "Mac mini" && \
        ! is_mac_mini "MacBook Air"
    exit $?
fi

fixture_result "$1"
fixture_code=$?
if [ "$fixture_code" -ne 64 ]; then
    exit "$fixture_code"
fi

if ! is_supported_platform "$(uname -s 2>/dev/null)"; then
    fail "target is not macOS"
    exit 1
fi
pass "target platform is macOS"

mac_version=$(sw_vers -productVersion 2>/dev/null)
version_major=${mac_version%%.*}
if is_supported_macos_version "$mac_version"; then
    pass "macOS version meets the remote-access route minimum"
elif [ -n "$mac_version" ] && [ -n "$version_major" ] && \
    ! printf '%s\n' "$version_major" | grep '[^0-9]' >/dev/null 2>&1; then
    warn "macOS is older than the current route minimum; use phase 01 before installing remote-access clients"
else
    fail "macOS version is unavailable or could not be classified"
    exit 1
fi

architecture=$(uname -m 2>/dev/null)
case "$architecture" in
    arm64|x86_64) pass "supported architecture detected: $architecture" ;;
    *) warn "unrecognized architecture; verify compatibility manually" ;;
esac

if [ "$architecture" = "x86_64" ]; then
    warn "remote-access phases can continue, but phase 09 does not offer a new Homebrew installation for Intel"
elif [ "$architecture" = "arm64" ]; then
    if [ "$version_major" -lt 15 ]; then
        warn "the current Homebrew-backed development phase requires macOS 15 or later"
    fi
fi

model_name=$(LC_ALL=C /usr/sbin/system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Model Name/ { print $2; exit }')
if is_mac_mini "$model_name"; then
    pass "target hardware is identified as Mac mini"
else
    fail "target hardware is not identified as Mac mini"
    exit 1
fi

group_list=" $(id -Gn 2>/dev/null) "
case "$group_list" in
    *" admin "*) pass "current account has administrator membership" ;;
    *) warn "current account is not an administrator; keep an administrator available for manual approvals" ;;
esac

available_kb=$(df -Pk / 2>/dev/null | awk 'NR == 2 { print $4 }')
case "$available_kb" in
    ''|*[!0-9]*) warn "free disk space could not be measured" ;;
    *)
        available_gb=$((available_kb / 1024 / 1024))
        if [ "$available_gb" -lt 20 ]; then
            warn "less than 20 GB is free; review storage before installing development tools"
        else
            pass "at least 20 GB of free disk space is available"
        fi
        ;;
esac

for tool_name in git gh brew node npm python3 codex claude; do
    if have_command "$tool_name"; then
        pass "$tool_name is already available"
    else
        warn "$tool_name is not available yet"
    fi
done

if have_command tailscale; then
    pass "Tailscale CLI is already available"
elif [ -d /Applications/Tailscale.app ] || [ -d "$HOME/Applications/Tailscale.app" ]; then
    pass "Tailscale app is installed; CLI integration is not in PATH"
else
    warn "Tailscale is not installed yet"
fi

if [ -d /Applications/AnyDesk.app ] || [ -d "$HOME/Applications/AnyDesk.app" ]; then
    pass "AnyDesk is installed"
else
    warn "AnyDesk is not installed yet"
fi

exit 0
