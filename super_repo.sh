#!/bin/bash
echo "start get android source code"

source .config
source .mirror/mirror.sh
# override the same config in mirror
source .config

count=0

function downloadRepo() {
   #echo "SUPER_MIRROR_DOWNLOAD_REPO_CMD = $SUPER_MIRROR_DOWNLOAD_REPO_CMD"
   download_url="$SUPER_MIRROR_DOWNLOAD_REPO_CMD repo"
   echo "download_url=$download_url"
   ${download_url}
}

function isNetworkConnected() {
   downloadRepo
   if [ $? -ne 0 ]; then
      echo "Your network is bad. Please check."
      return 1
   else
      echo "network connected."
   fi
}

function getRepoInitUrl() {
#   echo "fuc getRepoInitUrl enter"
   repo_init_url="./repo init -u $SUPER_MIRROR_MANI_URL  $SUPER_REPO_INIT_ARGS"
   echo "$repo_init_url"
}

function createRepo() {
    if [ ! -f repo ]; then
       echo "download repo..."
       downloadRepo
    else
       echo "repo already existed."
    fi
    chmod +x repo
}

function getSyncMode() {
   # 1 : fast mode; 0 : proxy mode
   mycount=$1
   if [ "$mycount" -gt 10 ]
   then
      ret=$(expr $mycount % 2)
      if [ 0 == "$ret" ] 
      then
         return 0
      else
         return 1
      fi 
   else
      return 1
   fi
}

function runRepoSync() {
   sleep 3
   count=$(($count+1))
   getSyncMode "$count"
   if [ 0 == $? ] 
   then
      # proxy mode
      echo "121121" | sudo -S sysctl -w net.ipv4.tcp_window_scaling=0
      j_ops=" -j1 "
   else
      # fast mode
      echo "121121" | sudo -S sysctl -w net.ipv4.tcp_window_scaling=1
      j_ops=" $SUPER_REPO_JOBS "
   fi
   win_scale=$(cat /proc/sys/net/ipv4/tcp_window_scaling)
   echo "count = $count j_ops=$j_ops tcp_window_scaling=$win_scale"
   #repo_sync="./repo sync $SUPER_REPO_SYNC"
   repo_sync="./repo sync $j_ops $SUPER_REPO_SYNC"
   echo "repo_sync=$repo_sync"
   ${repo_sync}
}

function setRepoUrl() {
   export REPO_URL=$SUPER_MIRROR_REPO_URL
}

function forceSetMirrorUrl(){
  # force replate url in .repo/manifests/
  echo "force set mirror url to manifest"
  # replace https://android.googlesource.com with mirror host 
  # For example: https://aosp.tuna.tsinghua.edu.cn
  find .repo/manifests/ -name *.xml | xargs sed -i -e "s#\(fetch=\"\)https://android.googlesource.com/\"#\1$SUPRE_MIRROR_HOST\"#g"

}

isNetworkConnected
if [ $? != 0 ]; then 
    exit 1
fi

createRepo
setRepoUrl

repo_init_url=$(getRepoInitUrl)
echo "repo_init_url=$repo_init_url"
${repo_init_url}

forceSetMirrorUrl

runRepoSync
while [ $? -ne 0 ]
do
   # clean temp file created when download failed.
   echo "Download failed. Clean temp files in .repo/project-objects/"
   find .repo/project-objects/ -name "tmp_*" | xargs rm -rf
   runRepoSync
done
echo "Download success."
