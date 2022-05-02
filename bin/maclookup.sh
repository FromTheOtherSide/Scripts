#!/usr/bin/env bash 
################################################################################
# N:              |__________________                    ____________________  #
#=================|__  __ __  /___  /_______________________(_______  __|__  / #
# V:              |_  / / _  ____  __ _  _ __  _____  _____  /_  __  /___/_ <  #
#=================|/ /_/ // /_ _  / / /  ___  /   _(__  )_  / / /_/ / ____/ /  #
# A:0thersid3     |\____/ \__/ /_/ /_/\___//_/    /____/ /_/  \__,_/  /____/   #
#==============================================================================#
# Description                                                                  #
# Script to demonstrate the features of this template                          #
# Dependencies:                                                                #
# * None                                                                       #
#                                                                              #
################################################################################
###                               Error Handling                             ###
################################################################################
# This will cause commands like read and conditionals to error. 
set +e # Exit if any command returns a non-zero exit status. 
set +x # All executed commands are printed to the terminal.
set -u # All parameters must be defined including positional parameters!!
set +o pipefail # This can cause conditionals to error: x=0; echo $x && echo '1'
set -E # Enable err trap, call code when an error is detected

trap "echo ERROR: There was an error in ${FUNCNAME:-'main context'}" ERR

################################################################################
###                        INITIALIZE VARIABLES                              ###
################################################################################

OUI=$(ip addr list|grep -w 'link'|awk '{print $2}'|grep -P '^(?!00:00:00)'| grep -P '^(?!fe80)' | tr -d ':' | head -c 6)
echo $OUI
curl -sS "http://standards-oui.ieee.org/oui.txt" | grep -i "$OUI" | cut -d')' -f2 | tr -d '\t'

curl -O - "http://standards-oui.ieee.org/oui.txt"


###############################################################################
###                                 MAIN                                    ###
###############################################################################






