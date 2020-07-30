#!/usr/bin/env bash
#
# To make it work:
#   brew install hub
#   hub browse
#
upstream_repo=`git remote get-url upstream | sed 's/git@github.com:\(.*\)\.git/\1/'`
upstream_br=`git symbolic-ref refs/remotes/upstream/HEAD | sed 's/refs\/remotes\/upstream\/\(.*\)/\1/'`
upstream="${upstream_repo}:${upstream_br}"

echo -n "Pull Request Title (empty for last commit msg): "
read title
last_commit_title=`git --no-pager log -1 --pretty=format:%s`
title=${title:-$last_commit_title}

topic_branch=`git rev-parse --abbrev-ref HEAD`
git push --set-upstream origin ${topic_branch}

hub pull-request -b ${upstream} -F - > /tmp/last_pr_url <<MSG
${title}
`cat PULL_REQUEST_TEMPLATE 2> /dev/null`
MSG
pr_url=`cat /tmp/last_pr_url`
echo "Opening ${pr_url}"
open ${pr_url}