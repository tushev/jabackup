#!/usr/bin/env bash

# ##################################################
#
version="0.1"               # Sets version variable
# https://natelandau.com/boilerplate-shell-script-template/
#
# ##################################################

# Provide a variable with the location of this script.
scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName=`basename "$0"`

function die() { echo "$@" 1>&2 ; exit 1; }
function safeExit() {  exit 0; }

# trapCleanup Function
# -----------------------------------
# Any actions that should be taken if the script is prematurely
# exited.  Always call this function at the top of your script.
# -----------------------------------
function trapCleanup() {
  # echo ""
  # if [ -d "${tmpDir}" ]; then
    # rm -r "${tmpDir}"
  # fi
  rm -f ${args[0]}/db_jabackup_$RAND_SUFFIX.sql.gz
}

# Set Flags
# -----------------------------------
# Flags which can be overridden by user input.
# Default values are below
# -----------------------------------
quiet=0
algo="z"
base_name="backup"
args=()

# Set Temp Directory
# -----------------------------------
# Create temp directory with three random numbers and the process ID
# in the name.  This directory is removed automatically at exit.
# -----------------------------------
# tmpDir="/tmp/${scriptName}.$RANDOM.$RANDOM.$RANDOM.$$"
# (umask 077 && mkdir "${tmpDir}") || {
  # die "Could not create temporary directory! Exiting."
# }



function mainScript() {
####################################################

if [ ! -d "${args[0]}" ]; then
	die "Directory ${args[0]} does not exist"
fi

if [[ "$base_name" == *\/* ]] 
then
	backup_name=$base_name
else
	backup_name="`pwd`/$base_name"
fi

cd ${args[0]}

q=\'
dbname=$(grep -oE '\$db = .*;' configuration.php | tail -1 | sed 's/$db = //g;s/;//g' | tr -d "$q" )
dbuser=$(grep -oE '\$user = .*;' configuration.php | tail -1 | sed 's/$user = //g;s/;//g' | tr -d "$q" )
dbpass=$(grep -oE '\$password = .*;' configuration.php | tail -1 | sed 's/$password = //g;s/;//g' | tr -d "$q" )
dbhost=$(grep -oE '\$host = .*;' configuration.php | tail -1 | sed 's/$host = //g;s/;//g' | tr -d "$q" )

pass_string=""
if [ -n "$dbpass" ]; then
	pass_string=" -p$dbpass"
fi

# change socket to localhost; should be improved in upcoming versions
if [[ "$dbhost" == "." ]]; then
	dbhost="localhost"
fi

# save file path

RAND_SUFFIX="$RANDOM.$RANDOM.$RANDOM.$$"

case $algo in
	j) ext="bz2" ;;
	J) ext="xz" ;;
	*) ext="gz" ;;
esac


echo "Starting mysqldump"
mysqldump -h $dbhost -u $dbuser$pass_string $dbname | gzip > db_jabackup_$RAND_SUFFIX.sql.gz
echo "Creating $backup_name.tar.$ext from ${args[0]}; follow symlinks"
tar -c${algo}hf $backup_name.tar.$ext .


echo "Done."
cd - > /dev/null

echo -n

####################################################
}

############## Begin Options and Usage ###################
# Print usage
usage() {
  echo -n "USAGE: ${scriptName} [OPTIONS] PATH

PATH is a path to Joomla! root (where index.php & configuration.php are located)

 Options:
  -b, --basename	BASENAME for archive (may include path). Extension will be added automatically (!).
  -z, --gzip2    	Compress files with gzip (default)
  -j, --bzip2    	Compress files with bzip2
  -J, --xz		    Compress files with xz 
  -q, --quiet       Quiet (no output) [not implemented yet]
  -h, --help        Display this help and exit
      --version     Output version information and exit
	  
Example: ./${scriptName} /var/www/joomla
This will create backup of Joomla! from /var/www/joomla as backup.tar.gz in current directory

Example: ./${scriptName} -f /home/mysite -J /var/www/joomla
This will create backup of Joomla! from /var/www/joomla as /home/mysite.tar.xz
"
}
# Iterate over options breaking -ab into -a -b when needed and --foo=bar into
# --foo bar
optstring=h
unset options
while (($#)); do
  case $1 in
    # If option is of type -ab
    -[!-]?*)
      # Loop over each character starting with the second
      for ((i=1; i < ${#1}; i++)); do
        c=${1:i:1}

        # Add current char to options
        options+=("-$c")

        # If option takes a required argument, and it's not the last char make
        # the rest of the string its argument
        if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
          options+=("${1:i+1}")
          break
        fi
      done
      ;;

    # If option is of type --foo=bar
    --?*=*) options+=("${1%%=*}" "${1#*=}") ;;
    # add --endopts for --
    --) options+=(--endopts) ;;
    # Otherwise, nothing special
    *) options+=("$1") ;;
  esac
  shift
done
set -- "${options[@]}"
unset options

# Print help if no arguments were passed.
# Uncomment to force arguments when invoking the script
[[ $# -eq 0 ]] && set -- "--help"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) usage >&2; safeExit ;;
    --version) echo "$(basename $0) ${version}"; safeExit ;;
	-b|--basename) shift; base_name=${1} ;;
    -z|--gzip) algo="z" ;;
    -j|--bzip2) algo="j" ;;
    -J|--xz) algo="J" ;;
    -q|--quiet) quiet=1 ;;
    --endopts) shift; break ;;
    *) die "invalid option: '$1'." ;;
  esac
  shift
done

# Store the remaining part as arguments.
args+=("$@")

############## End Options and Usage ###################




# ############# ############# #############
# ##       TIME TO RUN THE SCRIPT        ##
# ##                                     ##
# ## You shouldn't need to edit anything ##
# ## beneath this line                   ##
# ##                                     ##
# ############# ############# #############

# Trap bad exits with your cleanup function
trap trapCleanup EXIT INT TERM

# Exit on error. Append '||true' when you run the script if you expect an error.
set -o errexit

# Bash will remember & return the highest exitcode in a chain of pipes.
# This way you can catch the error in case mysqldump fails in `mysqldump |gzip`, for example.
set -o pipefail

# Run your script
mainScript

safeExit