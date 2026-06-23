-- Level 1: Basic movement (hjkl, w/b/e, gg/G)
-- Beginner tier: buffer state verified.
-- Challenges combine movement with a small edit (x or r) to make goal verifiable.
-- Cursor always starts at line 1, col 0 after buffer load.

return {
  {
    id = "l1_001",
    level = 1,
    description = "Move right 3 chars and delete the char under cursor.",
    hint1 = "Use `l` to move right one char at a time, then `x` to delete.",
    hint2 = "Press: l l l x",
    -- "helllo world": h(0)e(1)l(2)l(3)l(4)o. lll -> col3 = extra 'l'. x -> "hello world".
    setup_text = "helllo world",
    goal_text = "hello world",
    optimal_keystrokes = 4,
  },
  {
    id = "l1_002",
    level = 1,
    description = "Move right 2 chars, then left 1 char, then delete the char under cursor.",
    hint1 = "Use `l` to move right and `h` to move left, then `x` to delete.",
    hint2 = "Press: l l h x",
    -- "heello world": h(0)e(1)e(2)l(3). llh -> col1 = first extra 'e'. x -> "hello world".
    setup_text = "heello world",
    goal_text = "hello world",
    optimal_keystrokes = 4,
  },
  {
    id = "l1_003",
    level = 1,
    description = "Jump to the next word and delete the char under cursor.",
    hint1 = "Use `w` to jump forward to the start of the next word.",
    hint2 = "Press: w x",
    -- "hello Xworld": cursor 0. w -> start of 'Xworld' (col 6). x -> 'X' deleted -> "hello world".
    setup_text = "hello Xworld",
    goal_text = "hello world",
    optimal_keystrokes = 2,
  },
  {
    id = "l1_004",
    level = 1,
    description = "Jump to the next word, then back one word, then right 1 char, then replace the char with 'o'.",
    hint1 = "Use `w` forward, `b` back, `l` right, then `r` to replace.",
    hint2 = "Press: w b l r o",
    -- "wirld hello": cursor 0='w'. w->hello(col6). b->wirld(col0). l->col1='i'. ro -> "world hello".
    setup_text = "wirld hello",
    goal_text = "world hello",
    optimal_keystrokes = 5,
  },
  {
    id = "l1_005",
    level = 1,
    description = "Jump to the end of the current word and delete the char under cursor.",
    hint1 = "Use `e` to jump to the last char of the current word.",
    hint2 = "Press: e x",
    -- "hellox world": cursor 0. e -> end of 'hellox' = col5 = 'x'. x -> delete -> "hello world".
    setup_text = "hellox world",
    goal_text = "hello world",
    optimal_keystrokes = 2,
  },
  {
    id = "l1_006",
    level = 1,
    description = "Jump to the last line and replace its first char with 'p'.",
    hint1 = "Use `G` to jump to the last line, then `r` to replace a single char.",
    hint2 = "Press: G r p",
    -- "line one\nline two\nxass three": G -> line3 col0='x'. rp -> "pass three".
    setup_text = "line one\nline two\nxass three",
    goal_text = "line one\nline two\npass three",
    optimal_keystrokes = 3,
  },
  {
    id = "l1_007",
    level = 1,
    description = "Jump to the last line, then back to the first line, then delete the first char.",
    hint1 = "Use `G` to go to the last line and `gg` to return to the first.",
    hint2 = "Press: G g g x",
    -- "Xhello\nline two\nline three": G -> line3. gg -> line1 col0='X'. x -> "hello\nline two\nline three".
    setup_text = "Xhello\nline two\nline three",
    goal_text = "hello\nline two\nline three",
    optimal_keystrokes = 4,
  },
}
