#!/bin/sh

# This script is not in chroot yet, so need to resolve local directory.

CHROOT={{ _alias.chroot }}
ECHO={{ _alias.echo }}
GREP={{ _alias.grep }}
LS={{ _alias.ls }}
MKDIR={{ _alias.mkdir }}
MOUNT={{ _alias.mount }}
RM={{ _alias.rm }}

unset KRB5CCNAME
unset KRB5_KTNAME

for SVC in $($LS {{ dir }}/treadmill/init); do
    $GREP {{ dir }}/treadmill/init/$SVC/\$ {{ dir }}/.install > /dev/null
    if [ $? != 0 ]; then
        $ECHO Removing extra service: $SVC
        $RM -vrf {{ dir }}/treadmill/init/$SVC
    fi
done

$RM -vf {{ dir }}/treadmill/init/*/data/exits/*

# Look at ALL directories, e.g. .mslinks
for DIR in $(ls -a /); do
    # Ignore . and .. directories
    if [[ "${DIR}" != "." && "${DIR}" != ".." && -d /${DIR} ]]; then
        $MKDIR -p {{ dir }}/${DIR}
        $MOUNT -n --rbind /${DIR} {{ dir }}/${DIR}
    fi
done

# Cleanup all service exits information.
$RM -vf {{ dir }}/init/*/data/exits/*

# Do a one time generation of the host ticket before starting services. There
# will be a service in charge or keeping tickets refreshed (not the chroot).
{{ dir }}/treadmill/bin/host_tickets.sh -o {{ dir }}/treadmill/spool/krb5cc_host

cd {{ dir }}

# Starting svscan
export PATH={{ s6 }}/bin:$PATH
exec \
    ${CHROOT} {{ dir }} \
    {{ _alias.s6_envdir }} /treadmill/env \
    {{ _alias.s6_svscan }} /treadmill/init
