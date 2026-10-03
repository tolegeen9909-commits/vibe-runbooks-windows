#!/bin/bash
set -e

TESTS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MAC_RUNBOOK_ROOT=$(CDPATH= cd -- "$TESTS_DIR/.." && pwd)
REPO_ROOT=$(CDPATH= cd -- "$MAC_RUNBOOK_ROOT/.." && pwd)

pass_count=0
fail_count=0

ok() {
    pass_count=$((pass_count + 1))
    printf 'PASS: %s\n' "$1"
}

not_ok() {
    fail_count=$((fail_count + 1))
    printf 'FAIL: %s\n' "$1"
}

expect_code() {
    expected_code=$1
    label=$2
    shift 2

    set +e
    command_output=$("$@" 2>&1)
    actual_code=$?
    set -e

    if [ "$actual_code" -eq "$expected_code" ]; then
        ok "$label"
    else
        not_ok "$label returned $actual_code instead of $expected_code"
        printf '%s\n' "$command_output"
    fi
}

required_files="
AGENTS.md
FOR-CODEX.md
RITUALS.md
INDEX.md
runbook.md
SOURCES.md
TROUBLESHOOTING.md
scripts/lib.sh
scripts/record-checkpoint.sh
state/progress-template.json
00-preflight/runbook.md
00-preflight/check-system.sh
01-macos-update/runbook.md
02-power-24x7/runbook.md
02-power-24x7/verify.sh
03-ssh-termius/runbook.md
03-ssh-termius/verify.sh
04-anydesk/runbook.md
04-anydesk/verify.sh
05-tailscale/runbook.md
05-tailscale/verify.sh
06-recovery-security/runbook.md
06-recovery-security/verify.sh
07-reboot-checkpoint/runbook.md
08-power-loss-headless/runbook.md
09-development/runbook.md
09-development/verify.sh
10-final-checkpoint/runbook.md
10-final-checkpoint/self-check.sh
tests/route.sh
"

printf '%s\n' "$required_files" | while IFS= read -r relative_path; do
    if [ -z "$relative_path" ]; then
        continue
    fi
    if [ ! -f "$MAC_RUNBOOK_ROOT/$relative_path" ]; then
        printf 'FAIL: missing required file %s\n' "$relative_path"
        exit 1
    fi
done
ok "required Mac route files exist"

syntax_failed=0
while IFS= read -r shell_file; do
    if ! bash -n "$shell_file"; then
        syntax_failed=1
    fi
done <<EOF
$(find "$MAC_RUNBOOK_ROOT" -type f -name '*.sh' -print)
EOF
if [ "$syntax_failed" -eq 0 ]; then
    ok "all Mac shell files parse with Bash"
else
    not_ok "one or more Mac shell files have syntax errors"
fi

if python3 -m json.tool "$MAC_RUNBOOK_ROOT/state/progress-template.json" >/dev/null && \
    plutil -convert json -o /dev/null "$MAC_RUNBOOK_ROOT/state/progress-template.json" >/dev/null; then
    ok "progress template is valid JSON"
else
    not_ok "progress template is invalid"
fi

unsafe_script=0
while IFS= read -r shell_file; do
    if grep -E '(^|[[:space:]])sudo([[:space:]]|$)|(^|[[:space:]])(curl|wget)([[:space:]]|$)|(^|[[:space:]])brew[[:space:]]+(install|upgrade|uninstall)|(^|[[:space:]])defaults[[:space:]]+(write|delete)|(^|[[:space:]])softwareupdate.*([[:space:]]-i|--install)|(^|[[:space:]])installer[[:space:]]+-pkg|(^|[[:space:]])fdesetup[[:space:]]+(enable|disable)|(^|[[:space:]])systemsetup([[:space:]]|$)|(^|[[:space:]])launchctl[[:space:]]+(load|bootstrap|enable)|(^|[[:space:]])scutil[[:space:]]+--set|(^|[[:space:]])tailscale[[:space:]]+(up|login|set|logout)|(^|[[:space:]])pmset[[:space:]]+(-[abcu][[:space:]]|repeat|schedule)|(^|[[:space:]])open[[:space:]]+https?://' "$shell_file" >/dev/null 2>&1; then
        printf 'FAIL: mutating or opaque command found in %s\n' "$shell_file"
        unsafe_script=1
    fi
done <<EOF
$(find "$MAC_RUNBOOK_ROOT" -type f -name '*.sh' ! -path '*/tests/*' -print)
EOF
if [ "$unsafe_script" -eq 0 ]; then
    ok "Mac scripts contain no network, install, privilege, or system-setting mutation"
else
    not_ok "Mac script safety invariant failed"
fi

