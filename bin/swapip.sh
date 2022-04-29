#!/bin/bash

# switch between dhcp and manual ip via systemd-networkd config files

usage() {	
	cat <<-USAGE
	usage:
	$0 -D	apply a dhcp configuration to "$dev"
	$0 -M	apply a manual ip configuration to "$dev"
	$0 -h	show this usage summary
	USAGE
}


declare ip dev mode testrun
dev='eth0'
ip="$(ip address show dev eth0 | sed -n -E 's/.*inet\s(([0-9]{1,3}[\.]){3}[0-9]{1,3}\/[0-9]{1,2}).*/\1/p')"
# set simple vars
manipsrc='/home/otherside/dev/Config/System/network/15-ETHERNET_MANIP.conf'
manipdest='/etc/systemd/network/15-ETHERNET.network.d/15-ETHERNET_MANIP.conf'

while getopts 'hdDM' opt; do
	case "$opt" in
		D) mode='DHCP' ;;
		M) mode='Manual_IP' ;;
		h) 
			usage
			exit 0 
			;;
		*) 
			printf '%s\n\n' "error: invalid option on line $lineno"
			usage
			exit 1
			;;
	esac
done

[[ -z "$mode" ]] && { usage; exit 0; }

if [[ "$(id -u)" -ne 0 ]]; then
	printf '%s\n\n' 'This script must be ran as root'
	exit 1
fi

printf 'This will apply %s mode, ok?\n' "$mode"
select continue in Continue Exit; do
	if [[ "$REPLY" = 'Exit' ]]; then
		printf '%s\n\n' 'Exiting'
	else
		break
	fi
done

if [[ -z "$ip" ]]; then
	printf '%s\n\n' 'WARNING: Could not identify ip address'
fi

printf 'Current IP:%s\n' "$ip"
printf 'Device %s\n\n' "$dev"

if [[ -n "$ip" ]]; then
	printf '%s\n\n' 'deleting current ip'
	ip address delete "$ip" dev "$dev"
fi

printf '%s\n\n' 'stopping systemd-networkd.service'
systemctl stop systemd-networkd.service

# printf '%s\n\n' 'disabling network adapters'
# find /sys/class/net/ -type l -printf '%p\0' | 
# xargs -0 -i % -t ip link set % down

if [[ "$mode" = 'DHCP' ]]; then
	printf '%s\n\n' 'transitioning to dhcp mode'
	if [[ ! -f "$manipdest" ]]; then 
		link "$manipsrc" "$manipdest" && \
			printf '%s\n\n' 'sucessfully linked manual ip dropin' ||\
			printf '%s\n\n' 'error: failed to link manual ip dropin'
	else
		printf '%s\n\n' 'manual ip dropin already exists'
	fi
elif [[ "$mode" = 'Manual_IP' ]]; then
	printf '%s\n\n' 'transitioning to manual ip mode'
	if [[ -f "$manipdest" ]]; then
		unlink "$manipdest"
		[[ ! -f "$manipdest" ]] && \
			printf '%s\n\n' 'sucessfully removed manual ip dropin' || \
			printf '%s\n\n' 'error: failed to remove mauail ip dropin'
	else
		printf '%s\n\n' 'manual ip dropin is not present'
	fi
else
	printf 'mode %s does not exist\n\n' "$mode"
	exit 1
fi

# printf '%s\n\n' 'enabling network adapters'
# find /sys/class/net/ -type l -printf '%p\0' | 
# xargs -0 -i % -t ip link set % up && sleep 3

sleep 3

printf '%s\n\n' 'enabling systemd-networkd.service'
systemctl start systemd-networkd.service && sleep 3

# printf '%s\n\n' 'deleting current ip'
# if [[ -n "$ip" ]]; then:q

# 	ip address delete "$ip" dev "$dev" && sleep 3
# fi

printf '%s\n\n' 'reloading network configuration'
networkctl reload && sleep 3

if [[ "$mode" = 'DHCP' ]]; then
	printf '%s\n\n' 'renewing ip address'
	networkctl renew "$dev" && { printf 'ip address status:'; ip address show dev "$dev"; }
fi

printf '%s\n\n' 'contents of dhcp => manual ip dropin folder:'
ls -1 --color=always "${manipdest%/*}" && sleep 3


unset ip

