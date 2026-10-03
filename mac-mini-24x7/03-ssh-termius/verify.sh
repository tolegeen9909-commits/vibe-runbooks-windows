#!/bin/bash

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MAC_RUNBOOK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
. "$MAC_RUNBOOK_ROOT/scripts/lib.sh"

fixture_result "$1"
fixture_code=$?
if [ "$fixture_code" -ne 64 ]; then
    exit "$fixture_code"
fi

failures=0
manual_checks=0

if [ -x /usr/sbin/sshd ]; then
    pass "Apple SSH server is present"
else
    fail "Apple SSH server is unavailable"
    failures=$((failures + 1))
fi

if have_command nc && nc -z 127.0.0.1 22 >/dev/null 2>&1; then
    pass "SSH responds on the local loopback interface"
else
    fail "SSH does not respond locally; Remote Login may be off"
    failures=$((failures + 1))
fi

ssh_directory="$HOME/.ssh"
authorized_keys="$ssh_directory/authorized_keys"
current_user=$(id -un 2>/dev/null)
if [ -s "$authorized_keys" ] && [ ! -L "$authorized_keys" ]; then
    ssh_mode=$(stat -f '%Lp' "$ssh_directory" 2>/dev/null)
    key_mode=$(stat -f '%Lp' "$authorized_keys" 2>/dev/null)
    ssh_owner=$(stat -f '%Su' "$ssh_directory" 2>/dev/null)
    key_owner=$(stat -f '%Su' "$authorized_keys" 2>/dev/null)
    if [ "$ssh_mode" = "700" ] && [ "$key_mode" = "600" ] && \
        [ "$ssh_owner" = "$current_user" ] && [ "$key_owner" = "$current_user" ]; then
        pass "authorized SSH public keys have restrictive ownership and permissions"
    else
        fail "SSH key files need owner-only permissions and the current account as owner"
        failures=$((failures + 1))
    fi
else
    fail "no regular authorized SSH public key file was detected"
    failures=$((failures + 1))
fi

for manual_id in ssh-lan termius-lan; do
    if state_manual_true "$manual_id"; then
        pass "$manual_id was verified from the client"
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
