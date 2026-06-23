This is a completely vibe coded neovim plugin, everything beyond this diclaimer is written by AI. I have only tested its correctness as it pertains to my uses.

**end of human written content**

# nvim-practice

A Neovim plugin for structured daily vim practice sessions. It uses spaced repetition to surface weak spots, tracks your keystroke efficiency, and progresses you through 10 levels of challenges — from basic movement to advanced macros and regex.

## Requirements

- Neovim 0.8+
- No external dependencies

## Installation

**lazy.nvim**

```lua
{
  "your-github-username/neovim-practice-game",
  config = function()
    require("nvim-practice").setup()
  end,
}
```

**packer.nvim**

```lua
use {
  "your-github-username/neovim-practice-game",
  config = function()
    require("nvim-practice").setup()
  end,
}
```

## Configuration

```lua
require("nvim-practice").setup({
  hud_position = "top-right", -- "top-right" | "top-left" | "bottom-right" | "bottom-left"
})
```

All options are optional. Defaults are shown above.

## How it works

Each session runs for up to 30 minutes and consists of two phases:

1. **Warmup** — 3–5 previously-seen challenges, ranked by your spaced-repetition score. Challenges you struggled with appear first.
2. **New challenges** — 3–10 new challenges from your current level.

The session ends when you pass 5 new challenges or 30 minutes have elapsed (whichever comes later, at the end of the current challenge).

**Levels** progress from 1 (basic movement) to 10 (advanced macros/regex). You advance to the next level once you've passed 80% of that level's challenges.

**Scoring** after each challenge:

| Outcome | Condition |
|---|---|
| Clean | Completed with no hints and efficient keystrokes |
| Sloppy | Used the first hint |
| Fail | Used the second hint or reached the wrong goal state |

Your score determines when a challenge resurfaces: clean passes push it further into the future; fails bring it back sooner.

Progress is saved to `~/.local/share/nvim/nvim-practice/progress.json` after each challenge.

## Commands

| Command | Description |
|---|---|
| `:NPractice` | Start a practice session. Opens the challenge buffer and HUD. |
| `:NPracticeSkip` | Skip the current challenge. Counts as a failed attempt in spaced repetition, so skipped challenges resurface sooner. |

## Keymaps

These keymaps are active only during a practice session.

| Key | Description |
|---|---|
| `<leader>H` | Request a hint. First press reveals a partial hint; second press reveals the full answer. Both reduce your spaced-repetition score for the challenge. |
| `<leader>h` | Toggle the floating HUD on/off. Use this if the HUD overlaps content you need to see. |
| `q` / `<CR>` | Close the session summary screen at the end of a session. |

## Resetting a beginner challenge attempt

Beginner challenges (levels 1–5) require an exact keystroke sequence. If you press a wrong key, press `u` to undo back to the original buffer state — this resets your keystroke history so you can try again cleanly.
