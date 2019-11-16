#!/bin/bash

OC=/opt/continuum
OCP=$OC/project
OCAB=$OC/anaconda/bin

# RStudio strips out most environment variables before calling
# rsession, for some reason. We want at least the CONDA environment
# to be visible to R, so start_rstudio.sh puts them here
if [ -e ~/.Renviron ]; then
  while read -r line; do
    eval export $line
  done < ~/.Renviron
fi

# Determine the fallback environment. This is a failsafe environment
# that we can depend on having R. If the current environment happens
# to satisfy that condition, great; otherwise use a hardcoded choice
echo "- environment: $CONDA_PREFIX ($CONDA_DEFAULT_ENV)"
echo "- path: $PATH"
CONDA_FALLBACK_ENV=$CONDA_DEFAULT_ENV
OLD_PFX=$CONDA_PREFIX/

# Now determine the environment dictacted by the project, as
# given by the first environment in anaconda-project.yml. If
# this file is broken, we revert to the fallback environment
if [ -e $OCP/anaconda-project.yml ]; then
    CONDA_DESIRED_ENV=$(cd $OC/project && $OCAB/anaconda-project list-env-specs </dev/null | grep -A1 ^= | tail -1)
    if [ "$CONDA_DESIRED_ENV" == "" ]; then
        echo "- corrupt anaconda-project.yml, defaulting to $CONDA_DEFAULT_ENV"
    else
        echo "- target environment: $CONDA_DESIRED_ENV"
    fi
else
    echo "- no anaconda-project.yml, defaulting to $CONDA_DEFAULT_ENV"
fi

# Switch environments if necessary. However, if the new environment
# does not have R, we need to switch to the fallback.
if [ "$CONDA_DESIRED_ENV" == "$CONDA_DEFAULT_ENV" ]; then
    echo "- no environment change needed"

elif source $OCAB/activate $CONDA_DESIRED_ENV 2>/dev/null; then
    echo "- activation of environment $CONDA_DESIRED_ENV succeeded"
    echo "- environment: $CONDA_PREFIX ($CONDA_DEFAULT_ENV)"
    echo "- path: $PATH"

else
    echo "- activation of environment $CONDA_DESIRED_ENV failed"
fi

if [ "$(which R)" == "" ]; then
    echo "- R not found; reverting activation"
    source $OCAB/activate $CONDA_FALLBACK_ENV 
fi

# Update the R_HOME-based environment variables
NEW_PFX=$CONDA_PREFIX/
if [ "$OLD_PFX" != "$NEW_PFX" ]; then
    echo "- pointing environment variables to the new environment"
    # export LD_LIBRARY_PATH=$NEW_PFX/lib/R/lib
    while read -r line; do
        echo "  " $line; eval export $line
    done <<< $(env | sed -n "s@$OLD_PFX@$NEW_PFX@p")
    echo "- finished environment translation"
    
    # Rewrite the .Renviron file
    env | grep CONDA > ~/.Renviron
    echo PATH=$PATH >> ~/.Renviron
fi

# Add CONDA_DESIRED_ENV to the environment as well
echo CONDA_DESIRED_ENV=$CONDA_DESIRED_ENV >> ~/.Renviron

# Now launch the original rsession, which should now use our
# selected R environment
exec /usr/lib/rstudio-server/bin/rsession "$@"

