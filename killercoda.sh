#!/usr/bin/env bash
# Usage, as root on Killercoda's Ubuntu playground:
#   curl -fsSL https://raw.githubusercontent.com/clbrge/spore-codespace-probe/main/killercoda.sh | bash 2>&1 | tee probe-output.txt

step () { printf '\n=== %s\n' "$*"; "$@"; echo "--- exit $?"; }

step uname -r
step cat /etc/os-release
step cat /sys/kernel/security/lsm
step cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns
step systemd-detect-virt
step grep -E 'Seccomp|CapEff' /proc/self/status
step ls -l /.dockerenv
step id

tarball=$(curl -fsSL https://nodejs.org/dist/latest-v24.x/SHASUMS256.txt | awk '/linux-x64\.tar\.xz$/ {print $2}')
step bash -c "curl -fsSL https://nodejs.org/dist/latest-v24.x/$tarball | tar -xJ -C /opt"
ln -sfn "/opt/${tarball%.tar.xz}" /opt/node
step useradd -m -s /bin/bash probe

cat > /home/probe/probe-user.sh <<'EOF'
step () { printf '\n=== %s\n' "$*"; "$@"; echo "--- exit $?"; }
export PATH="$HOME/.npm-global/bin:/opt/node/bin:$PATH"
step id
step node --version
step unshare -Ur true
step npm config set prefix "$HOME/.npm-global"
step npm install -g @rhizogrip/spore-cli
step spore doctor --report
EOF
chown probe: /home/probe/probe-user.sh

printf '\n##### as user probe, machine as Killercoda gives it\n'
su - probe -c 'bash ~/probe-user.sh'

printf '\n##### as user probe, after an AppArmor profile for confine alone\n'
confine=$(find /home/probe/.npm-global/lib/node_modules/@rhizogrip -path '*/native/x64/confine' -type f | head -1)
step echo "confine: $confine"
printf 'abi <abi/4.0>,\ninclude <tunables/global>\nprofile spore-confine "%s" flags=(unconfined) {\n  userns,\n}\n' "$confine" > /etc/apparmor.d/spore-confine
step cat /etc/apparmor.d/spore-confine
step apparmor_parser -r /etc/apparmor.d/spore-confine
step cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns
su - probe -c 'export PATH="$HOME/.npm-global/bin:/opt/node/bin:$PATH"; unshare -Ur true; echo "--- plain unshare exit $? (should fail: only confine is allowed)"; spore doctor --report'
