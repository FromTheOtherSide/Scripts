#!/usr/bin/env bash 
################################################################################
# N: arch_installer.sh_______________                    ____________________  #
#=================|__  __ __  /___  /_______________________(_______  __|__  / #
# V: v.05         |_  / / _  ____  __ _  _ __  _____  _____  /_  __  /___/_ <  #
#=================|/ /_/ // /_ _  / / /  ___  /   _(__  )_  / / /_/ / ____/ /  #
# A:0thersid3     |\____/ \__/ /_/ /_/\___//_/    /____/ /_/  \__,_/  /____/   #
#==============================================================================#
# Description:                                                                 #
# Arch Linux installation script implementing:                                 #
# -btrfs files system                                                          #
# -systemd-boot                                                                #
# -hardware backed luks2 full disk encryption (less the efi partiton)          #
# -secure boot                                                                 #
# -systemd-homed                                                               #
# -                                                                            #
#                                                                              #
# Dependencies:                                                                #
# bash, coreutils, rsync                                                       #
#                                                                              #
################################################################################
###                               Error Handling                             ###
################################################################################
# This will cause commands like read and conditionals to error. 
set +e # Exit if any command returns a non-zero exit status. 
set +x # All executed commands are printed to the terminal.
set -u # All parameters must be defined including positional parameters!!
set -o pipefail # This can cause conditionals to error: x=0; echo $x && echo '1'
set -E # Enable err trap, call code when an error is detected

trap "Your shit broke nigga" ERR

# Settings
disk=/dev/sda # Assign the Kernel Device Descriptor i.e. /dev/sda 
distro='Arch Linux'
pretend=1
new_hostname='Adventure_Time'

################################################################################
###                                 Usage                                    ###
################################################################################
usage() {
  local usagetxt
  read -r -d '' usagetxt <<-USAGE 
  Usage: "$SCRIPT_NAME" -d distro [-s] [-C <ARG>] <FILE>
    distro : Distribution Name
    -s     : Simulated run
    -C     : Does something with ARG
    ARG    : Something
    FILE   : Something else
  USAGE
msg "$usagetxt" 
exit
}

################################################################################
###                               Dependencies                               ###
################################################################################
declare -a dependencies=(
  # /usr/bin/jq
 )

for dependency in "${dependencies[@]}"; do
  if [ ! -x "$dependency" ]; then
    echo "ERROR: Missing $dependency"
    exit 100
  fi
done


################################################################################
###                     COMMON VARIABLES & FUNCTIONS                         ###
################################################################################
readonly SCRIPT_NAME=$(/usr/bin/basename "${BASH_SOURCE[0]}")|| exit 100
readonly FULL_PATH=$(/usr/bin/realpath "${BASH_SOURCE[0]}")|| exit 100
readonly YYYYMMDD=$(/usr/bin/date '+%Y%m%d')|| exit 100
readonly TIMESTAMP="D${DATE}_$(/usr/bin/date '+%H%M')PST"|| exit 100

# Do not split on new spaces, split on new line and tab only
IFS=$'\n\t' # default=$' \t\n'

msg() {# usage msg <str> [r|b|g|p|n] [<qty \n before str>] [<qty \n after str>]
    local string=${1:-} clr=${2:-n} #prevent empty vars, req'd with set -u
    local -i nlbefore=${3:-0} nlafter=${4:-1} c=1
    local r='\e[31m' b='\e[34m' g='\e[32m' p='\e[35m' n='\e[0m' 
    for ((c=1;c<="$nlbefore";c++));do printf '%b' '\n';done 
    printf "%b%s%b" "${!clr}" "${string}" "${n}"
    for ((c=1;c<="$nlafter";c++));do printf '%b' '\n';done 
}

# Chose a file from a menu
yesno() {
  select opt in "yes" "no" "exit"
  do
    echo "You picked $REPLY"
    break;
  done
  [[ $REPLY = "cancel" ]] && echo exit 2
  [[ $REPLY = "no" ]] && msg "Rerunning $0" && "$0"
  [[ $REPLY = "yes" ]] $$ msg "Proceeding" 
}

