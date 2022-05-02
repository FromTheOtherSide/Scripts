#!/bin/bash
set +x

#-------------------------- BEGIN DEFAULT PARAMETERS --------------------------#

# Ignore case applies to file_name matches in digest only
ignore_case=false

# verbosiity: silent, info, verbose, debug
volume="info"

# Default algorithm when unspecified
ALGORITHM='SHA256'  

declare -a algo_supported
algo_supported=(
	SHA256
	SHA512
)

# Mode options
modes_ar=(
	'digest'
	'hash'
	'file'
	'device'
)

script_name="$(basename "$0")"
script_rev='v.01'
timestamp="$(date -Im)"
#-------------------------- END DEFAULT PARAMETERS ---------------------------#

Usage() {
	
read -r -d '' usage<<-USAGE
	Usage
	Compare the hash of a file or block device against that of a digest file, a
	user provided string, or the hash of another file. File can be a clock device 
	such as a USB drive.  
	"$script_name" [ -a ALGORITHM ] -F File_Path -D DIGEST [-i] 
	"$script_name" [ -a ALGORITHM ] -F File_Path -H HASH 
	"$script_name" [ -a ALGORITHM ] -F File_Path -f File_Path q
	$:0 [ -a ALGORITHM ] -B DEVICE [ -F File_PathREF | -b BYTES -N NAME ] -D DIGEST [-i] 

	-i 		File name comparisons are to be case insensitive.

	-B		Read from a block device rather than a normal file. File_PathREF is the
			ISO file the USB was created from and provides the NAME to read from
			DIGEST and the BYTES to read from DEVICE. 

	ALGORITHM 	The function used to compute the hash of File_Path. Defaults to sha256
			when omitted. 
			Select from:
			md5, sha1, sha256 (default), sha512

	DIGEST		A text file containing a line with both the file name and
			hash of File_Path. The output of the coreutils shasum programs would
			create a matching DIGEST. 

	HASH		A hexidecimal string, optionally preceeded by '0x', 
			representing the hash of File_Path as computed with ALGORITHM. HASH
			is represented numerically within "$script_name" to eliminate any formatting
			from comparison. 

	BYTES		The number of bytes to read from File_Path which must be a block device.
			If validating the creation of a USB from an ISO for example, this 
			should be equivilant to thee ISO file size. 

	HASH		The computed hash of File_Path. More specifically, the integer returned 
			as a result of applying the ALGORITHM function to File_Path.

	File_Path		The base file name of File_Path or, if the -b option is used, the block 
			device to read from i.e. '/dev/sda'.  

	OPERATION DETAILS:

	FILE to DIGEST
	Returns 0 if HASH_FILE and NAME_FILE appear on the same line within DIGEST. Returns 1
	no match found. if a HASH_FILE appears in DIGEST and a case insensitive only match of NAME_FILE is 
	found in DIGEST, 0 if -i option is applied. Returns 2 

	FILE to HASH
	Returns 0 if HASH equals HASH_FILE, 1 otherwise.

	FILE to FILE
	Returns 0 if the hash values of each FILE are identical as computed
	using ALGORITHM.
USAGE

printf '%s\n' "$usage"

}

#----------------------- PARSE POSITIONAL PARAMETERS --------------------------#

read -r -d '' other<<MODES
DIGEST
	"$script_name" digest /path/digest

The user provides a digest. Calculate the hash of any files named in the provided digest and present in the
digest directory. An alternative directory may be provided with the -d option.
List each file present in both as passing if the hashes match, failing
otherwise. Also list the number of file present in the digest and missing from
the directory. 
	Mandatory User Inputs
		digest file or files
	Optional User Inputs
		alternative directory
	Options
								recursive
								include digest directory with alternative directories
				Output
								A line for each file found containing
								file name:algorithm:Pass/Fail
				Return
								0 if all files were found and matched
								1 if no files found
								2 if user parameter error
								3 if other error
								1000 + number of files not found or matching
HASH
The user provides a hash and a file. The file hash is calculated using the
length of the hash to determine the algorithm. The 				
												

for each of the files listed in a digest, calulate the hash of any found and
determin file to to determine look for all files listed in digest in the working
directory,
# calculate their hashes, and determine if they match those in digest. User
# Inputs: digest algorithm Implied Imputs: Files in Working Directory

