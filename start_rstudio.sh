#!/bin/bash

TOOL_HOME=$(dirname "${BASH_SOURCE[0]}")
echo "RStudio home: $TOOL_HOME"
echo "User home: $HOME"

# RStudio Server must have R on its path when it launches.
# It does not need to be the actual environment the project uses; our
# custom rsession script will switch R_HOME and the PATH accordingly.
source $HOME/anaconda/bin/activate anaconda50_r

# Ensure R sees all of the currently available environment variables
env | sed -nE 's@^([^=]*)=(.*)@\1="\2"@p' > $HOME/.Renviron

args=($TOOL_HOME/bin/rserver \
      --rsession-config-file $TOOL_HOME/rsession.conf \
      --rsession-path $TOOL_HOME/rsession.sh \
      --auth-none=1 --auth-validate-users=0 --auth-minimum-user-id=1 \
      --server-working-dir=$HOME --server-user=$(id -un))

# Translate AE environment variables to Rstudio command-line arguments
[[ $TOOL_PORT ]] && args+=(--www-port=$TOOL_PORT)
[[ $TOOL_ADDRESS ]] && args+=(--www-address=$TOOL_ADDRESS)
[[ $TOOL_IFRAME_HOSTS ]] && args+=(--www-frame-origin=$TOOL_IFRAME_HOSTS)

echo "${args[@]}"
exec "${args[@]}"
