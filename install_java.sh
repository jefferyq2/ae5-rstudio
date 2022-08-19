#!/bin/bash

echo "+--------------------+"
echo "| AE5 Java Installer |"
echo "+--------------------+"

if [ ! -z "$CONDA_PREFIX" ]; then
    source deactivate 2>/dev/null
fi
java_loc=$(which java 2>/dev/null)
if [ "$java_loc" == "/usr/bin/java" ]; then
    echo 'ERROR: this script is intended for AE 5.6 or later.'
    exit -1
elif [[ "$java_loc" == /tools/java/* ]]; then
    echo 'ERROR: java is already installed. Remove /tools/java to reinstall.'
    exit -1
elif [[ -z "$TOOL_PROJECT_URL" || -z "$TOOL_HOST" || -z "$TOOL_OWNER" ]]; then
    echo 'ERROR: this script must be run within an AE5 session.'
    exit -1
elif [ ! -d /tools ]; then
    echo 'ERROR: this script requires the managed persistence /tools volume.'
    exit -1
elif [ -e /tools/java ]; then
    if [ ! -d /tools/java ]; then
        echo 'ERROR: /tools/java is not a directory.'
        exit -1
    elif [ ! -w /tools/java ]; then
        echo 'ERROR: /tools/java is not writable.'
        exit -1
    elif [ ! -z "$(ls -A /tools/java)" ]; then
        echo 'ERROR: /tools/java is not empty.'
        exit -1
    fi
elif ! mkdir -p /tools/java; then
    echo 'ERROR: the /tools/java directory could not be created.'
    exit -1
fi

if [ ! -z "$1" ]; then
    java_fn=$1
    if [ ! -f "$1" ]; then
        echo "ERROR: java tarball not found: $1"
        exit -1
    fi
fi
if [ -z "$java_fn" ]; then
    java_url=${JAVA_URL:-https://download.oracle.com/java/18/archive/jdk-18_linux-x64_bin.tar.gz}
    echo "Downloading: $java_url"
    java_fn=$(basename $java_url)
    if ! curl -L --output $java_fn $java_url; then
        echo "ERROR: could not download Java. To proceed manually:"
        echo "1. https://www.oracle.com/java/technologies/downloads/"
        echo "2. Download the JDK version you prefer, making sure to select the"
        echo "   Linux x64 Compressed Archive"
        echo "3. Upload that file to this project."
        echo "4. Re-run this script, supplying the name of the file as an argument."
        exit -1
    fi
fi
if ! tar tvf "$java_fn" >/dev/null; then
    echo "ERROR: tarball could not be verified: $java_fn"
    exit -1
fi

echo "Unpacking java..."
tar xf "$java_fn" -C /tools/java 

echo "+-----------------------+"
echo "Java installation is complete."
echo "Stop and restart your session to verify AE5 detects it."
echo "+-----------------------+"
