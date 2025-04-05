---
Title: "VIM Quick Reference"
date: 2024-12-14
categories:
- VIM
tags:
- vim
keywords:
- vim
summary: ""
comments: false
showMeta: false
showActions: false
---

## Help

```
:h jumplist
```

## Navigation & Repetition

- f{s} – Jumps to the next occurrence of the character {s} in the current line.
- 4ft – Moves the cursor to the 4th occurrence of the character t on the current line.
- ; – Repeats the last character-finding command (like f, t, etc.).
- , – Repeats the last character-finding command in the opposite direction.
- . – Repeats the last action (works with any command: delete, paste, change, etc.).
- == – Auto-indents the current line.
- zz – Scrolls the document so that the current line is centered on screen.

## Copy & Paste

- yw – Yanks (copies) a word.
- Shift + P – Pastes before the cursor.

## Editing

- Shift + R – Enters Replace Mode, overwriting characters as you type.
- Ctrl + R – Redoes the last undone change.
- diw – Deletes in the current word:
    - d = delete
    - i = inner (can also be a for "around")
    - w = word (can also be ", {, etc.)

- daw – Deletes around the current word (requires plugin: nvim-treesitter-textobjects).
- ci( – Changes inside parentheses (removes content and enters insert mode).
- yip – Yanks (copies) an entire paragraph.
- Shift + W – Moves forward by non-whitespace-separated words.
- Shift + V – Visually selects the entire line.

## Split windows

- C-w w switches between 2 open windows.

  - C-w s opens a new split window.
  - C-w w switches between open windows.
  - C-w o keeps the current window and closes the rest.
  - C-w c closes the current window.

