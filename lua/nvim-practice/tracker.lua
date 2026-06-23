--- tracker.lua
--- Keystroke tracking and hint timer management for nvim-practice.

local M = {}

local NS_NAME = "nvim-practice-tracker"

--- Start tracking keystrokes and hint timers for a challenge.
---@param challenge table  Challenge table (id, level, etc.)
---@param on_hint1 function  Called when hint1 threshold reached
---@param on_hint2 function  Called when hint2 threshold reached
---@param on_keystroke function  Called after each keystroke: fn(count)
---@return table handle
function M.start(challenge, on_hint1, on_hint2, on_keystroke)
  local ns_id = vim.api.nvim_create_namespace(NS_NAME)

  local handle = {
    ns_id      = ns_id,
    count      = 0,
    hint1_shown = false,
    hint2_shown = false,
    hint1_timer = nil,
    hint2_timer = nil,
    active      = true,
    _challenge  = challenge,
    _on_hint1   = on_hint1,
    _on_hint2   = on_hint2,
    _on_keystroke = on_keystroke,
  }

  -- Keystroke handler
  vim.on_key(function(key)
    if not handle.active then return end
    if key == "" then return end
    handle.count = handle.count + 1
    if on_keystroke then
      on_keystroke(handle.count)
    end
  end, ns_id)

  -- hint1 timer: fires at 60s
  handle.hint1_timer = vim.defer_fn(function()
    if not handle.active then return end
    if not handle.hint1_shown then
      handle.hint1_shown = true
      handle.hint1_timer = nil
      if on_hint1 then on_hint1() end
    end
  end, 60000)

  -- hint2 timer: fires at 180s
  handle.hint2_timer = vim.defer_fn(function()
    if not handle.active then return end
    if not handle.hint2_shown then
      handle.hint2_shown = true
      handle.hint2_timer = nil
      if on_hint2 then on_hint2() end
    end
  end, 180000)

  return handle
end

--- Cancel a timer returned by vim.defer_fn (if still pending).
---@param timer any
local function cancel_timer(timer)
  if timer == nil then return end
  -- vim.defer_fn returns a luv timer (uv_timer_t)
  local ok = pcall(function()
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
  end)
  -- if pcall fails the timer already fired/closed; ignore
  _ = ok
end

--- Stop tracking: unregister key handler, cancel pending timers.
---@param handle table
function M.stop(handle)
  if not handle then return end
  handle.active = false

  -- Unregister keystroke listener
  vim.on_key(nil, handle.ns_id)

  -- Cancel pending hint timers
  cancel_timer(handle.hint1_timer)
  cancel_timer(handle.hint2_timer)
  handle.hint1_timer = nil
  handle.hint2_timer = nil
end

--- Get current keystroke count.
---@param handle table
---@return number
function M.get_count(handle)
  return handle.count
end

--- Reset keystroke count (called when the user undoes back to setup state).
---@param handle table
function M.reset_count(handle)
  if not handle then return end
  handle.count = 0
end

--- Manually request the next hint (idempotent).
--- - hint1 not shown: show hint1, cancel 60s timer, schedule 120s more for hint2
--- - hint1 shown, hint2 not: show hint2, cancel 180s timer
--- - both shown: return nil
---@param handle table
---@return 1|2|nil  which hint was triggered
function M.request_hint(handle)
  if not handle or not handle.active then return nil end

  if not handle.hint1_shown then
    -- Cancel auto hint1 timer
    cancel_timer(handle.hint1_timer)
    handle.hint1_timer = nil

    handle.hint1_shown = true
    if handle._on_hint1 then handle._on_hint1() end

    -- Cancel existing hint2 timer; reschedule 120s from now
    cancel_timer(handle.hint2_timer)
    handle.hint2_timer = vim.defer_fn(function()
      if not handle.active then return end
      if not handle.hint2_shown then
        handle.hint2_shown = true
        handle.hint2_timer = nil
        if handle._on_hint2 then handle._on_hint2() end
      end
    end, 120000)

    return 1

  elseif not handle.hint2_shown then
    -- Cancel auto hint2 timer
    cancel_timer(handle.hint2_timer)
    handle.hint2_timer = nil

    handle.hint2_shown = true
    if handle._on_hint2 then handle._on_hint2() end

    return 2

  else
    return nil
  end
end

return M
