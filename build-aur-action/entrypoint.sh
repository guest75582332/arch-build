#!/bin/bash

set -euo pipefail

pkgname=$1

useradd builder -m
echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
chmod -R a+rw .

pacman-key --init
pacman-key --recv-key 3056513887B78AEB
pacman-key --lsign-key 3056513887B78AEB
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

cat << EOM >> /etc/pacman.conf
[archlinuxcn]
Server = https://repo.archlinuxcn.org/x86_64
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOM

pacman -Syu --noconfirm archlinuxcn-keyring && pacman -Syu --noconfirm archlinux-keyring yay

if [ ! -z "$INPUT_PREINSTALLPKGS" ]; then
    read -r -a preinstall_pkgs <<< "$INPUT_PREINSTALLPKGS"
    pacman -S --noconfirm "${preinstall_pkgs[@]}"
fi

if [[ "$pkgname" == "systemd-cron" ]]; then
    sudo --set-home -u builder yay -S --noconfirm --builddir=./ "aur/$pkgname"
else
    sudo --set-home -u builder yay -S --noconfirm --builddir=./ "$pkgname"
fi

# Find the actual build directory (pkgbase) created by yay.
# Some AUR packages use a different pkgbase directory name,
# e.g. otf-space-grotesk has a pkgbase 38c3-styles, 
# when using yay -S otf-space-grotesk, it's built under folder 38c3-styles.
function get_pkgbase(){
  local pkg="$1"
  url="https://aur.archlinux.org/rpc/?v=5&type=info&arg=${pkg}"
  resp="$(curl -sS "$url")"
  pkgbase="$(printf '%s' "$resp" | jq -r '.results[0].PackageBase // .results[0].Name')"
  echo "$pkgbase"
}

if [[ -d "$pkgname" ]];
  then
    pkgdir="$pkgname"
  else
    pacman -S --needed --noconfirm jq
    pkgdir="$(get_pkgbase "$pkgname")"
fi

echo "The pkgdir is $pkgdir"
echo "The pkgname is $pkgname"
cd "$pkgdir"
python3 ../build-aur-action/encode_name.py
