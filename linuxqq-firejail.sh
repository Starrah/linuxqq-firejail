#!/bin/sh

launcher="/usr/share/applications/qq.desktop"
patched_marker="# This file has been PATCHED by linuxqq-firejail! (https://github.com/Starrah/linuxqq-firejail)"
flatpak_xdg_utils_dir=""

grep -q "${patched_marker}" "${launcher}"
if [ $? -eq 0 ]; then
    echo "${launcher}" "had already been patched, so whe script will not patched it again."
    return 1
fi

flatpak_xdg_utils_dir="/usr/lib/flatpak-xdg-utils"
if [ ! -d "${flatpak_xdg_utils_dir}" ]; then
    flatpak_xdg_utils_dir="/usr/lib/flatpak-xdg-utils" # try default path 1 (Arch)
fi
if [ ! -d "${flatpak_xdg_utils_dir}" ]; then
    flatpak_xdg_utils_dir="/usr/libexec/flatpak-xdg-utils" # try default path 2 (Ubuntu)
fi
if [ ! -d "${flatpak_xdg_utils_dir}" ]; then
    flatpak_xdg_utils_dir=""
    echo "Cannot find the path for flatpak-xdg-utils. Please specify the path manually by editing the variable \"flatpak_xdg_utils_dir\" at the beginning of this script."
    return 1
fi

set -e

echo "  -> Adding dummy jsbridge handler..."
mkdir "/usr/share/mime/packages/" -p
cp $(dirname "$0")"/jsbridge-dummy.desktop" "/usr/share/applications/"
cp $(dirname "$0")"/jsbridge-dummy.xml" "/usr/share/mime/packages/"

echo "  -> Wrapping launcher..."
cp "${launcher}" "${launcher}".backup
sed -i "2s!QQ!QQ in Firejail!" "${launcher}"
sed -i "\$a""${patched_marker}" "${launcher}"
sed -i "3s!Exec=!Exec=sh -c \"env PATH=""${flatpak_xdg_utils_dir}"":\$PATH env IBUS_USE_PORTAL=1 firejail --private-bin=linuxqq,xdg-open,xdg-mime,bash !" "${launcher}"
sed -i "3s!%U!\"%U!" "${launcher}"
# rm "${launcher}".backup

echo "  -> Updating desktop and MIME database..."
update-desktop-database -q
update-mime-database /usr/share/mime

echo "Success! Now linuxqq will be restricted by firejail when you run from the desktop file (eg. from the start menu)!"