# hash: provide a file and a string representing a hash on the command line as a
# string. Determine if the hash matches that of the file. User Inputs: hash file
# algorithm Implied Inputs:
	# 

# file
MODES

#-------------------------------- BEGIN COLORS --------------------------------#

color_none='\e[0m'
color_black='\e[30m'
color_red='\e[31m'
color_green='\e[32m'
color_brown='\e[33m'
color_blue='\e[34m'
color_purple='\e[35m'
color_cyan='\e[36m'
color_lightgray='\e[37m'
color_darkgray='\e[1;30m'
color_yellow='\e[1;33m'
color_lightpurple='\e[1;35m'


msg() {
	declare pre post fd=1 msg="$2" nl='\n'
	case "$1" in
		error) color="$color_red"; pre='ERROR: ' fd=2;;
		warn) color="$color_yellow"; pre='WARNING: ';;
		info) color="$color_cyan"; pre='INFO: ';;
		verbose) color="$color_lightgray"; pre='VERBOSE: ';;
		debug) color="$color_brown"; pre='DEBUG: ';;
	esac
  
	[[ -n "$3" ]] && nl='' # If pos parameter 3 provided, no new line 
	
	# If FD is not a tty, disable color output
	if [[ ! -t "$fd" ]]; then pre=''; post=''; fi
	
	printf '%b%s%b%s%b' "$color" "$pre" "$color_none" "$2" "$nl" >&"$fd"
}
#--------------------------------- END COLORS ---------------------------------#




#-------------------------- BEGIN PARSE PARAMETERS ---------------------------#

Get_Opts(){
# while getopts hiA:F:f:D:H:B: opt 
# declare optstr=${1:?'optstr required'} args="${@:2}"
while getopts "${1}" opt 
do 
	case $opt in 
		T) # Test Mode
			opts+=('T')
			test_enabled=true
			msg verbose 'Test Mode Enabled'
			;;
		A) # Assign ALGORITHM	
			opts+=('A')
			ALGORITHM="${OPTARG@L}" 
			# convert supplied algorithm to lower case 
			if [[ ! "${algorithms[*]}" =~ $ALGORITHM ]]; then 
				msg error 'Invalid algorithm provided.\n' 
				exit 2 
			fi 
			msg verbose "Algoritm = $ALGORITM"
			;; 
		B) # Use a block device 
			opts+=('B')
			declare DEVICE
			# Test if mutually exclusive options are used
			if [[ -v "$File_Path2" ]] || [[ -v HASH ]]; then printf
				'Only one of -d DIGEST, -h HASH, or -F File_Path2 may be assigned'
				exit 3 
			fi
			DEVICE="$OPTARG" 
			if [[ ! -b "$DEVICE" ]]; then 
				printf 'ERROR: $DEVICE is not a block device' 
				exit 100 
			fi 
			;;
		F) # Assign File_Path 
			opts+=('F')
			declare -gr File_Path="$OPTARG" 
			if [[ ! -f "$File_Path" ]]; then 
				printf 'ERROR: $File_Path not a regular file' 
				exit 100 
			fi 
			;;
		f) # Assign File_Path2
			declare -i File_Path2_HASH
			# Test if mutually exclusive options are used
			if [[ -v "$DIGEST" ]] || [[ -v HASH ]]; then 
				printf 'Only one of -d DIGEST, -h HASH, or -F File_Path2 may be assigned'
				exit 3 
			fi
			File_Path2="$OPTARG"
			if [[ ! -f "$File_Path" ]]; then 
				printf 'ERROR: $File_Path not a regular file' 
				exit 100 
			fi 
			;; 
		D) # Assign DIGEST
			# Test if mutually exclusive options are used
			if [[ -v "$File_Path2" ]] || [[ -v HASH ]]; then 
				printf 'Only one of -d DIGEST, -h HASH, or -F File_Path2 may be assigned' 
				exit 3 
			fi
			DIGEST="$OPTARG" 
			if [[ ! -f "$DIGEST" ]]; then 
				printf 'ERROR: $File_Path not a regular file' 
				exit 100 
			fi 
			;; 
		H) # Assign HASH
			opts+=('H')
			# Test if mutually exclusive options are used
			if [[ -v "$File_Path2" ]] || [[ -v DIGEST ]]; then 
				printf 'Only one of -d DIGEST, -h HASH, or -F File_Path2 may be assigned' 
				exit 3 
			fi
			# Ensure HASH is 32 char min hexadecimal
			if [[ ! "$HASH" =~ '^[[:xdigit:]]{32,}$' ]]; then 
				printf 'ERROR: HASH must be comprised only of a minimum of 32 hedadecimal \ 
					characters optionally preceeded by 0x' 
				exit 100 
			fi
			# Automatically store hash a decimal integer by ensuring OPTARGS is always
			# preceded by 0x and declaring HASH as an integer as long as a valid hex
			# is is provided 
			declare -iu HASH=$([[ ! "$OPTARG" =~ ^0x[[:xdigit:]]*$ ]] && \
				echo "0x$OPTARG" || echo "$OPTARG") 
			printf '%X' "$HASH" 
			;; 
		h) # Show Usage
			Usage 
			exit 
			;; 
		i) # Set case sensitive	off 
			opts+=('i')
			CaseSensitive='false' 
			shopt -s 'nocasematch' 
			;; 
		*) # got to help 
			Usage 
			exit 1 
			;; 
	esac 
