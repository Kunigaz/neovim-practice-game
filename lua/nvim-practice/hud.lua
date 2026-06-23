-- hud.lua
-- Floating HUD module for nvim-practice.

local M = {}

local state = {
  buf     = nil,
  win     = nil,
  visible = true,
  last_opts = nil,
}

-- Expose state for tests
function M._state()
  return state
end

-- ---------------------------------------------------------------------------
-- Content builder (pure, no vim.api side-effects)
-- ---------------------------------------------------------------------------

function M._build_lines(opts)
  local lines = {}

  -- Header: level + challenge fraction
  lines[#lines + 1] = string.format(
    " Level %d · Challenge %d/%d",
    opts.level,
    opts.challenge_num,
    opts.total_challenges
  )

  -- Separator
  lines[#lines + 1] = " " .. string.rep("─", 38)

  -- Description
  lines[#lines + 1] = " " .. (opts.description or "")

  -- Blank line after description
  lines[#lines + 1] = ""

  -- Optional hint block (inserted before status line)
  if opts.hint then
    lines[#lines + 1] = " Hint: " .. opts.hint
    lines[#lines + 1] = ""
  end

  -- Status line: keystrokes + warmup + new progress
  local warmup_check = (opts.warmup_done >= opts.warmup_total) and " ✓" or ""
  lines[#lines + 1] = string.format(
    " Keys: %d  Warmup %d/%d%s  New %d/%d",
    opts.keystroke_count,
    opts.warmup_done,
    opts.warmup_total,
    warmup_check,
    opts.new_done,
    opts.new_total
  )

  return lines
end

-- ---------------------------------------------------------------------------
-- Position calculator (pure)
-- Width and height are passed so _calc_position is testable with any values.
-- ---------------------------------------------------------------------------

function M._calc_position(position, width, height)
  local col_right = vim.o.columns - width - 2
  local row_bottom = vim.o.lines - height - 3

  if position == "top-right" then
    return { row = 1, col = col_right, anchor = "NW" }
  elseif position == "top-left" then
    return { row = 1, col = 2, anchor = "NW" }
  elseif position == "bottom-right" then
    return { row = row_bottom, col = col_right, anchor = "NW" }
  elseif position == "bottom-left" then
    return { row = row_bottom, col = 2, anchor = "NW" }
  else
    -- Unknown position: default to top-right
    return { row = 1, col = col_right, anchor = "NW" }
  end
end

-- ---------------------------------------------------------------------------
-- Internal: render lines into an existing buffer
-- ---------------------------------------------------------------------------

local function render(buf, opts)
  local lines = M._build_lines(opts)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  return lines
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

function M.open(opts)
  opts = opts or {}
  state.last_opts = opts

  -- Close existing window cleanly if already open
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
  end

  -- Create scratch buffer (or reuse valid one)
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
  end

  local width = 40
  local lines = render(state.buf, opts)
  local height = #lines

  local position = opts.position or "top-right"
  local pos = M._calc_position(position, width, height)

  local win_config = {
    relative  = "editor",
    anchor    = pos.anchor,
    row       = pos.row,
    col       = pos.col,
    width     = width,
    height    = height,
    style     = "minimal",
    border    = "rounded",
    focusable = false,
    zindex    = 50,
  }

  state.win = vim.api.nvim_open_win(state.buf, false, win_config)
  state.visible = true

  -- Toggle keybind: <leader>h -> toggle HUD
  vim.keymap.set("n", "<leader>h", function()
    M.toggle(state.last_opts)
  end, { noremap = true, silent = true, desc = "Toggle nvim-practice HUD" })
end

function M.update(opts)
  opts = opts or {}
  state.last_opts = opts

  -- No-op if no valid buffer/window yet
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end

  render(state.buf, opts)

  -- Resize window to match new line count if window is valid
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    local lines = M._build_lines(opts)
    local height = #lines
    local width = 40
    local position = opts.position or "top-right"
    local pos = M._calc_position(position, width, height)

    vim.api.nvim_win_set_config(state.win, {
      relative  = "editor",
      anchor    = pos.anchor,
      row       = pos.row,
      col       = pos.col,
      width     = width,
      height    = height,
    })
  end
end

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
  state.visible = false
end

function M.toggle(opts)
  if M.is_open() then
    M.close()
  else
    M.open(opts or state.last_opts or {})
  end
end

function M.is_open()
  return state.win ~= nil
    and vim.api.nvim_win_is_valid(state.win)
    and state.visible
end

return M
