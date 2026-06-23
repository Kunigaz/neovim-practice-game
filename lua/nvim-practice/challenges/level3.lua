-- Level 3: Basic operators (d/c/y/p/x/r)
-- Beginner tier: buffer state verified.
-- \27 = Esc (for change operator which enters insert mode).

return {
  {
    id = "l3_001",
    level = 3,
    description = "Delete the word at the cursor.",
    hint1 = "Use `dw` to delete from cursor to start of next word.",
    hint2 = "Press: d w",
    -- "error: something went wrong": cursor 0. dw deletes 'error' + trailing space -> "something went wrong".
    -- Actually dw from 'e' deletes up to (not including) next word start: "error " -> " something..." No.
    -- dw deletes from cursor to start of next word (exclusive). "error " deleted, leaves "something went wrong". YES.
    setup_text = "error something went wrong",
    goal_text = "something went wrong",
    optimal_keystrokes = 2,
  },
  {
    id = "l3_002",
    level = 3,
    description = "Delete the entire current line.",
    hint1 = "Use `dd` to delete the whole line.",
    hint2 = "Press: d d",
    -- "remove this\nkeep this": dd -> line 1 deleted -> "keep this".
    setup_text = "remove this\nkeep this",
    goal_text = "keep this",
    optimal_keystrokes = 2,
  },
  {
    id = "l3_003",
    level = 3,
    description = "Change the word at the cursor to 'bar'.",
    hint1 = "Use `cw` to change from cursor to start of next word, then type the replacement.",
    hint2 = "Press: c w b a r Esc",
    -- "foo baz": cursor 0. cw -> delete 'foo ' and enter insert. type 'bar '. Esc.
    -- Wait: cw deletes 'foo' (to next word boundary) and enters insert. Then type 'bar'. Esc.
    -- cw from 'f' deletes 'foo' leaving cursor before ' baz'. Type 'bar'. Esc -> "bar baz". YES.
    setup_text = "foo baz",
    goal_text = "bar baz",
    optimal_keystrokes = 6,
  },
  {
    id = "l3_004",
    level = 3,
    description = "Replace the char under cursor with 'X'.",
    hint1 = "Use `r` to replace a single char without entering insert mode.",
    hint2 = "Press: r X",
    -- "aXXXX value": cursor 0='a'. rX -> "XXXXX value". Hmm not great.
    -- "?ello world": cursor 0='?'. rh -> "hello world". YES.
    setup_text = "?ello world",
    goal_text = "hello world",
    optimal_keystrokes = 2,
  },
  {
    id = "l3_005",
    level = 3,
    description = "Delete the char under cursor.",
    hint1 = "Use `x` to delete the char under the cursor.",
    hint2 = "Press: x",
    -- "Xhello": cursor 0='X'. x -> "hello". YES.
    setup_text = "Xhello",
    goal_text = "hello",
    optimal_keystrokes = 1,
  },
  {
    id = "l3_006",
    level = 3,
    description = "Yank (copy) the current line then paste it below.",
    hint1 = "Use `yy` to yank the line, then `p` to paste it below.",
    hint2 = "Press: y y p",
    -- "hello\nworld": yyp on line1 -> "hello\nhello\nworld". YES.
    setup_text = "hello\nworld",
    goal_text = "hello\nhello\nworld",
    optimal_keystrokes = 3,
  },
  {
    id = "l3_007",
    level = 3,
    description = "Delete from cursor to end of line.",
    hint1 = "Use `D` to delete from the cursor position to end of line.",
    hint2 = "Press: D",
    -- "hello TRASH": cursor 0. D -> deletes whole line content = "". Not great.
    -- Need cursor partway. "hello TRASH": cursor 0. wwD? Too many keys.
    -- Better: move cursor to space with l then D.
    -- "hello TRASH": lllllD -> col5=' '. D deletes from col5 to end -> "hello". YES. 6 keys.
    setup_text = "hello TRASH",
    goal_text = "hello",
    optimal_keystrokes = 6,
  },
  {
    id = "l3_008",
    level = 3,
    description = "Change the current line to 'done'.",
    hint1 = "Use `cc` to change the entire line, then type the new content.",
    hint2 = "Press: c c d o n e Esc",
    -- "old content": cc -> delete line content, enter insert. type 'done'. Esc -> "done". YES.
    setup_text = "old content",
    goal_text = "done",
    optimal_keystrokes = 7,
  },
}