done


}
#---------------------------- END PARSE PARAMETERS ----------------------------#

Characterize_Algorithms() {
	# Use Global Algorithm variable to export the following
	declare -Arg algo_sha256=(
		[cmd_coreutils]='sha256sum --zero'
		[cmd_openssl]='openssl dgst -sha256' 
		[hash_len]=64
		[test_vector_msg]='5a86b737eaea8ee976a0a24da63e7ed7eefad18a101c1211e2b3650c5187c2a8a650547208251f6d4237e661c7bf4c77f335390394c37fa1a9f9be836ac28509'
		[test_vector_md]='42e61e174fbb3897d6dd6cef3dd2802fe67b331953b06114a65c772859dfc1aa'
		[test_vector_len]='512'
	)

	declare -Arg algo_sha512=(
		[cmd_coreutils]='sha512sum --zero'
		[cmd_openssl]='openssl dgst -sha512' 
		[hash_len]=128
		[test_vector_msg]='fd2203e467574e834ab07c9097ae164532f24be1eb5d88f1af7748ceff0d2c67a21f4e4097f9d3bb4e9fbf97186e0db6db0100230a52b453d421f8ab9c9a6043aa3295ea20d2f06a2f37470d8a99075f1b8a8336f6228cf08b5942fc1fb4299c7d2480e8e82bce175540bdfad7752bc95b577f229515394f3ae5cec870a4b2f8'
		[test_vector_md]='a21b1077d52b27ac545af63b32746c6e3c51cb0cb9f281eb9f3580a6d4996d5c9917d2a6e484627a9d5a06fa1b25327a9d710e027387fc3e07d7c4d14c6086cc'
		[test_vector_len]='1024'
	)
}

Create_Test_Files() {
	if [[ " ${*} " =~ " d " ]]; then
		declare	test_digest="${test_path}/digest"
		printf '%s  %s\n' "${algo_sha256[test_vector_md]}" "$test_file" > "$test_digest"
	fi

	if [[ " ${*} " =~ " f " ]]; then
		declare test_file=
	fi
	# Declare global variables
	declare test_path="$(mktemp --directory)" \
		test_file="${test_path}/file" 
	
	printf "${algo_sha256[test_vector_msg]}" | xxd -p -r>sha256test.bin 
	

	# shasum text Hash Style
	"${source_hash}\s\s${source_name}"
	
	# shasum binary hash style
	"${source_hash}\s\*${source_name}"

	# bsd aka tag hash stype
	"${algoritm}\s\(${source_name}\)\s${source_hash}" 
}

determine_digest_type(){ 
	local L=hash_length 
	if [[ -f "$digest" ]];then 
		if grep -iqE "^.*\s[0x]{0,1}[[:xdigit:]]{$L}\s.*$" "$digest"; then 
			hash=$(grep -iqE "^.*\s[0x]{0,1}[[:xdigit:]]{$L}\s.*$" "$digest") 
		else 
			printf 'ERROR: No hexadecimal format hash of length $L in digest\n' 
			exit 2 
		fi 
	fi 
}

Calc_Hash() { 
	declare file="$1" alg="$2" hash 
	printf 'Calculating the %s hash of %s' "$2" "$1" 
	hash=$(printf '%s\n' "$(printf $(cat "$file" | "${alg}sum"))")
	printf 'Hash Calculation Complete\n%s\n' "${hash@U}" 
}

