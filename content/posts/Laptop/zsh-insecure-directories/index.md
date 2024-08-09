---
Title: "ZSH Troubleshooting"
date: 2024-07-14
categories:
- Laptop
tags:
- zsh
keywords:
- zsh
summary: ""
comments: false
showMeta: false
showActions: false
---

## ZSH insecure directories

```sh
zsh compinit: insecure directories, run compaudit for list.
Ignore insecure directories and continue [y] or abort compinit [n]? ncompinit: initialization aborted
```

```sh
❯ cd /usr/local/share/zsh

sudo chmod -R 755 ./site-functions

sudo chown -R root:root ./site-functions

❯ compaudit
There are insecure directories:
/home/alberto/zsh/completions/rg
/home/alberto/zsh/completions/eza
/home/alberto/zsh/pure
/home/alberto/zsh/completions
/home/alberto/zsh/completions
/home/alberto/zsh


```
