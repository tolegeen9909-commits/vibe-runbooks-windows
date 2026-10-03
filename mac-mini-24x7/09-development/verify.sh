#!/bin/bash

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MAC_RUNBOOK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
. "$MAC_RUNBOOK_ROOT/scripts/lib.sh"

development_platform_supported() {
    development_architecture=$1
    development_version=$2
    development_major=${development_version%%.*}
    case "$development_major" in
        ''|*[!0-9]*) return 1 ;;
    esac
    [ "$development_architecture" = "arm64" ] && [ "$development_major" -ge 15 ]
}

if [ "$1" = "--self-test-probes" ]; then
    development_platform_supported arm64 15.0 && \
        development_platform_supported arm64 26.0 && \
        ! development_platform_supported arm64 14.7 && \
        ! development_platform_supported x86_64 26.0
    exit $?
fi

fixture_result "$1"
fixture_code=$?
if [ "$fixture_code" -ne 64 ]; then
    exit "$fixture_code"
fi

if ! development_platform_supported "$(uname -m 2>/dev/null)" "$(sw_vers -productVersion 2>/dev/null)"; then
    fail "this development phase supports a new Homebrew setup only on Apple Silicon with macOS 15 or later"
    exit 1
fi

missing=0
for tool_name in brew git gh node npm python3 codex claude; do
    if have_command "$tool_name"; then
        pass "$tool_name is available"
    else
        fail "$tool_name is unavailable"
        missing=$((missing + 1))
    fi
done

if [ "$missing" -gt 0 ]; then
    exit 1
fi
exit 0
