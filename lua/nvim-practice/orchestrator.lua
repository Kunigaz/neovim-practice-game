-- orchestrator.lua
-- Top-level session wiring. Requires Neovim API.

local M = {}

local progress   = require("nvim-practice.progress")
local sm2        = require("nvim-practice.sm2")
local validation = require("nvim-practice.validation")
local session    = require("nvim-practice.session")
local tracker    = require("nvim-practice.tracker")
local hud        = require("nvim-practice.hud")

-- ---------------------------------------------------------------------------
-- Module-level state (singleton)
-- ---------------------------------------------------------------------------

local state = {
  session           = nil,   -- session state table
  tracker_handle    = nil,
  current_challenge = nil,
  soft_stop_timer   = nil,
  all_challenges    = nil,   -- flat list of all challenge tables
  hud_opts_base     = nil,   -- static HUD opts (position, totals)
  practice_buf      = nil,   -- dedicated scratch buffer for challenges
}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function today()
  return os.date("%Y-%m-%d")
end

-- Fisher-Yates shuffle (in-place)
local function shuffle(t)
  for i = #t, 2, -1 do
    local j = math.random(1, i)
    t[i], t[j] = t[j], t[i]
  end
end

-- Load all challenges from level files into a flat list
local function load_all_challenges()
  local all = {}
  for lvl = 1, 10 do
    local ok, challenges = pcall(require, "nvim-practice.challenges.level" .. lvl)
    if ok and type(challenges) == "table" then
      for _, ch in ipairs(challenges) do
        all[#all + 1] = ch
      end
    end
  end
  return all
end

-- Count challenges at a given level
local function challenges_at_level(all, level)
  local out = {}
  for _, ch in ipairs(all) do
    if ch.level == level then
      out[#out + 1] = ch
    end
  end
  return out
end

-- Find first incomplete level (pass_count < ceil(0.8 * count_in_level))
local function current_level(all_challenges, records)
  for lvl = 1, 10 do
    local at_lvl = challenges_at_level(all_challenges, lvl)
    local threshold = math.ceil(0.8 * #at_lvl)
    local passed = 0
    for _, ch in ipairs(at_lvl) do
      local rec = records[ch.id]
      if rec and (rec.pass_count or 0) >= 1 then
        passed = passed + 1
      end
    end
    if passed < threshold then
      return lvl
    end
  end
  return 10
end

-- Build HUD opts from current session + challenge
local function build_hud_opts(challenge, hint_text)
  local sess = state.session
  local base = state.hud_opts_base or {}
  local keystroke_count = state.tracker_handle
    and tracker.get_count(state.tracker_handle)
    or 0

  -- Determine challenge_num in session (warmup pos or new pos)
  local challenge_num = 1
  local total_challenges = 1
  if sess then
    if sess.phase == "warmup" then
      local warmup_total = base.warmup_total or 0
      challenge_num = (sess.warmup_done or 0) + 1
      total_challenges = warmup_total
    elseif sess.phase == "new_challenges" then
      local new_total = base.new_total or 0
      challenge_num = (sess.new_attempted or 0) + 1
      total_challenges = new_total
    end
  end

  return {
    level             = challenge and challenge.level or 1,
    challenge_num     = challenge_num,
    total_challenges  = total_challenges,
    description       = challenge and challenge.description or "",
    hint              = hint_text,
    keystroke_count   = keystroke_count,
    warmup_done       = sess and sess.warmup_done or 0,
    warmup_total      = base.warmup_total or 0,
    new_done          = sess and sess.new_passed or 0,
    new_total         = base.new_total or 0,
    position          = base.position or "top-right",
  }
end

-- ---------------------------------------------------------------------------
-- end_session
-- ---------------------------------------------------------------------------

local function end_session()
  -- Capture stats before clearing
  local new_passed   = state.session and state.session.new_passed or 0
  local warmup_done  = state.session and state.session.warmup_done or 0

  -- Stop tracker
  if state.tracker_handle then
    tracker.stop(state.tracker_handle)
    state.tracker_handle = nil
  end

  -- Clear autocmds and keymaps
  vim.api.nvim_clear_autocmds({ group = "NvimPractice" })
  pcall(vim.keymap.del, "n", "<leader>H")

  -- Close HUD
  hud.close()

  -- Nil out state
  state.session           = nil
  state.current_challenge = nil
  state.soft_stop_timer   = nil

  -- Repurpose the practice buffer as a session-complete screen
  local buf = state.practice_buf
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_set_current_buf(buf)
    vim.bo[buf].modifiable = true

    local lines = {
      "",
      "  Session Complete!",
      "  " .. string.rep("─", 36),
      "",
      string.format("  Warmup reviewed:    %d", warmup_done),
      string.format("  New challenges:     %d passed", new_passed),
      "",
      "  Press q or <CR> to close",
      "",
    }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].buftype    = "nofile"

    local opts = { noremap = true, silent = true, buffer = buf }
    vim.keymap.set("n", "q",    "<cmd>bdelete<CR>", opts)
    vim.keymap.set("n", "<CR>", "<cmd>bdelete<CR>", opts)
  end
  state.practice_buf = nil
end

-- ---------------------------------------------------------------------------
-- handle_result
-- ---------------------------------------------------------------------------

local function handle_result(result)
  local challenge = state.current_challenge
  local handle    = state.tracker_handle

  -- Determine SM-2 outcome
  local hint1_used = handle and handle.hint1_shown or false
  local hint2_used = handle and handle.hint2_shown or false

  local outcome
  if result == "pass" then
    if hint2_used then
      outcome = "fail"
    elseif hint1_used then
      outcome = "sloppy"
    else
      outcome = "clean"
    end
  else
    outcome = "fail"
  end

  -- Update progress record
  if challenge then
    local records = progress.load()
    local rec = records[challenge.id] or progress.default_record()
    local updated = sm2.update(rec, outcome, today())
    progress.update_record(challenge.id, updated)
  end

  -- Advance session state
  local new_state, side_effect = session.on_result(state.session, result)
  state.session = new_state

  -- Decide whether to end based on phase (not just side_effect)
  -- (skip always returns "end" but session may have more challenges)
  if side_effect == "save_and_end" or new_state.phase == "complete" then
    end_session()
    return
  end

  -- Load next challenge
  local next_ch = session.current_challenge(state.session)
  -- Defined forward reference resolved at bottom of file
  M._load_challenge(next_ch)
end

-- ---------------------------------------------------------------------------
-- on_text_changed
-- ---------------------------------------------------------------------------

local function on_text_changed()
  if not state.current_challenge or not state.session then return end

  local lines = vim.api.nvim_buf_get_lines(state.practice_buf or 0, 0, -1, false)
  local current_text = table.concat(lines, "\n")

  -- If the buffer has returned to setup state (user undid their changes), reset
  -- the keystroke count so they can retry from a clean slate.
  local setup_trimmed   = (state.current_challenge.setup_text or ""):match("^%s*(.-)%s*$")
  local current_trimmed = current_text:match("^%s*(.-)%s*$")
  if current_trimmed == setup_trimmed then
    tracker.reset_count(state.tracker_handle)
    return
  end

  local handle        = state.tracker_handle
  local keystroke_count = handle and tracker.get_count(handle) or 0

  local result = validation.grade(
    state.current_challenge,
    current_text,
    keystroke_count
  )

  if result == "pass" then
    handle_result("pass")
  end
  -- "fail" -> keep trying
end

-- ---------------------------------------------------------------------------
-- load_challenge (forward-declared as M._load_challenge for handle_result)
-- ---------------------------------------------------------------------------

local function load_challenge(challenge)
  if challenge == nil then
    end_session()
    return
  end

  state.current_challenge = challenge

  -- Create/reuse a dedicated scratch buffer for the challenge
  if not state.practice_buf or not vim.api.nvim_buf_is_valid(state.practice_buf) then
    state.practice_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(state.practice_buf)
  else
    vim.api.nvim_set_current_buf(state.practice_buf)
  end
  vim.bo[state.practice_buf].modifiable = true
  vim.bo[state.practice_buf].buftype = ""

  -- Set buffer content and reset cursor
  local lines = vim.split(challenge.setup_text or "", "\n", { plain = true })
  vim.api.nvim_buf_set_lines(state.practice_buf, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, {1, 0})

  -- Stop previous tracker
  if state.tracker_handle then
    tracker.stop(state.tracker_handle)
    state.tracker_handle = nil
  end

  -- Hint state for HUD
  local hint_text = nil

  local function on_hint1()
    hint_text = challenge.hint1
    hud.update(build_hud_opts(challenge, hint_text))
  end

  local function on_hint2()
    hint_text = challenge.hint2
    hud.update(build_hud_opts(challenge, hint_text))
  end

  local function on_keystroke(_count)
    hud.update(build_hud_opts(challenge, hint_text))
    -- Re-validate on each keystroke: TextChanged fires before vim.on_key so
    -- the count may not yet reflect the keystroke that completed the challenge.
    if state.current_challenge == challenge and state.session then
      local lines = vim.api.nvim_buf_get_lines(state.practice_buf or 0, 0, -1, false)
      local current_text = table.concat(lines, "\n")
      local h = state.tracker_handle
      local kcount = h and tracker.get_count(h) or 0
      if validation.grade(challenge, current_text, kcount) == "pass" then
        handle_result("pass")
      end
    end
  end

  state.tracker_handle = tracker.start(challenge, on_hint1, on_hint2, on_keystroke)

  -- Manual hint keybind: <leader>?
  vim.keymap.set("n", "<leader>H", function()
    if state.tracker_handle then
      tracker.request_hint(state.tracker_handle)
    end
  end, { noremap = true, silent = true, desc = "Request hint for current challenge" })

  -- Autocmd: TextChanged / TextChangedI
  vim.api.nvim_create_augroup("NvimPractice", { clear = true })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group    = "NvimPractice",
    buffer   = state.practice_buf,
    callback = on_text_changed,
  })

  -- Update HUD
  hud.update(build_hud_opts(challenge, nil))
