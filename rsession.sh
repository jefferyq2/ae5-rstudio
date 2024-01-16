#!/bin/bash

TOOL_HOME=$(dirname "${BASH_SOURCE[0]}")

# When activation is slow, RStudio will assume the launched session has
# died and attempt to launch another. RStudio doesn't care, however, if
# the new process or the old actually finishes and grabs the socket. So
# this establishes a simple process queue. If for some reason an earlier
# process fails, the next one on the list will attempt.
pidfile=$RS_SESSION_TMP_DIR/rsession.sh.pid
echo $$>>$pidfile
first=yes
while read -r pid; do
    [ $pid == $$ ] && break
    first=no
    echo "| New pid $$ waiting"
    while ps -p $pid &>/dev/null; do
        sleep 3
        pid2="$(cat $HOME/.local/share/rstudio/sources/session-*/lock_file 2>/dev/null || :)"
        [ -n "$pid2" ] && exit 0
    done
done <$pidfile

[ $first = yes ] && echo "+-- START: AE5 R Session Manager ---"
echo "| Lock obtained for pid $$"

# This which R environment to start with. Ideally, the project
# environment is ready in which case it can be selected. But if it is
# not, we must select an existing environment, because RStudio requires
# one to exist when the it starts
source $TOOL_HOME/configure_env.sh

pid="$(cat $HOME/.local/share/rstudio/sources/session-*/lock_file 2>/dev/null || :)"
if [ -n "$pid" ] && ps -p $pid &>/dev/null; then
    echo "| Session already running; exiting."
    echo "+-- END: AE5 R Session Manager ---"
    exit 0
fi

# Make sure $CONDA_PREFIX/lib and $CONDA_PREFIX/lib/R/lib are in LD_LIBRARY_PATH
# RStudio actually adds $CONDA_PREFIX/lib/R/lib for us, but configure_env.sh
# might overwrite that, so we're putting it back here again.
LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | sed -E "s@$CONDA_PREFIX/lib[^:]*(:|$)@@g")
[ -n "$JAVA_HOME" ] && LD_LIBRARY_PATH="$JAVA_HOME/lib/server:$LD_LIBRARY_PATH"
LD_LIBRARY_PATH=$CONDA_PREFIX/lib/R/lib:$CONDA_PREFIX/lib:$LD_LIBRARY_PATH
if ! grep -aq "GLIBCXX_3.4.29" $CONDA_PREFIX/lib/libstdc++.so; then
    echo "| Older libstdc++ detected; using correction"
    LD_LIBRARY_PATH=/lib64:$LD_LIBRARY_PATH
fi
path_echo "| LD_LIBRARY_PATH: $LD_LIBRARY_PATH"

args=($TOOL_HOME/bin/rsession \
      --session-default-working-dir /opt/continuum/project \
      --session-rprofile-on-resume-default 1 \
      --r-resources-path $TOOL_HOME/resources \
      --r-core-source $TOOL_HOME/R \
      --r-modules-source /tools/rstudio/R/modules \
      --external-quarto-path /tools/rstudio/bin/quarto \
      --external-pandoc-path /tools/rstudio/bin/tools \
      --external-node-path /tools/rstudio/bin/nodejs)
cmd="${args[@]} $@"
echo @Running: $cmd@ | fold -s | sed 's/^/  /;s/$/\\/;s/^  @//;s/@\\//;s/^/| /'
echo "+-- END: AE5 R Session Manager ---"
rm $pidfile
exec $cmd
