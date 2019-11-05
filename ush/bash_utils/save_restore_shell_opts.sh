#
#-----------------------------------------------------------------------
#
# This file defines functions used to save and restore the state of the
# shell options.  The function save_shell_opts() appends the current set
# of shell options to the end of a global array named shell_opts_array,
# while the function restore_shell_opts() restores the shell options 
# stored in the last element of shell_opts_array (and removes that ele-
# ment from the array).
# 
#-----------------------------------------------------------------------
#


function save_shell_opts() {
#
# Get the current set of shell options and save them in the local varia-
# ble shell_opts.
#
  local shell_opts="$(set +o)"$'\n'"set -$-"
  shell_opts=${shell_opts//$'\n'/ }
  shell_opts=$( printf "%s\n" "$shell_opts" | sed -r -e "s/set ([+-])/\1/g" )
#
# Store the current set of shell options in the global array shell_-
# opts_array so we can reuse them later.
#
  shell_opts_array+=("${shell_opts}")
#
}
#} > /dev/null 2>&1  # This will redirect both stdout and stderr to null
                    # even if xtrace is enabled when the function gets
                    # called.


function restore_shell_opts() {
#
# Get the last element of the shell_opts_array global array containing
# a sequense of shell options.  We assume here that the last set of op-
# tions saved in this array is the one we want to restore.
#
  local shell_opts=${shell_opts_array[*]: -1} 
#
# Delete the last element of the global array.
#
  local index=("${!shell_opts_array[@]}")
  unset 'shell_opts_array[${index[@]: -1}]'
#
# Issue the "set" command followed by the appropriate shell options.  
# Note that we don't put double quotes around $shell_opts because that
# would cause the contents of shell_opts to be treated as a single argu-
# ment to "set", which is not what we want.
#
  set $shell_opts  
#
}
#} > /dev/null 2>&1  # This will redirect both stdout and stderr to null
                    # even if xtrace is enabled when the function gets
                    # called.
