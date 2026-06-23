# nvim-practice: Neovim Learning Game — PRD

## Problem Statement

Developers who want to improve their Neovim proficiency have no structured, daily practice tool that fits naturally into their workflow. Existing resources like `:Tutor` are one-time reads, not repeated practice. vim-be-good and vim-adventures require leaving the terminal or are not designed around deliberate daily sessions. There is no tool that tracks which vim skills a developer has mastered, which still need work, and that automatically surfaces the right challenges each morning based on demonstrated proficiency.

---

## Solution

`nvim-practice` is a Neovim plugin that provides structured 15–30 minute daily practice sessions, launched directly from inside Neovim via `:NPractice`. Each session opens with spaced-repetition warmup challenges drawn from already-mastered skills, then advances to new challenges at the player's current difficulty level. The player progresses through 10 levels of vim proficiency — from basic movement to advanced macros and regex — unlocking the next level only after demonstrating consistent mastery of the current one. All game state persists between sessions using Neovim's standard data directory.

---

## User Stories

1. As a developer, I want to start a practice session with `:NPractice`, so that I can practice vim without leaving Neovim or opening a browser.
2. As a developer, I want my session to begin with warmup challenges from skills I've already learned, so that I can get my fingers warmed up before tackling new material.
3. As a developer, I want warmup challenges to be chosen based on which skills I'm weakest at or haven't practiced recently, so that I'm not wasting time on skills I've fully mastered.
4. As a developer, I want a floating HUD that shows my current challenge description and progress, so that I can focus on editing without navigating away from the buffer.
5. As a developer, I want the HUD to show my current keystroke count in real time, so that I know how efficiently I'm solving the challenge.
6. As a developer, I want to be able to move the HUD if it overlaps important content in my buffer, so that it never blocks what I'm trying to edit.
7. As a developer, I want beginner challenges to enforce specific keystroke sequences, so that I learn the right vim command for each situation rather than hacking around it.
8. As a developer, I want intermediate challenges to accept any keystroke sequence that produces the correct result, so that I'm graded on outcome rather than memorising one specific solution.
9. As a developer, I want advanced challenges to include a maximum keystroke limit, so that I'm incentivised to find and use the most efficient vim commands.
10. As a developer, I want a hint available when I'm stuck, so that I can unblock myself without abandoning the challenge.
11. As a developer, I want the first hint to appear automatically after 60 seconds of inactivity, so that I don't stay stuck indefinitely without realising help is available.
12. As a developer, I want to be able to request a hint manually with `<leader>?`, so that I can get help immediately when I know I'm stuck.
13. As a developer, I want a second, more specific hint to appear at 180 seconds or on a second `<leader>?` press, so that I get progressively more guidance without being given the answer immediately.
14. As a developer, I want using hints to affect my proficiency score on a challenge, so that challenges I needed help with stay in my warmup rotation longer.
15. As a developer, I want my session to end gracefully when 30 minutes have elapsed, finishing the challenge I'm currently on before stopping, so that I'm never cut off mid-problem.
16. As a developer, I want my session to also end when I've passed at least 5 new challenges, so that I have a clear sense of accomplishment even in short sessions.
17. As a developer, I want to progress to the next difficulty level automatically after passing 80% of the current level's challenges, so that the game pushes me forward when I'm ready.
18. As a developer, I want the game to track my average keystrokes per challenge, so that I can see whether my efficiency is improving over time.
19. As a developer, I want challenges where I failed or needed full hints to reappear the next day, so that I revisit weak areas immediately.
20. As a developer, I want challenges I've mastered (high streak, efficient keystrokes) to reappear less and less frequently, so that my warmup time focuses on what matters.
21. As a developer, I want my progress to be saved in Neovim's standard data directory, so that it survives if I update or reinstall the plugin.
22. As a developer, I want the plugin to be installable via lazy.nvim with a single line, so that setup is frictionless.
23. As a developer, I want level 1 challenges to cover basic movement (`hjkl`, `w/b/e`, `gg/G`), so that the game builds the most fundamental muscle memory first.
24. As a developer, I want level 2 challenges to cover entering and exiting insert and visual modes, so that mode-switching becomes automatic.
25. As a developer, I want level 3 challenges to cover basic operators (`d`, `c`, `y`, `p`, `x`, `r`), so that I learn to manipulate text before combining operators with motions.
26. As a developer, I want level 4 challenges to cover text objects (`iw`, `aw`, `i"`, `i(`, `ip`), so that I can target semantic units of text rather than navigating character by character.
27. As a developer, I want level 5 challenges to combine operators and motions (`dw`, `ci"`, `ya(`), so that I practice thinking in vim verbs.
28. As a developer, I want level 6 challenges to cover search (`/`, `n/N`, `*`, `#`, `f/t/;/,`) with literal patterns, so that I can navigate to content quickly.
29. As a developer, I want level 7 challenges to cover substitution (`:s`, `:%s`) with basic regex (`. * ^ $ \w`), so that I learn to edit text at scale.
30. As a developer, I want level 8 challenges to cover marks, registers, and macros, so that I can automate repetitive editing.
31. As a developer, I want level 9 challenges to cover efficiency patterns (`.` repeat, counts, `norm`, `:g/`) with advanced regex (`\v` very-magic, capture groups), so that I can solve complex edits in minimal keystrokes.
32. As a developer, I want level 10 challenges to cover windows, folds, and Neovim-specific features with complex regex patterns, so that I can use the full power of Neovim.
33. As a developer, I want regex complexity to increase gradually across levels 6–10 rather than all at once, so that I build regex skills alongside the vim commands they're paired with.
34. As a developer, I want my progress to be saved after every completed challenge, so that closing Neovim mid-session never loses completed work.
35. As a developer, I want an incomplete challenge (Neovim closed mid-attempt) to not count as a pass or fail, so that accidents don't corrupt my proficiency record.
36. As a developer, I want the HUD to show session progress (`Warmup 3/3 ✓  New 2/5`), so that I know how far through the session I am at a glance.
37. As a developer, I want to be able to skip a challenge with `:NPracticeSkip`, so that I can move on without being permanently blocked.
38. As a developer, I want a skipped challenge to count as a failed attempt in the spaced repetition system, so that skipping doesn't let me avoid weak areas indefinitely.

