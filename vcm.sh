#!/usr/bin/env bash

# Enable xtrace if the DEBUG environment variable is set
if [[ ${DEBUG-} =~ ^1|yes|true$ ]]; then
    set -o xtrace # Trace the execution of the script (debug)
fi

# A better class of script...
set -o errexit  # Exit on most errors (see the manual)
set -o errtrace # Make sure any error trap is inherited
set -o nounset  # Disallow expansion of unset variables
set -o pipefail # Use last non-zero exit code in a pipeline

############################### HELPERS ##########################################
#Helpers based on https://github.com/ralish/bash-script-template

# DESC: Handler for unexpected errors
# ARGS: $1 (optional): Exit code (defaults to 1)
# OUTS: None
function script_trap_err() {
    local exit_code=1

    # Disable the error trap handler to prevent potential recursion
    trap - ERR

    # Consider any further errors non-fatal to ensure we run to completion
    set +o errexit
    set +o pipefail

    # Validate any provided exit code
    if [[ ${1-} =~ ^[0-9]+$ ]]; then
        exit_code="$1"
    fi

    # Exit with failure status
    exit "$exit_code"
}

# DESC: Handler for exiting the script
# ARGS: None
# OUTS: None
function script_trap_exit() {
    cd "$orig_cwd"

    # Remove script execution lock
    if [[ -d ${script_lock-} ]]; then
        rmdir "$script_lock"
    fi

    # Restore terminal colours
    printf '%b' "$ta_none"
}

