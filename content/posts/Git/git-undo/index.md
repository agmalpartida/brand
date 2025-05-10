---
Title: "Git Undo Changes"
date: 2024-11-16
categories:
- Git
tags:
- git
keywords:
- git
summary: "Git Undo Changes"
comments: false
showMeta: false
showActions: false
---

# Git
## Discard All Local Changes in the Working Directory

If you want to discard all uncommitted changes (modifications and untracked files) in your working directory:

```bash
git reset --hard
```

If you also have untracked files and want to delete them:

```sh
git clean -fd
```

- `-f` forces the cleaning.
- `-d` removes untracked directories.

## Discard Changes in a Specific File

If you only need to discard changes in a particular file:

```sh
git checkout -- filename
```

Or, in recent versions of Git:

```sh
git restore filename
```

## Discard All Changes in Tracked Files

To discard all changes in tracked files without affecting untracked files:

```sh
git restore .
```

## Revert Changes in the Staging Area

If you've already added files to the staging area (`git add`) but haven't committed yet and want to remove them from there:

```sh
git restore --staged filename
```

## Delete the Last Commit

If you've made a commit but haven't pushed it yet:

```sh
git reset --soft HEAD~1
```

This undoes the last commit while keeping the changes in your working directory.

If you want to undo the commit and delete the changes from the working directory:

```sh
git reset --hard HEAD~1
```
