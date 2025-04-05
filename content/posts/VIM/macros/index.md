---
Title: "VIM Macros"
date: 2025-04-05
categories:
- VIM
tags:
- vim
keywords:
- vim
- macros
summary: ""
comments: false
showMeta: false
showActions: false
---

# Macros

A macro in Vim is simply a sequence of recorded commands.

- Q – Starts recording a macro. Perform actions, then press Q again to stop recording.
- @a – Replays the macro recorded in register a.

## 🛠 Editing a Macro

1.  Create a new buffer:

```sh
:new
```

2. Paste the contents of the macro from register a:

```sh
:put a
```

3. Edit the macro content:

- A – Move to end of line in normal mode.
- ^[ (Escape) – Exit insert mode.
- J – Join the line with the one below.

4. View all registers:

```sh
:reg
```

5. Copy and paste the edited text back into register a:

- "ayy – Copy the current line into register a.

6. Run the updated macro:

```sh
@a
```
