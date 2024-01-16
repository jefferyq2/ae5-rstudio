TOOL_HOME=$(dirname "${BASH_SOURCE[0]}")

path_echo() {
    echo "$@" | sed \
        -e "s@$CONDA_PREFIX@\$CONDA_PREFIX@g" \
        -e "s@$CONDA_ROOT@\$CONDA_ROOT@g" \
        -e "s@$JAVA_HOME@\$JAVA_HOME@g" \
        -e "s@/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin@<system>@"
}

if [ -f /tmp/.rstudio_environment ]; then
    # RStudio strips out most environment variables before calling
    # rsession for some reason, which means users do not see them
    # either. This restores them for our purposes.
    while read -r line; do
        export ${line%%=*}="${line#*=}"
    done < /tmp/.rstudio_environment
fi

env_info=$($CONDA_PYTHON_EXE $TOOL_HOME/default_env.py $PWD)
if [ "$env_info" = "$CONDA_DESIRED_ENV $CONDA_DEFAULT_ENV $RSTUDIO_DEFAULT_R_VERSION" ]; then
    echo "| CONDA_PREFIX: $CONDA_PREFIX"
    # return when sourced; exit when run standalone for testing
    return 2>/dev/null || exit
fi

CONDA_DESIRED_ENV=$(echo $env_info | cut -d ' ' -f 1)
active_env=$(echo $env_info | cut -d ' ' -f 2)
active_ver=$(echo $env_info | cut -d ' ' -f 3)
echo "| Current environment: $CONDA_DEFAULT_ENV"
echo "| Project environment: $CONDA_DESIRED_ENV"
echo "| Startup environment: $active_env ($active_ver)"

OLD_PREFIX=$CONDA_PREFIX
if [ "$CONDA_DEFAULT_ENV" != "$active_env" ]; then
    echo "| Activating: $active_env"
    source $CONDA_ROOT/bin/activate $active_env
fi

if [[ "$OLD_PREFIX" != "$CONDA_PREFIX" && -f "$OLD_PREFIX/bin/R" ]]; then
    # Make sure all old references to the old environment are gone
    PATH=$(echo $PATH | sed "s@$OLD_PREFIX/bin:@@g")
    LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | sed "s@$OLD_PREFIX/lib[^:]*:@@g")
    # This is intended to rewrite RStudio-generated variables
    vars=$(env | sed -nE "s@$OLD_PREFIX/@$CONDA_PREFIX/@gp")
    while read -r line; do
        export ${line%%=*}="${line#*=}"
    done <<< "$vars"
fi

echo "| CONDA_DESIRED_ENV: $CONDA_DESIRED_ENV"
echo "| CONDA_DEFAULT_ENV: $CONDA_DEFAULT_ENV"
echo "| CONDA_PREFIX: $CONDA_PREFIX"
echo "| CONDA_ROOT: $CONDA_ROOT"
[ -n "$JAVA_HOME" ] && echo "| JAVA_HOME: $JAVA_HOME"
path_echo "| PATH: $PATH"
export CONDA_DEFAULT_ENV CONDA_DESIRED_ENV CONDA_PREFIX PATH LD_LIBRARY_PATH

# Ensure rsession sees all of the currently available environment variables
export RSTUDIO_DEFAULT_R_VERSION=$active_ver
export RMARKDOWN_MATHJAX_PATH=$TOOL_HOME/resources/mathjax-27
export RS_RPOSTBACK_PATH=$TOOL_HOME/bin/rpostback
export R_PROFILE=$TOOL_HOME/Rprofile

# Save the current environment for the next potential rsession start
env > /tmp/.rstudio_environment
