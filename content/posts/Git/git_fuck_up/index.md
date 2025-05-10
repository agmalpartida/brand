---
Title: "Git Fuck Up"
date: 2025-01-19
categories:
- Git
tags:
- git
keywords:
- git
summary: "Git terror moments"
comments: false
showMeta: false
showActions: false
---

# I committed and immediately realized I need to make one small change!

```sh
# make your change
git add . # or add individual files
git commit --amend --no-edit
# now your last commit contains that change!
# WARNING: never amend public commits
```

You could also make the change as a new commit and then do rebase -i in order to squash them both together, but this is about a million times faster.

**Warning**: You should never amend commits that have been pushed up to a public/shared branch! Only amend commits that only exist in your local copy or you're gonna have a bad time.


# I accidentally committed something to master that should have been on a brand new branch!

```sh
# create a new branch from the current state of master
git branch some-new-branch-name
# remove the last commit from the master branch
git reset HEAD~ --hard
git checkout some-new-branch-name
# your commit lives in this branch now 
```

**Note**: this doesn't work if you've already pushed the commit to a public/shared branch, and if you tried other things first, you might need to git reset HEAD@{number-of-commits-back} instead of HEAD~.

# I accidentally committed to the wrong branch!

```sh
# undo the last commit, but leave the changes available
git reset HEAD~ --soft
git stash
# move to the correct branch
git checkout name-of-the-correct-branch
git stash pop
git add . # or add individual files
git commit -m "your message here";
# now your changes are on the correct branch
```

A lot of people have suggested using cherry-pick for this situation too, so take your pick on whatever one makes the most sense to you!

```sh
git checkout name-of-the-correct-branch
# grab the last commit to master
git cherry-pick master
# delete it from master
git checkout master
git reset HEAD~ --hard
```

# I tried to run a diff but nothing happened?!

If you know that you made changes to files, but diff is empty, you probably add-ed your files to staging and you need to use a special flag.

```sh
git diff --staged
```

# I need to undo my changes to a file!

```sh
# find a hash for a commit before the file was changed
git log
# use the arrow keys to scroll up and down in history
# once you've found your commit, save the hash
git checkout [saved hash] -- path/to/file
# the old version of the file will be in your index
git commit -m "Wow, you don't have to copy-paste to undo"
```

For real though, if your branch is sooo borked that you need to reset the state of your repo to be the same as the remote repo in a "git-approved" way.

```sh
# get the lastest state of origin
git fetch origin
git checkout master
git reset --hard origin/master
# delete untracked files and directories
git clean -d --force
# repeat checkout/reset/clean for each borked branch
```