################################################################################
###                            MAIN FUNCTIONS                                ###
################################################################################
backup_part() { 
	read -r usage<<-USAGE 
	Copies all data from a partiton to a backup directory in "$HOME/Backup/" 
	Usage: $0 part [ -restore ] 
	part #partition descriptor i.e. /dev/sda2 
	-r  # restore data from backup directory to the partition (using rsync diff) 
	USAGE

	local part={1:?usage} restore={2:=2} 
	[[ ! $val = '-r' ]] && restore=0 || restore=1 
	local desc="Backup/${disk//\/}" dir_bak="$HOME/$desc" dir_mnt="/mnt/$desc" 
	mkdir -p $dir_mnt $dir_bak mount $part $dir_mnt
  
	if [[ restore -eq 0 ]]; then 
		yesno "Backup" 
		rsync -archive --delete $dir_mnt $dir_bak 
		echo "Backup Success (Presumable?)"
	fi 
	if [[ restore -eq 1 ]]; then 
		yesno "Restore" 
		rsync -archive --delete $dir_bak $dir_mnt 
		echo "Restore Success (Presumable?)"	
	fi 
	umount $dir_mnt 
	rmdir $dir_mnt 
	sync && sleep 1 
}


# Set Console Keyboard Loadkeys 
set_time() {
	msg 'setting the clock on the fucking microwave again' 
	timedatectl set-ntp true
	timedatectl status
    hwclock --systohc
}


# Boot into Live USB & Verify EFI Boot Mode 
verify_efimode() {
    if [[ "$(/sys/firmware/efi/efivars | wc -w )" -gt 5 ]]; then
		msg "Using EFI Boot Mode" g
	else
		msg "Legacy Mode Detected,I'm out!" r
	    exit 2
	fi
}

Create_Partitions() {
    msg 'sorting partitons'
    sgdisk  $pretend --sort
    msg 'sorting complete' g

    msg 'creating partitions' p

	# Create Backup, Create, & Restore EFI Partition
	backup_efi 
	sgdisk $pretend \
        --new=0:0:+550M \
		--typecode=0:c12a7328-f81f-11d2-ba4b-00a0c93ec93b \
		--change-name=0:"${distro}-efi" $disk 
	sync && sleep 1 
	restore_efi
    msg 'efi part complete' g

	# Create / Partition
	sgdisk  $pretend \
        --new=0:0:+15G  \
		--typecode=0:4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709 \
		--change-name=0:"${distro}_root-crypt" $disk 
	sync && sleep 1
    msg 'root part complete' g


	# Create swap Partition
	sgdisk  $pretend \
        --new=0:0:+04G  \
		--typecode=0:0657fd6d-a4ab-43c4-84e5-0933c84b4f4f \
		--change-name=0:"${distro}_swap-crypt" $disk
	sync && sleep 1
    msg 'swap part complete' g


	# Create Home Partition
	sgdisk  $pretend \
        --new=0:0:+10G \
		--typecode=0:933AC7E1-2EB4-4F13-B844-0E14E2AEF915 \
		--change-name=0:"${distro}-home" $disk 
	sync && sleep 1 
    msg 'home part complete' g

}


# Encrypt File System Containers
encrypt() {
	# Create Encrypted Containers on Root and Swap, /home/[user] will be encrypted
	# by systemd-homed
    msg 'creating luks 2 container for root' 
	cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/${distro}_root-crypt 
    msg 'root cantainer complete' g

    msg 'creating luks 2 container for swap' 
	cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/${distro}_swap-crypt
    msg 'swap cantainer complete' g
}

# Format the Parttions
format() {
    msg 'applying fat32 filesystem to efi part' 
	mkfs.fat -F32   -n ${distro}_efi  /dev/disk/by-partlabel/${distro}-efi
    msg 'efi complete' g
    msg 'applying fat32 filesystem to efi part' 
	mkfs.btrfs 	-L ${distro}_root /dev/disk/by-partlabel/${distro}-root
    msg 'root complete' g
    msg 'applying fat32 filesystem to efi part' 
	mkfs.btrfs 	-L ${distro}_home /dev/disk/by-partlabel/${distro}-home
    msg 'home complete' g
    msg 'applying fat32 filesystem to efi part' 
	mkswap --check  -L ${distro}_swap /dev/disk/by-partlabel/${distro}-swap
    msg 'swap complete' g
}

