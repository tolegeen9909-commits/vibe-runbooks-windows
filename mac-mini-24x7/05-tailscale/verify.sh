#!/bin/bash

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MAC_RUNBOOK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
. "$MAC_RUNBOOK_ROOT/scripts/lib.sh"

evaluate_tailscale_runtime() {
    runtime_installed=$1
    runtime_online=$2

    if [ "$runtime_installed" -ne 1 ]; then
        fail "Tailscale is not installed"
        return 1
    fi
    pass "Tailscale is installed"

    if [ "$runtime_online" -ne 1 ]; then
        manual "Tailscale online status is not currently proven"
        return 2
    fi
    pass "Tailscale local online status is available"
    return 0
}

tailscale_status_is_online() {
    status_payload=$1
    backend_state=$(printf '%s' "$status_payload" | plutil -extract BackendState raw -o - - 2>/dev/null) || return 1
    self_online=$(printf '%s' "$status_payload" | plutil -extract Self.Online raw -o - - 2>/dev/null) || return 1

    [ "$backend_state" = "Running" ] && [ "$self_online" = "true" ]
}

if [ "$1" = "--self-test-probes" ]; then
    evaluate_tailscale_runtime 1 1 >/dev/null 2>&1 || exit 1
    probe_code=0
    evaluate_tailscale_runtime 0 0 >/dev/null 2>&1 || probe_code=$?
    [ "$probe_code" -eq 1 ] || exit 1
    probe_code=0
    evaluate_tailscale_runtime 1 0 >/dev/null 2>&1 || probe_code=$?
    [ "$probe_code" -eq 2 ] || exit 1

    tailscale_status_is_online '{"BackendState":"Running","Self":{"Online":true}}' || exit 1
    if tailscale_status_is_online '{"BackendState":"Stopped","Self":{"Online":true}}'; then
        exit 1
    fi
    if tailscale_status_is_online '{"BackendState":"NeedsLogin","Self":{"Online":false}}'; then
        exit 1
    fi
    if tailscale_status_is_online 'The Tailscale CLI failed to start: Failed to load preferences.'; then
        exit 1
    fi
    exit 0
fi

fixture_result "$1"
fixture_code=$?
if [ "$fixture_code" -ne 64 ]; then
    exit "$fixture_code"
fi

failures=0
manual_checks=0
tailscale_present=0
tailscale_online=0
tailscale_cli=

if have_command tailscale; then
    tailscale_present=1
    tailscale_cli=$(command -v tailscale)
elif [ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ]; then
    tailscale_present=1
    tailscale_cli=/Applications/Tailscale.app/Contents/MacOS/Tailscale
elif [ -x "$HOME/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]; then
    tailscale_present=1
    tailscale_cli="$HOME/Applications/Tailscale.app/Contents/MacOS/Tailscale"
elif [ -d /Applications/Tailscale.app ] || [ -d "$HOME/Applications/Tailscale.app" ]; then
    tailscale_present=1
fi

if [ -n "$tailscale_cli" ]; then
    tailscale_status=
    status_code=0
    tailscale_status=$(TAILSCALE_BE_CLI=1 "$tailscale_cli" status --json 2>/dev/null) || status_code=$?
    if [ "$status_code" -eq 0 ] && tailscale_status_is_online "$tailscale_status"; then
        tailscale_online=1
    fi
fi

runtime_code=0
evaluate_tailscale_runtime "$tailscale_present" "$tailscale_online" || runtime_code=$?
case "$runtime_code" in
    1) failures=$((failures + 1)) ;;
    2) manual_checks=$((manual_checks + 1)) ;;
esac

if [ "$runtime_code" -eq 1 ]; then
    exit 1
fi

for manual_id in tailscale-peers ssh-over-tailscale; do
    if state_manual_true "$manual_id"; then
        pass "$manual_id was verified from the Windows client"
    else
        manual "$manual_id still needs a client-side test"
        manual_checks=$((manual_checks + 1))
    fi
done

if [ "$failures" -gt 0 ]; then
    exit 1
fi
if [ "$manual_checks" -gt 0 ]; then
    exit 2
fi
exit 0