---

## Implementation Decisions

### Technology
- Implemented entirely in Lua as a standard Neovim plugin. No external runtime dependencies beyond Neovim itself.
- All runtime data stored in Neovim's standard data directory (`vim.fn.stdpath("data")`). No hardcoded paths — fully portable across any user's machine.

### Plugin Structure
- Standard Neovim plugin layout with `plugin/` (auto-loaded command registration) and `lua/nvim-practice/` (all game logic).
- Modules: session orchestration, challenge loading/validation, floating HUD, SM-2 progress tracking, warmup scoring.
- Challenge content defined as Lua tables in per-level files under `challenges/`.

### Challenge Data Model
Each challenge specifies: a unique ID, description, two progressive hint strings, initial buffer text (setup), goal buffer text, optionally a required keystroke sequence (beginner levels), optionally a max keystroke limit (advanced levels), and an optimal keystroke count (used for SM-2 efficiency scoring).

### Challenge Validation (three tiers)
- **Beginner (levels 1–5)**: enforce specific keystroke sequence AND verify goal buffer state.
- **Intermediate (levels 6–8)**: verify goal buffer state only; track keystroke count for SM-2.
- **Advanced (levels 9–10)**: verify goal buffer state AND enforce max keystroke limit.

Buffer state checked on every `TextChanged`/`TextChangedI` event. Keystrokes tracked via `vim.on_key`.

### Hint System
A per-challenge timer and manual keybind work together:
- At 60 seconds elapsed or first `<leader>?`: reveal `hint1` in HUD → outcome marked as sloppy (SM-2 interval unchanged).
- At 180 seconds elapsed or second `<leader>?`: reveal `hint2` (the full answer) → outcome marked as fail (SM-2 interval resets to 1 day).

Timer managed with `vim.defer_fn`; cancelled immediately on challenge completion.

