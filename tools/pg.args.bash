#!/usr/bin/env bash

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


# THE DEFAULTS INITIALIZATION - POSITIONALS
_positionals=()
_arg_leftovers=()


print_help()
{
	printf 'Usage: %s [--] ... \n' "$0"
	printf '\t%s\n' "... : command"
}


parse_commandline()
{
	_positionals_count=0
	while test $# -gt 0
	do
		_last_positional="$1"
		_positionals+=("$_last_positional")
		_positionals_count=$((_positionals_count + 1))
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