Calc_Hash_BlockDev() {
	# mandatory arguments
	declare device=${1:?${script_name}:device_param_required} 
	declare -i bytes=${2:?${script_name}:bytes_param_required}
	# optional arguments
	declare algorithml=${3:-"$ALGORITHM"}

	# compose head options, must be silent for valid hash
	head_params=( --bytes="$bytes" --silent "$device")

	# Calculate Hash
	printf 'Calculating the hash of the first %d bytes of %s' "$bytes" "$device"
	hash=$(printf '%s\n' "$(printf $(head "${head_params[@]}" | "${alg}sum"))")
	printf 'Hash Calculation Complete\n%s\n' "${hash@U}" 
}

Characterize_File() {
	# Declare GLOBAL variables
	declare -g file_name file_size 
	declare -gu file_hash # will always be converted to upper case
}
File_Name() {
	# File base nasme for use in digest search
	printf '%s' "$(basename "$1")"
}

File_Size() {
	# File size for use in block device characterization
	printf '%s' "$(stat -printf '%s' "$1")"
}

File_Hash() {
	# File hash for comparison
	printf '%s' "$(grep -Eo '^[[:xdigit:]]*' <(sha256sum "$1"))" 
}

Check_Hash(){
	[[ "$1" -eq "$2" ]] && printf 'true' || printf 'false'
}

File_Exists(){
	[[ -f "$1" ]] && printf 'true' || printf 'false'
}


Report() {
	
	printf '%s\n' "${dgsts_data[@]}"
	exit
}

Populate_Lines() {
	regex_gnusum='^([[:xdigit:]]*)[[:space:]]([[:space:]]|\*)(.*)$'
	regex_tagsum=''
	regex_bsd=''
	# loop through each line in the digest file, populate curr_line array fields
	while read -r line; do

		# increment the line counter
		(( lines_read++ ))

		# Set basic line propoerties
		curr_line=() # clear current_line value 
		curr_line+=("$(printf '%.3d' "$lines_read")") # line_num 0
		curr_line+=( "$(printf '%s' "$line")" ) # line_content 1
	  
		# Check if line is a file:hash digest
		[[ "$line" =~ $regex_gnusum ]] && current_line+=('true') || 
			curr_line+=('false') # line_isvalid 2
		
		# Set line hash and file name, will be '' & '' if isdigest false
		curr_line+=( "$(printf '%s' "${BASH_REMATCH[3]}")" ) # file_name 3
		curr_line+=( "$(printf '%s' "${BASH_REMATCH[1]}")" ) # file_hash 4
		curr_line+=( "$(printf '%s' 'sha256')" ) # algorith 5

		# call inspect_file to look for and hash file
		curr_line+=( "$(printf '%s' "$(dirname "$1")/"${current_line[4]}")")" ) # file_path 6
		curr_line+=( "$(printf "$(File_Exists "${current_line[6]}")")" )  # file_exists 7
		curr_line+=( "$(printf "$(File_Hash "${current_line[6]}")")" ) # file_hash 8
		
		# Check if hashes match 9
		curr_line+=("$(Check_Hash "${current_line[6]}" "${current_line[4]}")") 

		# append line results to main results
		for i in "${curr_line[@]}"; do
			dgsts_data+=("$i")
		done

	done < "$1"

}

Populate_Digests(){
	declare -ag dgsts_data
	declare curr_dgst
	
	dgsts_data="${#@}" # Qty of digest files 
	
	# Loop through arguments representing digests
	for i in "${@}"; do
		(( curr_dgst++ ))
		# For each digest, populate name, path exits, is file, lines	
		
		dgsts_data+=( "$(basename "$i")" ) # Digest Name 1
		
		dgsts_data+=( "$(realpath "$i")" ) # Digest Path 2
		
		if [[ -e "$(realpath $i)" ]]; then
			dgsts_data+=( 'true' )
		else
			dgsts_data+=( 'false' )# Digest Exists 3
		fi

		if [[ -f "$(realpath $i)" ]]; then 
			dgsts_data+=( 'true' )
		else
			dgsts_data+=( 'false' ) # Digest is a File 4
		fi
		dgsts_data+=( "$(wc -l "$(realpath $i)")"  ) # Digest Lines 5
		
		Populate_Lines "$(realpath $i)"

	done
}