mount(){
    msg 'Mounting partitions' 
    mkdir -p /mnt /mnt/boot /mnt/home
    mount /dev/mapper/${distro}_root /mnt
    mount /dev/mapper/${distro}_efi /mnt/boot
    mount /dev/mapper/${distro}_home /mnt/home
    swapon ${distro}_swap
    msg 'Mounting Complete' g
}   

base_install() {
    msg 'The following repo servers are configured,ok?' p
    cat /etc/pacman.d/mirrorlist
    yesno

    msg 'Strap up cowboys and cowgirls, youre goin in!' p
    arch-chroot /mnt

    msg 'Installing base system' p
    pacstrap /mnt base linux linux-firmware brtfs-progs \
        neovim intel-ucode dracut
    msg 'We got um' g
}

gen_locale(){
    msg 'Time for some local hood rat shit' b
    ln -sf /usr/share/zoneinfo/America/Los_Angeles /mnt/etc/localtime 
    sed -i -e '/^#en_US.UTF-8/s/^#//' /mnt/etc/locale.gen 
    echo 'LANG=en_US.UTF-8'>/mnt/etc/locale.conf 
    echo 'KEYMAP=us' >/mnt/etc/vconsole.conf
    echo "$new_hostname" >/mnt/etc/hostname
    locale-gen
    msg 'Hood rat shit complete' g
}

gen_init(){

    msg 'Generating initramfs and a big ass crowd'
    mkinitcpio -P
    msg '=^_^=' p
}

root(){
    systemctl enable systemd-homed 
    systemctl enable systemd-timesyncd 
    msg 'Finish your breakfast bitch' b
    passwd
    msg 'Now wash your face' g
}


pacman -S --noconfirm --asdeps binutils elfutils 
dracut -f --uefi --regenerate-all 
bootctl install

chattr +C /home/
homectl create otherside --storage luks --fs-type btrfs


##############################################################################
###                        Log to SystemD Journal                          ###
##############################################################################
function log {
    message="$1"
    func_name="${2-unknown}"
    priority=6
    if [ -z "$2" ]; then
        echo "INFO:" "$message"
    else
        echo "ERROR:" "$message"
        priority=0
    fi
    /usr/bin/logger --journald<<EOF
MESSAGE_ID=$SCRIPT_NAME
MESSAGE=$message
PRIORITY=$priority
CODE_FILE=$FULL_PATH
CODE_FUNC=$func_name
EOF
}

log "Executing ${SCRIPTNAME} at ${YYYYMMDD}" "None"

################################################################################
###                                  GETOPTS                                 ###
################################################################################
# Print usage and exit if no parameters provided
[[ $# -eq 0 ]] && usage

while getopts ":hn:l:" opt; do
    case "$opt" in
        n ) network=1
            network_arg=$OPTARG
            ;;
        l ) link=1
            link_arg=$OPTARG
            ;;
        * | h ) usage
            ;;
    esac
done
shift $((OPTIND -1))

################################################################################
###                                MAIN                                      ###
################################################################################

msg 'Welcome to Arch Installation' p


set_time

verify_efimode

create_partitons

format

encrypt

mount

base_install

gen_locale

gen_init

root


# Inform Kernel of Partition Updates
partprobe -s "$target_device" sync && sleep 1


################################################################################
###                                 TO-DO                                   ###
###############################################################################







	sysreq() { read-r sysreq<<SYSREQ Bit Masks dec =   hex - {description 2 =   0x2
		- enable control of console logging level 4 =   0x4 - enable control of
		keyboard (SAK, unraw) 8 =   0x8 - enable debugging dumps of processes etc.
		16 =  0x10 - enable sync command 32 =  0x20 - enable remount read-only 64 =
		0x40 - enable signalling of processes (term, kill, oom-kill) 128 =  0x80 -
		allow reboot/poweroff 256 = 0x100 - allow nicing: of all RT tasks SYSREQ }

