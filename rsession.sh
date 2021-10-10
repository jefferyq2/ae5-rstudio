#!/bin/bash

echo "+-- START: AE5 R Session Manager ---"

TOOL_HOME=$(dirname "${BASH_SOURCE[0]}")
echo "| RStudio home: $TOOL_HOME"
echo "| User home: $HOME"

# This must be the name of an environment guaranteed to have a
# valid R installation, so that in case of user error RStudio
# knows where to find at least one valid R environment.
CONDA_FALLBACK_ENV=anaconda50_r

OCA=$HOME/anaconda
OCP=$HOME/project
OCAB=$OCA/bin
OCCB=$OCA/condabin

# RStudio strips out most environment variables before calling
# rsession, for some reason. We want at least the CONDA environment
# to be visible to R, so start_rstudio.sh puts them here
while read -r line; do
    eval "export $line"
done < ~/.Renviron

# If the previous conda environment has R we can use it as the fallback.
# That way if someone changes the environment to one without R, at least
# it will fall back to the one they were using previously.
[ -x $CONDA_PREFIX/lib/R/lib/libR.so ] && CONDA_FALLBACK_ENV=$CONDA_DEFAULT_ENV

# Our log display in Ops Center strips out leading spaces. Adding the non-space
# prefix allows us to better read the results
echo "| Current environment: $CONDA_DEFAULT_ENV"
echo "|   CONDA_PREFIX: $CONDA_PREFIX"
echo "|   R_HOME: $R_HOME"
echo "|   PATH: $PATH"
echo "|   LD_LIBRARY_PATH: $LD_LIBRARY_PATH"

# Now determine the environment dictacted by the project, as
# given by the first environment in anaconda-project.yml. If
# this file is broken, we revert to the fallback environment
export CONDA_DESIRED_ENV=$(cd $OCP && $OCCB/anaconda-project list-env-specs </dev/null | grep -A1 ^= | tail -1)
if [ "$CONDA_DESIRED_ENV" ]; then
    echo "| Target environment: $CONDA_DESIRED_ENV"
else
    echo "| Missing or corrupt anaconda-project.yml"
    export CONDA_DESIRED_ENV=$CONDA_FALLBACK_ENV
    export CONDA_PROJECT_ERR=yes
fi

# Switch environments if necessary
if [ "$CONDA_DESIRED_ENV" == "$CONDA_DEFAULT_ENV" ]; then
    echo "| No environment change needed"
else
    # In theory we should only need source activate here. But for some reason
    # the activate/deactivate scripts are failing and LDFLAGS is not changed
    # when it should be. This matters below because LDFLAGS may contain paths
    # that point to the old environment.
    source $OCAB/deactivate
    unset LDFLAGS
    if source $OCAB/activate $CONDA_DESIRED_ENV; then
        echo "| Activation of environment succeeded"
    else
        echo "| ERROR: Activation of environment failed"
    fi
fi

# Return to the fallback environment if the new environment does not have R
if [ ! -x "$CONDA_PREFIX/lib/R/lib/libR.so" ]; then
    echo "| ERROR: R not found; activating fallback environment"
    source $OCAB/activate $CONDA_FALLBACK_ENV
fi

# A number of the environment variables still point to the R environment that
# was visible to RStudio when it was first run. Modify those to point to the
# new environment so that the R process will be properly configured
if [ "$R_HOME" != "$CONDA_PREFIX/lib/R" ]; then
    echo "| Pointing R_HOME, etc. to the correct environment"
    R_PREFIX=$(dirname $(dirname $R_HOME))
    vars=$(env | sed -nE 's@^([^=]=)(.*)@\1"\2"@;/^CONDA/!'"s@$R_PREFIX/@$CONDA_PREFIX/@gp")
    while read -r line; do
        echo "|   $line"
        eval "export $line"
    done <<< "$vars"
else
    echo "| R_HOME is correct"
fi

# Make sure $CONDA_PREFIX/lib and $CONDA_PREFIX/lib/R/lib are in LD_LIBRARY_PATH
# RStudio actually adds $CONDA_PREFIX/lib/R/lib for us, but we overwrite that
# when we read in .Renviron above, so we're putting it back here again.
echo "| Adding CONDA_PREFIX libraries to LD_LIBRARY_PATH"
__tmp=$(echo $LD_LIBRARY_PATH: | sed "s@$CONDA_PREFIX/lib\(/R/lib\)\?:@@g")
export LD_LIBRARY_PATH=$CONDA_PREFIX/lib/R/lib:$CONDA_PREFIX/lib:${__tmp%:}

echo "| Final environment: $CONDA_DEFAULT_ENV"
echo "|   CONDA_PREFIX: $CONDA_PREFIX"
echo "|   R_HOME: $R_HOME"
echo "|   PATH: $PATH"
echo "|   LD_LIBRARY_PATH: $LD_LIBRARY_PATH"

# RStudio strips out much of the environment before launching the R console
# and shell terminals. We need the CONDA variables if we want to use conda on
# the command line. The PATH variable is not always preserved either. By putting
# these variables in .Renviron we ensure they will be restored. We also need
# NSS_WRAPPER_* and LD_PRELOAD passed through so that RStudio terminals can
# see the nss_wrapper-supplied username.
echo "| Writing environment variables to .Renviron"
export R_PROFILE=$TOOL_HOME/Rprofile
env | sed -nE 's@^([^=]*)=(.*)@\1="\2"@p' > ~/.Renviron
echo PS1='"('$(basename "$CONDA_PREFIX")') "' >> ~/.Renviron

# The installed version of RStudio uses OpenSSL 1.1, while our versions of R 3.5 use
# OpenSSL 1.0. Unfortunately RStudio doesn't realize this and dynamically links our R
# to their rsession binary in an incompatible way. To fix this we assume an OpenSSL 1.0
# version of rsession is available with the name "rsession10" and point it at our
# conda environment version of OpenSSL
RSESSION=rsession
if [[ -f $CONDA_PREFIX/lib/libssl.so.1.0.0 && -f $TOOL_HOME/bin/rsession10 ]]; then
    echo "| Using OpenSSL 1.0 version of rsession"
    ln -s $CONDA_PREFIX/lib/libssl.so $CONDA_PREFIX/lib/libssl.so.10 2>/dev/null || :
    ln -s $CONDA_PREFIX/lib/libcrypto.so $CONDA_PREFIX/lib/libcrypto.so.10 2>/dev/null || :
    RSESSION=rsession10
fi

echo "| Running: $RSESSION $@"
echo "+-- END: AE5 R Session Manager ---"
exec $TOOL_HOME/bin/$RSESSION "$@"
