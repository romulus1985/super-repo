#!/bin/bash
echo "PWD=$PWD $0=$0"
dirname=$(dirname $0)
#echo "dirname = $dirname"
mirror_config=".mirror/$SUPER_REPO_MIRROR".conf
echo "mirror_config = $mirror_config"
if [ -f  "$mirror_config" ]; then
    echo "Using $mirror_config"
    source "$mirror_config"
else
    echo "Using default: tsinghua"
    source tsinghua.config
fi