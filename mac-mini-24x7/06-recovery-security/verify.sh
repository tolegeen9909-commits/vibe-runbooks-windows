#!/bin/bash

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MAC_RUNBOOK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
. "$MAC_RUNBOOK_ROOT/scripts/lib.sh"

classify_filevault_status() {
    case "$1" in
        *"Encryption in progress"*|*"Decryption in progress"*|*"Deferred enablement"*|*"Deferred disablement"*)
            printf 'transitioning\n'
            ;;
        *"FileVault is On"*) printf 'on\n' ;;
        *"FileVault is Off"*) printf 'off\n' ;;
        *) printf 'unknown\n' ;;
    esac
}

if [ "$1" = "--self-test-probes" ]; then
    [ "$(classify_filevault_status 'FileVault is On.')" = "on" ] && \
        [ "$(classify_filevault_status 'FileVault is Off.')" = "off" ] && \
        [ "$(classify_filevault_status 'FileVault is On. Encryption in progress: Percent completed = 50')" = "transitioning" ] && \
        [ "$(classify_filevault_status 'FileVault is Off. Decryption in progress: Percent completed = 50')" = "transitioning" ] && \
        [ "$(classify_filevault_status 'unclassified')" = "unknown" ]
    exit $?
fi

fixture_result "$1"
fixture_code=$?
if [ "$fixture_code" -ne 64 ]; then
    exit "$fixture_code"
fi

check_failed=0
check_manual=0

autorestart_value=$(pmset -g custom 2>/dev/null | awk '$1 == "autorestart" { print $2; exit }')
case "$autorestart_value" in
    1)
        pass "automatic restart after a power loss is enabled"
        ;;
    0)
        fail "automatic restart after a power loss is disabled"
        check_failed=1
        ;;
    *)
        manual "automatic restart state could not be classified"
        check_manual=1
        ;;
esac

filevault_state=$(LC_ALL=C fdesetup status 2>/dev/null)
filevault_class=$(classify_filevault_status "$filevault_state")
case "$filevault_class" in
    on)
        filevault_on=1
        pass "FileVault is enabled"
        ;;
    off)
        filevault_on=0
        warn "FileVault is disabled"
        ;;
    transitioning)
        manual "FileVault encryption or decryption is still in progress"
        check_manual=1
        filevault_on=transitioning
        ;;
    *)
        manual "FileVault state could not be classified"
        check_manual=1
        filevault_on=unknown
        ;;
esac

if defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser >/dev/null 2>&1; then
    automatic_login=1
    warn "automatic login is enabled"
else
    automatic_login=0
    pass "automatic login is disabled"
fi

selected_mode=$(state_mode 2>/dev/null)
if [ "$selected_mode" != "secure" ] && [ "$selected_mode" != "autonomous" ]; then
    manual "choose secure or autonomous mode after reviewing the current state"
    if [ "$check_failed" -gt 0 ]; then
        exit 1
    fi
    exit 2
fi

if [ "$selected_mode" = "secure" ]; then
    case "$filevault_on" in
        1)
            pass "FileVault remains enabled"
            ;;
        0)
            fail "secure mode requires FileVault to remain enabled"
            check_failed=1
            ;;
        *)
            manual "secure mode cannot be verified until FileVault state is readable"
            check_manual=1
            ;;
    esac
    if [ "$automatic_login" -eq 0 ]; then
        pass "automatic login is disabled"
    else
        fail "secure mode requires automatic login to stay disabled"
        check_failed=1
    fi
else
    if [ "$filevault_on" = "0" ] && [ "$automatic_login" -eq 1 ]; then
        pass "autonomous login prerequisites are visible"
    else
        manual "autonomous recovery is not proven by the current FileVault and login state"
        check_manual=1
    fi
fi

if [ "$check_failed" -gt 0 ]; then
    exit 1
fi
if [ "$check_manual" -gt 0 ]; then
    exit 2
fi
exit 0
