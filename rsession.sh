#!/bin/bash

echo "+-- START: AE5 R Session Manager ---"

# This environment must have an R installation
CONDA_FALLBACK_ENV=anaconda50_r

OC=/opt/continuum
OCA=$OC/anaconda
OCP=$OC/project
OCAB=$OCA/bin
OCLB=$OCA/envs/lab_launch/bin

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
export CONDA_DESIRED_ENV=$(cd $OC/project && $OCLB/anaconda-project list-env-specs </dev/null | grep -A1 ^= | tail -1)
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

# RStudio strips out much of the environment before launching the R console
# and shell terminals. We need the CONDA variables if we want to use conda on
# the command line. The PATH variable is not always preserved either. By putting
# these variables in .Renviron we ensure they will be restored.
echo "| Writing CONDA_*/PATH environment variables to .Renviron"
env | sed -nE 's@^(CONDA[^=]*|PATH)=(.*)@\1="\2"@p' > ~/.Renviron

# We need to add $CONDA_PREFIX/lib in LD_LIBRARY_PATH for rsession
# $CONDA_PREFIX/lib/R/lib is already in there by virtue of activation
echo "| Adding CONDA_PREFIX/lib to LD_LIBRARY_PATH"
export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH

echo "| Final environment: $CONDA_DEFAULT_ENV"
echo "|   CONDA_PREFIX: $CONDA_PREFIX"
echo "|   R_HOME: $R_HOME"
echo "|   PATH: $PATH"
echo "|   LD_LIBRARY_PATH: $LD_LIBRARY_PATH"

echo "| Arguments: $@"
echo "+-- END: AE5 R Session Manager ---"
exec /usr/lib/rstudio-server/bin/rsession "$@"