end

-- Expose for handle_result (same file, closure is fine; alias for clarity)
M._load_challenge = load_challenge

-- ---------------------------------------------------------------------------
-- M.start_session
-- ---------------------------------------------------------------------------

function M.start_session()
  -- Load challenge content
  local all = load_all_challenges()
  state.all_challenges = all

  -- Load progress records
  local records = progress.load()

  -- Determine current level
  local lvl = current_level(all, records)

  -- Select warmup: attempted challenges only, top 3 by SM-2 score
  local attempted_records = {}
  for id, rec in pairs(records) do
    if (rec.attempt_count or 0) > 0 then
      attempted_records[id] = rec
    end
  end
  local warmup_entries = sm2.select_warmup(attempted_records, 3, today())

  -- Resolve warmup challenge tables from ids
  local challenge_by_id = {}
  for _, ch in ipairs(all) do
    challenge_by_id[ch.id] = ch
  end

  local warmup_challenges = {}
  for _, entry in ipairs(warmup_entries) do
    local ch = challenge_by_id[entry.id]
    if ch then
      warmup_challenges[#warmup_challenges + 1] = ch
    end
  end

  -- New challenges: current level, pass_count == 0, up to 10, shuffled
  local new_pool = {}
  for _, ch in ipairs(challenges_at_level(all, lvl)) do
    local rec = records[ch.id]
    if not rec or (rec.pass_count or 0) == 0 then
      new_pool[#new_pool + 1] = ch
    end
  end
  shuffle(new_pool)
  local new_challenges = {}
  for i = 1, math.min(10, #new_pool) do
    new_challenges[#new_challenges + 1] = new_pool[i]
  end

  -- Create session
  state.session = session.new(warmup_challenges, new_challenges)

  -- Store base HUD opts
  local nvim_practice = require("nvim-practice")
  local position = (nvim_practice.opts and nvim_practice.opts.hud_position) or "top-right"
  state.hud_opts_base = {
    warmup_total = #warmup_challenges,
    new_total    = #new_challenges,
    position     = position,
  }

  -- Open HUD
  local first_ch = session.current_challenge(state.session)
  hud.open(build_hud_opts(first_ch, nil))

  -- 30-minute soft stop
  state.soft_stop_timer = vim.defer_fn(function()
    if state.session and state.session.phase ~= "complete" then
      state.session = session.trigger_soft_stop(state.session)
    end
  end, 30 * 60 * 1000)

  -- Load first challenge
  load_challenge(first_ch)
end

-- ---------------------------------------------------------------------------
-- M.skip
-- ---------------------------------------------------------------------------

function M.skip()
  local challenge = state.current_challenge
  if not challenge then return end

  -- SM-2: count as fail
  local records = progress.load()
  local rec = records[challenge.id] or progress.default_record()
  local updated = sm2.update(rec, "fail", today())
  progress.update_record(challenge.id, updated)

  -- Advance session (skip, no save)
  local new_state, _side_effect = session.on_result(state.session, "skip")
  state.session = new_state

  -- End or load next based on phase
  if new_state.phase == "complete" then
    end_session()
    return
  end

  local next_ch = session.current_challenge(state.session)
  load_challenge(next_ch)
end

return M
