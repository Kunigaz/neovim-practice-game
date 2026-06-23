-- Level 2: Insert and visual modes (i/I/a/A/o/O, Esc, v/V)
-- Beginner tier: buffer state verified.
-- \27 = Esc (raw byte as produced by vim.on_key).

return {
  {
    id = "l2_001",
    level = 2,
    description = "Append ' world' to the end of the first line.",
    hint1 = "Use `A` to jump to end of line and enter insert mode.",
    hint2 = "Press: A (space) w o r l d Esc",
    -- "hello": A -> insert at end. type ' world'. Esc -> normal.
    -- goal: "hello world"
    setup_text = "hello",
    goal_text = "hello world",
    optimal_keystrokes = 8,
  },
  {
    id = "l2_002",
    level = 2,
    description = "Insert 'TODO: ' at the very start of line 2.",
    hint1 = "Use `j` to move down, then `I` to insert at the start of the line.",
    hint2 = "Press: j I T O D O : (space) Esc",
    -- "fix bug\nremove it": j -> line2. I -> insert at col0. type 'TODO: '. Esc.
    -- goal: "fix bug\nTODO: remove it"
    setup_text = "fix bug\nremove it",
    goal_text = "fix bug\nTODO: remove it",
    optimal_keystrokes = 9,
  },
  {
    id = "l2_003",
    level = 2,
    description = "Open a new line below the current line and type 'done'.",
    hint1 = "Use `o` to open a new line below and enter insert mode.",
    hint2 = "Press: o d o n e Esc",
    -- "task one": o -> new line below, insert. type 'done'. Esc.
    -- goal: "task one\ndone"
    setup_text = "task one",
    goal_text = "task one\ndone",
    optimal_keystrokes = 6,
  },
  {
    id = "l2_004",
    level = 2,
    description = "Open a new line above the current line and type 'start'.",
    hint1 = "Use `O` to open a new line above and enter insert mode.",
    hint2 = "Press: O s t a r t Esc",
    -- "end task": O -> new line above, insert. type 'start'. Esc.
    -- goal: "start\nend task"
    setup_text = "end task",
    goal_text = "start\nend task",
    optimal_keystrokes = 7,
  },
  {
    id = "l2_005",
    level = 2,
    description = "Insert a char 'X' after the cursor (append in place).",
    hint1 = "Use `a` to enter insert mode one char after the cursor.",
    hint2 = "Press: a X Esc",
    -- "fobar": a -> insert after 'f', type 'o', Esc -> "foobar".
    setup_text = "fobar",
    goal_text = "foobar",
    optimal_keystrokes = 3,
  },
  {
    id = "l2_006",
    level = 2,
    description = "Use insert mode to fix the typo: change 'helo' to 'hello'.",
    hint1 = "Navigate to the missing char position, then use `i` to enter insert mode.",
    hint2 = "Press: l l l i l Esc",
    -- "helo world": cursor 0. lll -> col3='o'. i -> insert before 'o'. type 'l'. Esc -> "hello world".
    setup_text = "helo world",
    goal_text = "hello world",
    -- lll -> col3='o'. i -> insert before 'o'. type 'l'. Esc -> "hello world".
    optimal_keystrokes = 6,
  },
}