if grep -R --exclude='route.sh' -E -i '10\.[0-9]+\.[0-9]+\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+|192\.168\.[0-9]+\.[0-9]+|100\.[0-9]+\.[0-9]+\.[0-9]+|(^|[^[:xdigit:]])(fc|fd)[[:xdigit:]]{2}:|(^|[^[:xdigit:]])fe80:|[0-9]{9,10}' "$MAC_RUNBOOK_ROOT" >/dev/null 2>&1; then
    not_ok "Mac route contains a concrete private IP or ID-like number"
else
    ok "Mac route contains no concrete private IP or AnyDesk-like ID"
fi

if grep -R --exclude='route.sh' -E 'BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY|sk-[A-Za-z0-9_-]{16,}' "$MAC_RUNBOOK_ROOT" >/dev/null 2>&1; then
    not_ok "Mac route contains secret-like material"
else
    ok "Mac route contains no obvious private key or API key"
fi

fixture_scripts="
00-preflight/check-system.sh
02-power-24x7/verify.sh
03-ssh-termius/verify.sh
04-anydesk/verify.sh
05-tailscale/verify.sh
06-recovery-security/verify.sh
09-development/verify.sh
10-final-checkpoint/self-check.sh
"

printf '%s\n' "$fixture_scripts" | while IFS= read -r relative_path; do
    if [ -z "$relative_path" ]; then
        continue
    fi
    script_path="$MAC_RUNBOOK_ROOT/$relative_path"
    bash "$script_path" --self-test-pass >/dev/null
    fail_code=0
    bash "$script_path" --self-test-fail >/dev/null 2>&1 || fail_code=$?
    if [ "$fail_code" -ne 1 ]; then
        printf 'FAIL: %s fail fixture returned %s\n' "$relative_path" "$fail_code"
        exit 1
    fi
    manual_code=0
    bash "$script_path" --self-test-manual >/dev/null 2>&1 || manual_code=$?
    if [ "$manual_code" -ne 2 ]; then
        printf 'FAIL: %s manual fixture returned %s\n' "$relative_path" "$manual_code"
        exit 1
    fi
done
ok "all verifier fixtures distinguish PASS, FAIL, and MANUAL"

for probe_script in \
    00-preflight/check-system.sh \
    02-power-24x7/verify.sh \
    04-anydesk/verify.sh \
    05-tailscale/verify.sh \
    06-recovery-security/verify.sh \
    09-development/verify.sh
do
    if bash "$MAC_RUNBOOK_ROOT/$probe_script" --self-test-probes >/dev/null; then
        ok "$probe_script parser probes"
    else
        not_ok "$probe_script parser probes"
    fi
done

temp_root=$(mktemp -d /private/tmp/mac-mini-runbook.XXXXXX)
cleanup() {
    case "$temp_root" in
        /private/tmp/mac-mini-runbook.*|/tmp/mac-mini-runbook.*)
            rm -rf -- "$temp_root"
            ;;
    esac
}
trap cleanup EXIT

test_state="$temp_root/progress.json"
record_script="$MAC_RUNBOOK_ROOT/scripts/record-checkpoint.sh"

early_state="$temp_root/early-progress.json"
env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$early_state" \
    bash "$record_script" mode secure >/dev/null
expect_code 1 "final marker rejects missing prerequisite evidence" \
    env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$early_state" \
    bash "$record_script" step 10-final-checkpoint:secure-ready

normalized_state="$temp_root/normalized-progress.json"
cp "$MAC_RUNBOOK_ROOT/state/progress-template.json" "$normalized_state"
plutil -insert notes -string forbidden "$normalized_state"
plutil -insert manualChecks.rogue-check -bool true "$normalized_state"
env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$normalized_state" \
    bash "$record_script" mode secure >/dev/null
if plutil -extract notes raw -o - "$normalized_state" >/dev/null 2>&1 || \
    plutil -extract manualChecks.rogue-check raw -o - "$normalized_state" >/dev/null 2>&1; then
    not_ok "checkpoint writer retained non-schema fields"
else
    ok "checkpoint writer normalizes non-schema fields"
fi

wrong_route_state="$temp_root/wrong-route-progress.json"
cp "$MAC_RUNBOOK_ROOT/state/progress-template.json" "$wrong_route_state"
plutil -replace route -string windows "$wrong_route_state"
expect_code 1 "checkpoint rejects a mismatched route" \
    env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$wrong_route_state" \
    bash "$record_script" mode secure

missing_mode_state="$temp_root/missing-mode-progress.json"
expect_code 1 "recovery step requires a selected mode" \
    env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$missing_mode_state" \
    bash "$record_script" step 06-recovery-security:verified
