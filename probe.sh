#!/usr/bin/env bash
# Usage: bash probe.sh 2>&1 | tee probe-output.txt

step () { printf '\n=== %s\n' "$*"; "$@"; echo "--- exit $?"; }

step uname -r
step cat /sys/kernel/security/lsm
step cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns
step grep -E 'Seccomp|CapEff' /proc/self/status
step id
step bash -c "env | grep -E '^(CODESPACES|GITHUB_CODESPACE)' | cut -d= -f1"
step ls -l /.dockerenv
step bash -c 'command -v systemd-detect-virt'
step unshare -Ur true
step npm install -g @rhizogrip/spore-cli
step spore doctor --report
