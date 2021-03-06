#!/usr/bin/env bash

# ARG_OPTIONAL_REPEATED([watch],[w],[folders or files to watch for changes])
# ARG_HELP([This will execute the command and restart it when a file changes.])
# ARG_POSITIONAL_DOUBLEDASH([])
# ARG_LEFTOVERS([command])
# ARG_DEFAULTS_POS([])
# ARGBASH_GO()
# needed because of Argbash --> m4_ignore([
### START OF CODE GENERATED BY Argbash v2.10.0 one line above ###
# Argbash is a bash code generator used to get arguments parsing right.
# Argbash is FREE SOFTWARE, see https://argbash.io for more info


die()
{
	local _ret="${2:-1}"
	test "${_PRINT_HELP:-no}" = yes && print_help >&2
	echo "$1" >&2
	exit "${_ret}"
}


begins_with_short_option()
{
	local first_option all_short_options='wh'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - POSITIONALS
_positionals=()
_arg_leftovers=()
# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_watch=()


print_help()
{
	printf '%s\n' "This will execute the command and restart it when a file changes."
	printf 'Usage: %s [-w|--watch <arg>] [-h|--help] [--] ... \n' "$0"
	printf '\t%s\n' "... : command"
	printf '\t%s\n' "-w, --watch: folders or files to watch for changes (empty by default)"
	printf '\t%s\n' "-h, --help: Prints help"
}


parse_commandline()
{
	_positionals_count=0
	while test $# -gt 0
	do
		_key="$1"
		if test "$_key" = '--'
		then
			shift
			test $# -gt 0 || break
			_positionals+=("$@")
			_positionals_count=$((_positionals_count + $#))
			shift $(($# - 1))
			_last_positional="$1"
			break
		fi
		case "$_key" in
			-w|--watch)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_watch+=("$2")
				shift
				;;
			--watch=*)
				_arg_watch+=("${_key##--watch=}")
				;;
			-w*)
				_arg_watch+=("${_key##-w}")
				;;
			-h|--help)
				print_help
				exit 0
				;;
			-h*)
				print_help
				exit 0
				;;
			*)
				_last_positional="$1"
				_positionals+=("$_last_positional")
				_positionals_count=$((_positionals_count + 1))
				;;
		esac
		shift
	done
}


assign_positional_args()
{
	local _positional_name _shift_for=$1
	_positional_names=""
	_our_args=$((${#_positionals[@]} - 0))
	for ((ii = 0; ii < _our_args; ii++))
	do
		_positional_names="$_positional_names _arg_leftovers[$((ii + 0))]"
	done

	shift "$_shift_for"
	for _positional_name in ${_positional_names}
	do
		test $# -gt 0 || break
		eval "$_positional_name=\${1}" || die "Error during argument parsing, possibly an Argbash bug." 1
		shift
	done
}

parse_commandline "$@"
assign_positional_args 1 "${_positionals[@]}"

# OTHER STUFF GENERATED BY Argbash

### END OF CODE GENERATED BY Argbash (sortof) ### ])
