!/usr/bin/env bash 
################################################################################
# N:BashTemplate  |__________________                    ____________________  #
#=================|__  __ __  /___  /_______________________(_______  __|__  / #
# V:0.03          |_  / / _  ____  __ _  _ __  _____  _____  /_  __  /___/_ <  #
#=================|/ /_/ // /_ _  / / /  ___  /   _(__  )_  / / /_/ / ____/ /  #
# A:0thersid3     |\____/ \__/ /_/ /_/\___//_/    /____/ /_/  \__,_/  /____/   #
#==============================================================================#
# Description                                                                  #
# Script to demonstrate the features of this template                          #
# Dependencies:                                                                #
#                                                                              #
################################################################################
###                               Error Handling                             ###
################################################################################
# This will cause commands like read and conditionals to error. 
set +e # Exit if any command returns a non-zero exit status. 
set +x # All executed commands are printed to the terminal.
set -u # All parameters must be defined including positional parameters!!
set -o pipefail # This can cause conditionals to error: x=0; echo $x && echo '1'
set -o errtrace # = set -E Enable err trap, call code when an error is detected


################################################################################
###                     Common Vars and Functions                            ###
################################################################################
msg() {   
    # easily create colored messages
    local string=${1:-} ccode=${2:-none}
    local -A colors=([bl]='30' [r]='31' [g]='32' [br]='33' [bl]='34' [p]='35' [gr]='1;30'
        [pink]='1;31' [teal]='1;32' [yellow]='1;33' [sky]='1;34' [violet]='1;35' 
        [periwinkle]='1;36' [white]='1;37' [none]='0')
    local -A styles=([none]=0 [bold]=1 [underlined]=4 [blinking]=5 [reverse]=7)
	printf '%b%s%b\n' "\e[${colors["$ccode"]}m" "${string}"  "\e[${styles[none]}m"
}

reqroot(){
    if [[ "$EUID" -ne 0 ]]; then
        msg "${FUNCNAME[1]} requires the script be run as root" r
        exit 1
    fi
}

################################################################################
###                                 Usage                                    ###
################################################################################
usage() {
cat<<USAGE 
Usage: $SCRIPT_NAME [-N [PARAM] ] [-L [PARAM] ] [-H]
-N     : Work with systemd-networkd .network files
-L     : Work with systemd-dev .link files
-D     : Work with systemd-networkd .netdev files
-R     : Work with systemd-resolved files
COMMAND
D    : Enable debugging
d    : Disable debugging
I    : Print configuration info
Example
# Print the information for netdev and disable netdev debugging
systemd_networking_cfg -D Id 
USAGE
exit 2
}

################################################################################
###                                  GETOPTS                                 ###
################################################################################
# Initalize Vars
clear

declare network link netdev resolved

while getopts ":N:L:D:R:" opt
do
    case $opt in
        N) 
            msg 'Network Selected' r
            network="$OPTARG"
            ;;
        L) 
            link="$OPTARG"
            ;;
        D) 
            netdev="$OPTARG"
            ;;
        R) 
            echo 'dgieuagpsdhhdfvhdfv'
            msg 'Resolved Selected' r
            resolved="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;

    esac
done

echo "getopts returned $?"

shift $((OPTIND -1))

################################################################################
###                             NETDEV SETTINGS                              ###
################################################################################

dirsysudev1=/usr/lib/udev/rules.d
dirsysudev2=/usr/local/lib/udev/rules.d
dissysrunudev=/run/udev/rules.d
dirsysadminudev=/etc/udev/rules.d. 
filevdev=".netdev"
################################################################################
###                               LINK SETTINGS                              ###
################################################################################

################################################################################
###                              NETWORK SETTINGS                            ###
################################################################################
# systemd-networkd network file locations
dirsysnet1=/usr/lib/systemd/network
dirsysnet2=/usr/local/lib/systemd/network
dirrunnet=/run/systemd/network
diradminnet=/etc/systemd/network
filenet=".network"

################################################################################
###                   SYSTEMD-RESOLVED CONFIGURATION                         ###
################################################################################
# systemd-resolved is a system service that provides network name resolution to
# local applications. It implements a caching and validating DNS/DNSSEC stub
# resolver, as well as an LLMNR and MulticastDNS resolver and responder.

# Configuration is defined by these files in order of precedence from low to
# high. Duplicated settings will be determined by the last shown file.
# The .conf files are applied in lexographical order with the last taking
# precedence.
print_network_info() {

conf_directories=(
    /usr/lib/systemd/network
    /usr/local/lib/systemd/network
    /run/systemd/network
    /etc/systemd/network
)

dir_cats=(
    [/usr]="System"
    [/run]="Application"
    [/etc]="Administrator"
)

conf_files=$(find {${conf_directories[*]}} -type f -maxdepth 1 -iregex='^.*\.network$')

loop_dirs() {
for d in ${conf_dir}; do
    
    if [[ -d $d ]]; then
        
        msg  "${dir_cats[${d:0:4}]} Defined $Area Configrations" 'sky'
        
        readarray -t conf_files < <(find "$d" -type f -maxdepth 1 -iregex='^.*\.network$' | xargs readlink -f) 
        q
        loop files ${conf_files[*]}
   
    fi

done
}

loop files() {
    for c in $@; do
        if [[ -d "${c}.d" ]]; then
            readarray -t dropins < <(find "${c}.d" -type f -maxdepth 1 -iregex='^.*\.conf$' | xargs readlink -f | sort)
    fi
done
}

triple=([one]=([a]=1 [b]=2 [c]=3) [two]=([x]=4 [y]=5 [z]=6))






}









