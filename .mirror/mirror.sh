#!/bin/bash

#echo "PWD=$PWD $0=$0"
# dirname=$(dirname $0)
#echo "dirname = $dirname"
mirror_config=".mirror/$SUPER_REPO_MIRROR".conf
# echo "mirror_config = $mirror_config"

if [ -f "$mirror_config" ]; then
    used_config=$mirror_config
else
    used_config=.mirror/tsinghua.conf
fi
echo "Using $used_config"

source "$used_config"
