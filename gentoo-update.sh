#!/bin/bash

set -e

BASE_VM=1001

# Lets first update the base vm
if [[ -z $(vzlist -1 | grep ${BASE_VM}) ]]; then
    vzctl start ${BASE_VM}
    sleep 3
fi

vzctl exec2 ${BASE_VM} "emerge --sync"
vzctl enter ${BASE_VM} --exec "python-updater -- --ask && exit 0 || exit 1"
vzctl enter ${BASE_VM} --exec "emerge -uvaDN @world && exit 0 || exit 1"
vzctl enter ${BASE_VM} --exec "perl-cleaner --all -- --ask && exit 0 || exit 1"
vzctl enter ${BASE_VM} --exec "emerge -uvaDN @world --with-bdeps=y && exit 0 || exit 1"
vzctl enter ${BASE_VM} --exec "etc-update && exit 0 || exit 1"
vzctl enter ${BASE_VM}
vzctl exec2 ${BASE_VM} "emerge -vc"
vzctl stop ${BASE_VM}
vzctl mount ${BASE_VM}
sleep 5


if [[ -f /vz/template/cache/gentoo-x86_64.tar.gz ]]; then
    mv /vz/template/cache/gentoo-x86_64{,-"$(date -u +%s)"}.tar.gz
fi

tar \
	--numeric-owner \
	--create \
	--verbose \
	--gzip \
	--file /vz/template/cache/gentoo-x86_64.tar.gz \
	--directory /vz/root/${BASE_VM}/ \
	--exclude='./usr/portage/*' \
	--exclude='./var/log/emerge*.log' \
	--exclude='./var/log/messages' \
	--exclude='./var/log/rc.log' \
	--exclude='./var/log/wtmp' \
	--exclude='./var/log/portage/' \
	--exclude='./var/log/*.gz' \
	--exclude='./var/tmp/portage/*' \
	--exclude='./root/.screen/' \
	--exclude='./root/.bash_history' \
	--exclude='./root/.vim/' \
	--exclude='./root/.viminfo' \
	--exclude='./home/*/.screen/'\
	--exclude='./home/*/.bash_history' \
	--exclude='./home/*/.vim/' \
	--exclude='./home/*/.viminfo' \
	--exclude='./etc/ssh/ssh_host_*' \
	--exclude='./fastboot' \
	.
sleep 5

vzctl umount ${BASE_VM}

for ctid in $(vzlist -a -1 | grep -v ${BASE_VM}); do
    if [[ -z $(vzlist -1 | grep $ctid) ]]; then
        vzctl start $ctid
        sleep 3
    fi
    vzctl exec2 $ctid "[[ -d /usr/portage ]]" || continue
    vzctl enter $ctid --exec "python-updater -- --ask --getbinpkg && exit 0 || exit 1"
    vzctl enter $ctid --exec "emerge -uvagDN @world && exit 0 || exit 1"
    vzctl enter $ctid --exec "perl-cleaner --all -- --ask --getbinpkg && exit 0 || exit 1"
    vzctl enter $ctid --exec "emerge -uvagDN @world --with-bdeps=y && exit 0 || exit 1"
    vzctl enter $ctid --exec "etc-update && exit 0 || exit 1"
    vzctl exec2 $ctid "emerge -vc"
    vzctl exec2 $ctid "eix-update"
    vzctl enter $ctid
done
