+++
categories = ['Laptop']
comments = false
date = '2024-07-06'
keywords = ['laptop']
showActions = false
showMeta = false
summary = 'Set up shortcuts for your terminal emulator'
tags = ['terminal']
title = 'Alacritty: escape sequence'
+++

For example, from your terminal, if you run `xxd -psd`  and press `ctrl-f v`  and then enter and finally `ctrl-c`  to exit, it outputs the following:

```sh
$ xxd -psd
^Fv
06760a^C
```

What matters is the sequence `06760a^C`. Let's split it every two characters:

```sh
06 -> ctrl-f
76 -> v
0a -> return
^C -> ctrl-c
```

From here, we know that `0x06 0x76` corresponds to `ctrl-f v`. This is the most important part. Once we have this, we can now tell Alacritty to use this escape sequence code. I use `cmd + d` to open a vertical pane, now we're going to tell Alacritty to invoke the above escape sequence.

To do this, we need to add a line to key_bindings field in alacritty.yml:

```sh
- { key: D, mods: Command, chars: "\x06\x76"  }
```

Now whenever you press `cmd + d` inside Alacritty, this will automatically be transformed into the escape sequence `\x06\x76` which then opens a vertical tab in tmux.