Main_Digest(){
	# Possible Options
	# Directory to look for files that appear in Digest
	# -Digest Dir
	# -Working Dir
	# -Specify
	# Formats of digest lines to accept
	# -GNU as in MD5SUM
	# -GNU tags
	# -BSD
	# -Custom
	# Test Mode
	# Verify Digest Signature


	# declare arrays containing fields names
	# the same array names minus _fields will contian the data
	# fields with a '#' are repeated for each object

	# Loop through each digest and using these arrays:

	# Subroutine: Populate_Digests 
	# For each digest
	# Populate with the header data for a digest 
	# Populate with data from Populate_Digest
	# declare -ag dgsts_data

	# Subroutine: Populate_Digest
	# For each line
	# Clear Data
	# Call 
	# Populate with the data for each line in the digest
	# Write to dgsts_data
	# Repeat for next digest
	declare -ag dgst_data

	# Subroutine: Populate_Line
	# Clear data
	# Populate with each datapoint in a digest line
	# Write to dgst_data
	# Repeat for next line
	declare -ag line_data
	declare -agr dgsts_fields=(
		'Digests Count'
		'Digest Name'
		'Digest Path'
		'Digest Exists'
		'Digest is File'
		'dgst#_fields'
	)

	declare -agr dgst_fields=(
		'Lines Count'
		'dgst_ln#_fields'
	)
		
	declare -agr dgst_ln_fields=(
		'Line Number'
		'Line Content'
		'Line is Valid'
		'Line Format'
		'Line Hash'
		'Line File'
		'File Path'
		'File Exists'
		'File Hash'
		'File Match'
	)

	# Possible Options
#	optstr='A:T'
#	Get_Opts "$optstr" 
	
	Populate_Digests "${@:$(( OPTIND +1 ))}"
	
	Report
}
#--------------------------------- BEGIN MAIN ---------------------------------#

# If the first postional parameter is an available mode, enable it!
if [[ " ${modes_ar[*]} " =~ " ${1} " ]]; then
	mode="${1}"
	
	"Main_${mode@u}" "${@}"
else 

	msg error "$1 is not a valid mode"
	exit 1

fi

#---------------------------------- END MAIN ----------------------------------#


tests() {
	# Test Inputs\Parameters 1) File_Path - The string the user enters to point to
	# the file to be hashed name/path content binary text 2) DIGEST - The string
	# entered to represent the hash name/path contains neither HASH nor File_Path
	# name contains only HASH contains only File_Path name contains both HASH and
	# File_Path name once each on same line contains both HASH and File_Path name
	# once each on seperate lines contains both HASH and File_Path name once each
	# on same line plus others on sepeate lines contains both HASH and File_Path
	# name multiple times on seperate lines binary file provided instead? 2)
	# ALGORITHM - The string entered to select the algoritm 3) DIGEST - The string
	# to point to the digest 5) file - the actual file 6) algorithm - the
	# algorithm/external program combo 7) digest - the digest file 8) hash - an
	# accepted HASH

	# 
	# 1) File_Path Name 3) File_Path Content 4) DIGEST Name 5) 5) DIGEST File Name
	# Not Contained 6) DIGEST File Name Contained Once Within 7) DIGEST File Name
	# Capitalization 8) DIGEST File Name Multiple Times on Same Line 9) DIGEST
	# File Name Surrounding Characters 10) DIGEST File Encoding 11) Digest Hash
	# Same as 6-9 12) DIGEST Hash & File Same Line 13) DIGESt Hash & File
	# Different Lines

	# Test Vectors selected from NIST The Secure Hash Algorithm Validation System
	# (SHAVS) I simply selected the last message from the byte oriented short test
	# for each algoritm We are not validating the algoritm here, just making sure
	# nothing is totaly fonked up
	# https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Algorithm-Validation-Program/documents/shs/shabytetestvectors.zip
	# create a temporary location for testing files
	declare dirT=$(mktemp)
	
	# vectors
	msg_sha256='f6bb5d59b0fa9de0828b115303bf94aa987361ccdde48d0246c5d5ab068f9a322f192a3e1b6841280cc8d0b20f1bfcf626726a9ca5daba50dd795173f8d95c11'
	ms_sha256='f757fe6ec7239f7e9f6accade3990a15e74e435a932c48ecccfa70a66c3fdb9d'


	# Create File_Path
	printf '%s' "$MSG" > "${dirT}/File_Path_sha256.txt"	
	
	# Create DIGEST

}