enable_link_debugger(){
l=1
}

disable_link_debugger(){
l=0
}

print_link_info(){
lp=1
}

enable_netdev_debugger(){
lp=2
}

disable_netdev_debugger(){
nd=1
}

print_netdev_info(){
nd=2
}

enable_resolved_debugger(){
nd=3
}

disable_resolved_debugger(){
nd=4
}

print_resolved_info(){

    sys="$1"
## where is /etc/resolv.conf mapped to

#    "$(find /run/systemd/ -iwholename '/run/systemd/resolved.conf.d/*.conf' | sort)"
declare -a resolved_conf=(

    "/run/systemd/resolved.conf"
    "/usr/lib/systemd/resolved.conf"
    "/etc/systemd/resolved.conf"
    "$(find /usr/lib/systemd/ -iwholename '/usr/lib/systemd/resolved.conf.d/*.conf' | sort)"
    "$(find /etc/systemd/ -iwholename '/usr/lib/systemd/resolved.conf.d/*.conf' | sort)"
)

    # Loop through all systemd-resolved config files
    for conf in "${resolved_conf[@]}"
    do
        [[ ! -f "$conf" ]] && continue
        # keys will store the complete list of keys assigned in those files
        declare -a keys
        # Print File Name
        printf '\n\n%s\n' "$conf"
        # Determine file category for title and color coding
        case "$conf" in
           ( '/run/systemd/resolved.conf' ) 
                msg "System Defined Settings"
                color='bl'
                ;;
            (\/usr\/lib\/systemd\/resolved\.conf) 
                msg "Application Defined Settings"
                cl='g'
                ;;
            (/etc\/systemd\/resolved\.conf) 
                msg "Administrator Defined Settings"
                cl='r'
                ;;
            (\/run\/systemd\/resolved.conf.d\/*.conf) 
                msg  "System Drop-In Settings" 
                cl='sky'
                ;;
            (\/usr\/lib\/systemd\/resolved.conf.d\/*.conf) 
                msg  "Application Drop-In Settings"
                cl='teal'
                ;;
            (\/etc\/systemd\/resolved.conf.d\/*.conf) 
                msg  "Administrator Drop-In Settings"
                cl='pink'
                ;;
            (*)
                msg "Undefined configuration file $OPT, exiting" r
                exit 2
                ;;
        esac
        # Loop through each line of current file
        while IFS= read -r line
        do
            # Skip to next line if this is a comment or lacks an '='
            [[ $line =~ '\#.*' ]] || [[ ! $line =~ '^.*=.*$' ]] && continue # Ignore comments
            # Check if the key has been used in a prior file
            if [[ -v "${line%=*}" ]]; then
                msg '# Overwriting previous setting'
                declare "${line%=*}=${line#*=}"
                keys+=("${line%=*}")
            else
                "${line%=*}=${line#*=}"
            fi

            msg "${line%=*}=${line#*=}" "$cl"
        done < "$conf"
    done

    # Effective Settings
    for k in ${keys[@]}
    do
        msg "$k=${!k}"
    done

}

# systemd-analyze cat-config systemd/resolved.conf

enable_network_debugger(){
    # Root likely required
    reqroot
    mkdir -p /etc/systemd/system/systemd-networkd.service.d/

    echo "[Service]">/etc/systemd/system/systemd-networkd.service.d/10-debug.conf
    echo "Environment=SYSTEMD_LOG_LEVEL=debug">>/etc/systemd/system/systemd-networkd.service.d/10-debug.conf

    systemctl daemon-reload
    systemctl restart systemd-networkd
    journalctl -b -u systemd-networkd
}

disable_network_debugger(){
    # Root likely required      
    rm /etc/systemd/system/systemd-networkd.service.d/10-debug.conf
    rm -d /etc/systemd/system/systemd-networkd.service.d/
    exit

    systemctl daemon-reload
    systemctl restart systemd-networkd
    journalctl -b -u systemd-networkd
}

################################################################################
###                                     MAIN                                 ###
################################################################################

set +x
set +u

if [[ -v $network ]]; then
    case $network in
        d) disable_network_debugger
            ;;
        D) enable_network_debugger
            ;;
        I) print_network_info
            ;;
        *) usage
            ;;
    esac
fi

if [[ -v resolved ]]; then
    echo "Parsing Resolved Arg"
    case $resolved in
        d) disable_resolved_debugger
            ;;
        D) enable_resolved_debugger
            ;;
        I) print_resolved_info
            ;;
        *) usage
            ;;
    esac
fi

if [[ -v $link ]]; then
    case $link in
        d) disable_link_debugger
            ;;
        D) enable_link_debugger
            ;;
        I) print_link_info
            ;;
        *) usage
            ;;
    esac
fi

if [[ -v $netdev ]]; then
    case $netdev in
        d) disable_netdev_debugger
            ;;
        D) enable_netdev_debugger
            ;;
        I) print_netdev_info
            ;;
        *) usage
            ;;
    esac
fi

set -u
###############################################################################
### End of Script ! If set -u && last line NOT conditional in cmd-subst     ###
###############################################################################

