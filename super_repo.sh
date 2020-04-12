#!/bin/bash
echo "start get android source code"

source .config

function downloadRepo() {
   if [ "$SUPER_REPO_MIRROR" = "$SUPER_MIRROR_USTC" ]; then
      curl -sSL  'https://gerrit-googlesource.proxy.ustclug.org/git-repo/+/master/repo?format=TEXT' | base64 -d > repo 
   else
       curl https://mirrors.tuna.tsinghua.edu.cn/git/git-repo -o repo
   fi
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
   MANIFEST_URL=
   if [ "$SUPER_REPO_MIRROR" = "$SUPER_MIRROR_USTC" ]; then
      MANIFEST_URL=$SUPER_MIRROR_MANI_USTC_URL 
   else
      MANIFEST_URL=$SUPER_MIRROR_MANI_TSING_HUA_URL
   fi
   repo_init_url="./repo init -u $MANIFEST_URL $SUPER_REPO_INIT_ARGS"
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

function runRepoSync() {
   repo_sync="repo sync $SUPER_REPO_SYNC"
   echo "$repo_sync"
   ${repo_sync}
}

function setRepoUrl() {
   if [ "$SUPER_REPO_MIRROR" = "$SUPER_MIRROR_USTC" ]; then
       export REPO_URL='https://gerrit-googlesource.proxy.ustclug.org/git-repo'
   else
       export REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/git/git-repo'
   fi
}

function forceSetMirrorUrl(){
  # force replate url in .repo/manifests/
  echo "force set mirror url to manifest"
  # replace https://android.googlesource.com with https://aosp.tuna.tsinghua.edu.cn
  find .repo/manifests/ -name *.xml | xargs sed -i -e "s#\(fetch=\"\)https://android.googlesource.com/\"#\1https://aosp.tuna.tsinghua.edu.cn\"#g"

}

isNetworkConnected
if [ $? != 0 ]; then 
    return 1
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
    runRepoSync
done

# clean temp file created when download failed.
echo "Download success. Clean temp files in .repo/project-objects/"
find .repo/project-objects/ -name "tmp_*" | xargs rm