# DESC: Exit script with the given message
# ARGS: $1 (required): Message to print on exit
#       $2 (optional): Exit code (defaults to 0)
# OUTS: None
# NOTE: The convention used in this script for exit codes is:
#       0: Normal exit
#       1: Abnormal exit due to external error
#       2: Abnormal exit due to script error
function script_exit() {
    if [[ $# -eq 1 ]]; then
        printf '%s\n' "$1"
        exit 0
    fi

    if [[ ${2-} =~ ^[0-9]+$ ]]; then
        printf '%b\n' "$1"
        # If we've been provided a non-zero exit code run the error trap
        if [[ $2 -ne 0 ]]; then
            script_trap_err "$2"
        else
            exit 0
        fi
    fi

    script_exit 'Missing required argument to script_exit()!' 2
}

# DESC: Generic script initialisation
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: $orig_cwd: The current working directory when the script was run
#       $script_path: The full path to the script
#       $script_dir: The directory path of the script
#       $script_name: The file name of the script
#       $script_params: The original parameters provided to the script
#       $ta_none: The ANSI control code to reset all text attributes
# NOTE: $script_path only contains the path that was used to call the script
#       and will not resolve any symlinks which may be present in the path.
#       You can use a tool like realpath to obtain the "true" path. The same
#       caveat applies to both the $script_dir and $script_name variables.
# shellcheck disable=SC2034
function script_init() {
    # Useful paths
    readonly orig_cwd="$PWD"
    readonly script_path="${BASH_SOURCE[0]}"
    readonly script_dir="$(dirname "$script_path")"
    readonly script_name="$(basename "$script_path")"
    readonly script_params="$*"

    # Important to always set as we use it in the exit handler
    readonly ta_none="$(tput sgr0 2>/dev/null || true)"
}

# DESC: Initialise colour variables
# ARGS: None
# OUTS: Read-only variables with ANSI control codes
# NOTE: If --no-colour was set the variables will be empty
# shellcheck disable=SC2034
function colour_init() {
    if [[ -z ${no_colour-} ]]; then
        # Text attributes
        readonly ta_bold="$(tput bold 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly ta_uscore="$(tput smul 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly ta_blink="$(tput blink 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly ta_reverse="$(tput rev 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly ta_conceal="$(tput invis 2>/dev/null || true)"
        printf '%b' "$ta_none"

        # Foreground codes
        readonly fg_black="$(tput setaf 0 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly fg_blue="$(tput setaf 4 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly fg_cyan="$(tput setaf 6 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly fg_green="$(tput setaf 2 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly fg_magenta="$(tput setaf 5 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly fg_red="$(tput setaf 1 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly fg_white="$(tput setaf 7 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly fg_yellow="$(tput setaf 3 2>/dev/null || true)"
        printf '%b' "$ta_none"

        # Background codes
        readonly bg_black="$(tput setab 0 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly bg_blue="$(tput setab 4 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly bg_cyan="$(tput setab 6 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly bg_green="$(tput setab 2 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly bg_magenta="$(tput setab 5 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly bg_red="$(tput setab 1 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly bg_white="$(tput setab 7 2>/dev/null || true)"
        printf '%b' "$ta_none"
        readonly bg_yellow="$(tput setab 3 2>/dev/null || true)"
        printf '%b' "$ta_none"
    else
        # Text attributes
        readonly ta_bold=''
        readonly ta_uscore=''
        readonly ta_blink=''
        readonly ta_reverse=''
        readonly ta_conceal=''

        # Foreground codes
        readonly fg_black=''
        readonly fg_blue=''
        readonly fg_cyan=''
        readonly fg_green=''
        readonly fg_magenta=''
        readonly fg_red=''
        readonly fg_white=''
        readonly fg_yellow=''

        # Background codes
        readonly bg_black=''
        readonly bg_blue=''
        readonly bg_cyan=''
        readonly bg_green=''
        readonly bg_magenta=''
        readonly bg_red=''
        readonly bg_white=''
        readonly bg_yellow=''
    fi
}

# DESC: Acquire script lock
# ARGS: $1 (optional): Scope of script execution lock (system or user)
# OUTS: $script_lock: Path to the directory indicating we have the script lock
# NOTE: This lock implementation is extremely simple but should be reliable
#       across all platforms. It does *not* support locking a script with
#       symlinks or multiple hardlinks as there's no portable way of doing so.
#       If the lock was acquired it's automatically released on script exit.
function lock_init() {
    local lock_dir
    if [[ $1 = 'system' ]]; then
        lock_dir="/tmp/$script_name.lock"
    elif [[ $1 = 'user' ]]; then
        lock_dir="/tmp/$script_name.$UID.lock"
    else
        script_exit 'Missing or invalid argument to lock_init()!' 2
    fi

    if mkdir "$lock_dir" 2>/dev/null; then
        readonly script_lock="$lock_dir"
        debug "Acquired script lock: $script_lock"
    else
        script_exit "Unable to acquire script lock: $lock_dir" 1
    fi
}

# DESC: Pretty print the provided string
# ARGS: $1 (required): Message to print (defaults to a green foreground)
#       $2 (optional): Colour to print the message with. This can be an ANSI
#                      escape code or one of the prepopulated colour variables.
#       $3 (optional): Set to any value to not append a new line to the message
# OUTS: None
function pretty_print() {
    if [[ $# -lt 1 ]]; then
        script_exit 'Missing required argument to pretty_print()!' 2
    fi

    if [[ -z ${no_colour-} ]]; then
        if [[ -n ${2-} ]]; then
            printf '%b' "$2"
        else
            printf '%b' "$fg_green"
        fi
    fi

    # Print message & reset text attributes
    if [[ -n ${3-} ]]; then
        printf '%s%b' "$1" "$ta_none"
    else
        printf '%s%b\n' "$1" "$ta_none"
    fi
}

# DESC: Combines two path variables and removes any duplicates
# ARGS: $1 (required): Path(s) to join with the second argument
#       $2 (optional): Path(s) to join with the first argument
# OUTS: $build_path: The constructed path
# NOTE: Heavily inspired by: https://unix.stackexchange.com/a/40973
function build_path() {
    if [[ $# -lt 1 ]]; then
        script_exit 'Missing required argument to build_path()!' 2
    fi

    local new_path path_entry temp_path

    temp_path="$1:"
    if [[ -n ${2-} ]]; then
        temp_path="$temp_path$2:"
    fi

    new_path=
    while [[ -n $temp_path ]]; do
        path_entry="${temp_path%%:*}"
        case "$new_path:" in
        *:"$path_entry":*) ;;
        *)
            new_path="$new_path:$path_entry"
            ;;
        esac
        temp_path="${temp_path#*:}"
    done

    # shellcheck disable=SC2034
    build_path="${new_path#:}"
}

# DESC: Check a binary exists in the search path
# ARGS: $1 (required): Name of the binary to test for existence
#       $2 (optional): Set to any value to treat failure as a fatal error
# OUTS: None
function check_binary() {
    if [[ $# -lt 1 ]]; then
        script_exit 'Missing required argument to check_binary()!' 2
    fi

    if ! command -v "$1" >/dev/null 2>&1; then
        if [[ -n ${2-} ]]; then
            script_exit "Missing dependency: Couldn't locate $1." 1
        else
            debug "Missing dependency: $1" "${fg_red-}"
            return 1
        fi
    fi

    debug "Found dependency: $1"
    return 0
}

# DESC: Validate we have superuser access as root (via sudo if requested)
# ARGS: $1 (optional): Set to any value to not attempt root access via sudo
# OUTS: None
function check_superuser() {
    local superuser
    if [[ $EUID -eq 0 ]]; then
        superuser=true
    elif [[ -z ${1-} ]]; then
        if check_binary sudo; then
            debug 'Sudo: Updating cached credentials ...'
            if ! sudo -v; then
                debug "Sudo: Couldn't acquire credentials ..." \
                    "${fg_red-}"
            else
                local test_euid
                test_euid="$(sudo -H -- "$BASH" -c 'printf "%s" "$EUID"')"
                if [[ $test_euid -eq 0 ]]; then
                    superuser=true
                fi
            fi
        fi
    fi

    if [[ -z ${superuser-} ]]; then
        debug 'Unable to acquire superuser credentials.' "${fg_red-}"
        return 1
    fi

    debug 'Successfully acquired superuser credentials.'
    return 0
}

# DESC: Run the requested command as root (via sudo if requested)
# ARGS: $1 (optional): Set to zero to not attempt execution via sudo
#       $@ (required): Passed through for execution as root user
# OUTS: None
function run_as_root() {
    if [[ $# -eq 0 ]]; then
        script_exit 'Missing required argument to run_as_root()!' 2
    fi

    if [[ ${1-} =~ ^0$ ]]; then
        local skip_sudo=true
        shift
    fi

    if [[ $EUID -eq 0 ]]; then
        "$@"
    elif [[ -z ${skip_sudo-} ]]; then
        sudo -H -- "$@"
    else
        script_exit "Unable to run requested command as root: $*" 1
    fi
}

info() { pretty_print "[INFO] $*" "${fg_white-}"; }
debug() {
    if [[ ${DEBUG-} =~ ^1|yes|true$ ]]; then
        pretty_print "[DEBUG] $@"
    fi
}
warning() { pretty_print "[WARNING] $*" "${fg_cyan-}"; }
error() { pretty_print "[ERROR] $*" "${fg_red-}"; }
fatal() {
    pretty_print "[FATAL] $*" "${fg_red-}"
    exit 1
}

function confirm() {
    local _prompt _default _response

    if [ "$1" ]; then _prompt="$1"; else _prompt="Are you sure"; fi
    _prompt="$_prompt [y/n] ?"

    while true; do
        read -r -p "$_prompt " _response
        case "$_response" in
        [Yy][Ee][Ss] | [Yy]) # Yes or Y (case-insensitive).
            return 0
            ;;
        [Nn][Oo] | [Nn]) # No or N.
            return 1
            ;;
        *) # Anything else (including a blank) is invalid.
            ;;
        esac
    done
}

function stopIfNotCorrectParamValue() {
    local expectedParamValue=$1
    local actualNumber=$2

    if [ ! $expectedParamValue -eq $actualNumber ]; then
        script_usage
        script_exit "Incorrect numbers of parameters expected $expectedParamValue !" 1
    fi
}

function stopIfEmpty() {
    if [ -z "$1" ]; then
        fatal "$2"
    fi
}

############################### END HELPERS ######################################

############################### GLOBALS ##########################################
__vms_out_file__="vm_list.txt"
############################### END GLOBALS ######################################

############################### CORE FUNCTIONS ###################################

# DESC: Usage help
# ARGS: None
# OUTS: None
function script_usage() {
    cat <<EOF
Usage:
     clone "sourceVmName" "destinationVmName"                   Clone VM                  
     clone "sourceVmName" "destinationVmName" number_of_copies  Create multiple clones of virtualmachine
        example: clone "vm1" "vm_cluster" 5         It creates 5 clones with name vm_cluster-1, vm_cluster-2, vm_cluster-3, vm_cluster-4, vm_cluster-5
     
     dumpVmList all                                 Save list of all VMs currently registered on virtualbox into manage file.    
     dumpVmList run                                 Save list of running VMs currently into manage file.
     help                                           Displays this help
EOF

}

function installVboxIfMissing() {
    which VBoxManage &>/dev/null
    if [ $? -ne 0 ]; then
        confirm "Virtualbox missing... Do you want to install VirtualBox?" || fatal "Virtualbox is needed to use scripts. Exiting..."
        sudo apt install -y "virtualbox"
        sudo apt install -y "guest−additions−iso"
        info "End of installation Virtualbox"
    fi
}

# Save list of current VMS into file
function dumpVmList() {
    stopIfNotCorrectParamValue 1 $#
    local param=$1

    case $param in
    all | ALL | -a | vms)
        info "Going to dump all vms."
        local vmType="vms"
        ;;
    runningvms | running | run)
        info "Going to dump running vms."
        local vmType="runningvms"
        ;;
    *)
        script_exit "Invalid parameter was provided: $param" 1
        ;;
    esac

    local vm_list=$(VBoxManage list $vmType | grep '".*"' --only-matching | sed 's/"//g')
    stopIfEmpty "$vm_list" "No VM found."
    info "List of VMS: \n $vm_list"
    updateVmList "$vm_list"
    info "End of dump process."
}

function updateVmList() {
    stopIfNotCorrectParamValue 1 $#

    local vm_list=$1
    info "Updating mange file: $__vms_out_file__"
    printf '' >$__vms_out_file__
    for val in ${vm_list[*]}; do
        printf "%s\n" $val >>$__vms_out_file__
    done
    debug "End of update manage file: $__vms_out_file__"
}

## CLONE VM

function cloneSpecificVM() {
    local surceVm=$1
    local destVmName=$2
    info "Creating copy VM from $surceVm to $destVmName"
    VBoxManage clonevm $surceVm --name $destVmName --register
    debug "END copy VM from $surceVm to $destVmName"
}

function cloneVM() {
    if [ $# -eq 2 ]; then
        cloneSpecificVM "$1" "$2"
    fi
    stopIfNotCorrectParamValue 3 $#

    local surceVm=$1
    local destVmPrefix=$2
    local numOfCopies=$(($3))
    info "Going to copy $surceVm."

    for i in $(seq 1 $numOfCopies); do
        vmNames+="$destVmPrefix-$i "
        cloneSpecificVM "$surceVm" "$destVmPrefix-$i"
    done

    info "Vm $surceVm cloned to: $vmNames"
    confirm "Do you want to update mange vm list [$__vms_out_file__]" && updateVmList "$vmNames"
    info "VMs cloned"
}

## END CLONE VM

## STOP VM

function stopSpecificVM() {
    stopIfNotCorrectParamValue 2 $#
    local vmName=$1

    debug "Going to stop machine with name $vmName."
    
    VBoxManage controlvm "$vmName" $behavior && rc=$? || rc=$?  
    if [ $rc -ne 0 ]; then
        info "VBoxManage: $vmName $behavior"
    fi
    
    debug "End Stop machine $vmName started."
}

function stopVm() {
    stopIfNotCorrectParamValue 1 $#
    local param=$1

    case $param in
    pause)
        local behavior="pause"
        ;;
    poweroff)
        local behavior="poweroff"
        ;;
    acpi | normal)
        local behavior="acpipowerbutton"
        ;;
    *)
        script_exit "Invalid parameter was provided: $param" 1
        ;;
    esac

    info "Going to $behavior action to all vmstack."
    for vm in $(awk '{print $1}' $__vms_out_file__); do
        stopSpecificVM "$vm" $behavior
    done
    info "VMs stack stopped."
}

## END STOP VM

## START VM

function startSpecificVM() {
    stopIfNotCorrectParamValue 1 $#
    local vmName=$1

    debug "Going to run Virtual machine with name $vmName."
    VBoxManage startvm "$vmName" --type $behavior
    debug "Virtual machine $vmName started."
}

function startVM() {
    local param=$1

    case $param in
    gui)
        local behavior="gui"
        ;;
    separate)
        local behavior="separate"
        ;;
    headless | quiet | h)
        local behavior="headless"
        ;;
    *)
        script_exit "Invalid parameter was provided: $param" 1
        ;;
    esac

    if [ $# -eq 2 ]; then
        startSpecificVM "$2"
    fi

    stopIfNotCorrectParamValue 1 $#

    info "Going to start all vmstack."

    for vm in $(awk '{print $1}' $__vms_out_file__); do
        startSpecificVM "$vm"
    done
    info "VMs stack started."
}

## END VM

############################### END CORE FUNCTIONS ###############################

############################### MAIN LOOP ########################################

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function parse_params() {
    local param
    if [ $# -eq 0 ]; then
        script_usage
        exit
    fi

    while [[ $# -gt 0 ]]; do
        param="$1"
        shift
        case $param in
        dumpVmList)
            dumpVmList "$@"
            exit
            ;;
        clone)
            cloneVM "$@"
            exit
            ;;
        stop)
            stopVm "$@"
            exit
            ;;
        start)
            startVM "$@"
            exit
            ;;
        help)
            script_usage
            exit 0
            ;;
        *)
            script_exit "Invalid parameter was provided: $param" 1
            ;;
        esac
    done
}

# DESC: Main control flow
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: None
function main() {
    trap script_trap_err ERR
    trap script_trap_exit EXIT

    script_init "$@"
    installVboxIfMissing
    colour_init
    parse_params "$@"
    #lock_init system
}

main "$@"

############################### END MAIL LOOP ####################################