### Session State Machine
```
START → [warmup: 3–5 SM-2 selected challenges]
       → [new_challenges: current level, not yet passed]
       → [complete: write progress, show summary]

Soft stop: 30 min elapsed + current challenge finished → END
Hard stop: 5 new challenges passed → END
```
Progress written to disk after each completed challenge. Closing Neovim mid-challenge = attempt not recorded.

### Spaced Repetition (SM-2)
Each challenge record stores: attempt count, pass count, streak, average keystrokes, optimal keystrokes, last-played date, interval in days, ease factor.

Warmup score formula:
```
score = (days_since_last_played / interval_days)
      + (avg_keystrokes / optimal_keystrokes)
      + (1 / (streak + 1))
```
Top 3–5 challenges by score are selected as warmup.

Post-attempt interval updates:
- Clean pass (no hints, under keystroke limit): `interval *= ease_factor`, ease increases.
- Sloppy pass (hint 1 used OR >50% of max keystrokes): interval and ease unchanged.
- Fail (hint 2 used OR wrong end state): `interval = 1 day`, ease decreases.

### Level Progression
- Next level unlocks when the player passes 80% of the current level's challenges across all sessions.
- Streak drives SM-2 interval only — does not gate level unlock.

### Floating HUD
- Created via `vim.api.nvim_open_win` with minimal style and rounded border.
- Default anchor: top-right corner. Configurable via setup option (`hud_position`).
- Shows: level + challenge number, description, current hint (if triggered), real-time keystroke counter, session progress.
- No timer displayed.
- Toggle keybind (`<leader>h`) to hide/show if HUD overlaps buffer content.
- **Implementation note**: validate HUD position against buffer content at multiple terminal widths; this is a known risk area.

### Public API
- Entry: `:NPractice` user command, registered on plugin load.
- Setup: `require("nvim-practice").setup({ hud_position = "top-right" })`.
- Skip: `:NPracticeSkip` user command.
- Installable via lazy.nvim pointing at the GitHub repo.

---

## Testing Decisions

Good tests for this plugin test external behaviour only — given inputs (a progress record, a challenge definition, a keystroke sequence), assert outputs (score, updated record, pass/fail verdict). Tests must not depend on internal module structure or implementation details.

### Modules to test

**SM-2 scoring and update functions** — The highest and most important seam. Pure Lua functions with zero Neovim dependency. Test that warmup scores rank challenges in the expected order, and that clean/sloppy/fail outcomes produce the correct `interval_days` and `ease_factor` updates. Runnable with `busted` alone.

**Challenge validation logic** — Function comparing current buffer text against goal state, and function validating a keystroke sequence against a required sequence. Pure string operations. Runnable with `busted` alone.

**Session state machine transitions** — Given a current state and an event (challenge passed, challenge failed, soft-stop fired), assert the correct next state and that the correct side effects (save, advance, end) are triggered. Runnable with `busted` alone.

**HUD and keystroke tracking** — Requires `vim.api` and `vim.on_key`. Integration-level tests using headless Neovim via `plenary.nvim` test harness.

### Prior art
No existing tests in the codebase (new project). Establish `busted` for pure unit tests and `plenary.nvim` for integration tests as the standard pattern.

---

## Out of Scope

- Multiplayer or leaderboard features.
- Cloud sync of progress data.
- Support for vim (non-Neovim) or other editors.
- In-game challenge editing or custom challenge creation by the player.
- A CLI entry point (`neovim-practice` shell command) — entry is via `:NPractice` inside Neovim only.
- Automated content generation — all challenges are hand-authored Lua tables.
- Time display in the HUD.

---

## Further Notes

- Regex is drip-fed across levels 6–10 rather than isolated in its own level. Each level introduces regex complexity that is natural to the commands being taught at that level.
- The 30-minute soft stop should feel invisible — the session ends after the current challenge completes, never mid-problem.
- HUD position overlapping the editing buffer is a known UX risk. During implementation, test at common terminal widths (80, 120, 160 columns) and ensure the toggle keybind is discoverable.
- Future consideration: once on GitHub, a community contribution guide for adding new challenges to level files would significantly expand the challenge pool without touching game logic.