expect_code 1 "mode-dependent manual proof requires a selected mode" \
    env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$missing_mode_state" \
    bash "$record_script" manual lock-recovery

orphaned_evidence_state="$temp_root/orphaned-evidence-progress.json"
cp "$MAC_RUNBOOK_ROOT/state/progress-template.json" "$orphaned_evidence_state"
plutil -insert completedSteps.0 -string 06-recovery-security:verified "$orphaned_evidence_state"
expect_code 1 "mode selection rejects orphaned recovery evidence" \
    env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$orphaned_evidence_state" \
    bash "$record_script" mode secure

expect_code 1 "checkpoint rejects an unknown marker" \
    env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$test_state" \
    bash "$record_script" step not-allowlisted

env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$test_state" \
    bash "$record_script" mode secure >/dev/null

for step_id in \
    00-preflight:verified \
    01-macos-update:verified \
    02-power-24x7:verified \
    03-ssh-termius:verified \
    04-anydesk:verified \
    05-tailscale:verified \
    06-recovery-security:verified \
    07-reboot-checkpoint:verified \
    08-power-loss-headless:verified \
    09-development:verified
do
    env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$test_state" \
        bash "$record_script" step "$step_id" >/dev/null
done

step_count_before=$(plutil -extract completedSteps raw -o - "$test_state")
env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$test_state" \
    bash "$record_script" step 00-preflight:verified >/dev/null
step_count_after=$(plutil -extract completedSteps raw -o - "$test_state")
if [ "$step_count_before" = "$step_count_after" ]; then
    ok "duplicate checkpoint writes are idempotent"
else
    not_ok "duplicate checkpoint created a second marker"
fi

for manual_id in \
    ssh-lan \
    termius-lan \
    anydesk-view \
    anydesk-control \
    anydesk-unattended \
    anydesk-hardened \
    tailscale-peers \
    ssh-over-tailscale \
    lock-recovery \
    logout-recovery \
    reboot-tailscale \
    reboot-ssh \
    reboot-anydesk \
    power-startup \
    power-remote-access \
    headless-access
do
    env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$test_state" \
        bash "$record_script" manual "$manual_id" >/dev/null
done

expect_code 0 "secure readiness is computed from evidence" \
    env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$test_state" \
    bash "$MAC_RUNBOOK_ROOT/10-final-checkpoint/self-check.sh"

expect_code 1 "final marker must match selected mode" \
    env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$test_state" \
    bash "$record_script" step 10-final-checkpoint:autonomous-ready

env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$test_state" \
    bash "$record_script" step 10-final-checkpoint:secure-ready >/dev/null
expect_code 1 "mode change cannot reuse completed recovery evidence" \
    env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$test_state" \
    bash "$record_script" mode autonomous

autonomous_state="$temp_root/autonomous-progress.json"
env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$autonomous_state" \
    bash "$record_script" mode autonomous >/dev/null

for step_id in \
    00-preflight:verified \
    01-macos-update:verified \
    02-power-24x7:verified \
    03-ssh-termius:verified \
    04-anydesk:verified \
    05-tailscale:verified \
    06-recovery-security:verified \
    07-reboot-checkpoint:verified \
    08-power-loss-headless:verified \
    09-development:verified
do
    env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$autonomous_state" \
        bash "$record_script" step "$step_id" >/dev/null
done

for manual_id in \
    ssh-lan \
    termius-lan \
    anydesk-view \
    anydesk-control \
    anydesk-unattended \
    anydesk-hardened \
    tailscale-peers \
    ssh-over-tailscale \
    lock-recovery \
    logout-recovery \
    reboot-tailscale \
    reboot-ssh \
    reboot-anydesk \
    power-startup \
    power-remote-access \
    headless-access
do
    env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$autonomous_state" \
        bash "$record_script" manual "$manual_id" >/dev/null
done

expect_code 0 "autonomous readiness uses complete independent evidence" \
    env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$autonomous_state" \
    bash "$MAC_RUNBOOK_ROOT/10-final-checkpoint/self-check.sh"
env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$autonomous_state" \
    bash "$record_script" step 10-final-checkpoint:autonomous-ready >/dev/null
expect_code 0 "matching autonomous final marker remains valid" \
    env MAC_RUNBOOK_TEST_MODE=1 MAC_RUNBOOK_STATE_FILE="$autonomous_state" \
    bash "$MAC_RUNBOOK_ROOT/10-final-checkpoint/self-check.sh"

if [ "$fail_count" -gt 0 ]; then
    printf 'FAIL: %s route checks failed\n' "$fail_count"
    exit 1
fi

printf 'PASS: %s route checks completed\n' "$pass_count"
