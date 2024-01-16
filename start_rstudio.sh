#!/bin/bash

echo "+-- START: AE5 RStudio Startup ---"
TOOL_HOME=$(dirname "${BASH_SOURCE[0]}")

# Determine which R environment to start with. Ideally, the project
# environment is ready in which case it can be selected. But if it is
# not, we must select an existing environment, because RStudio requires
# one to exist when the it starts
source $TOOL_HOME/configure_env.sh

args=($TOOL_HOME/bin/rserver --rsession-path $TOOL_HOME/rsession.sh \
      --auth-none=1 --auth-validate-users=0 --auth-minimum-user-id=1 \
      --server-working-dir=$HOME --server-user=$(id -un))

# Translate AE environment variables to Rstudio command-line arguments
[[ $TOOL_PORT ]] && args+=(--www-port=$TOOL_PORT)
[[ $TOOL_ADDRESS ]] && args+=(--www-address=$TOOL_ADDRESS)
[[ $TOOL_IFRAME_HOSTS ]] && args+=(--www-frame-origin=$TOOL_IFRAME_HOSTS)

cmd="${args[@]}"
echo @Running: $cmd@ | fold -s | sed 's/^/  /;s/$/\\/;s/^  @//;s/@\\//;s/^/| /'
echo "+-- END: AE5 RStudio Startup ---"
exec $cmd
