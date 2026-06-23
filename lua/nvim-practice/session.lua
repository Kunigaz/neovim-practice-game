-- session.lua: pure Lua session state machine. Zero Neovim API.
local M = {}

-- Deep copy a list of challenges
local function copy_list(t)
  local out = {}
  for i, v in ipairs(t) do
    out[i] = v
  end
  return out
end

-- Determine initial phase and set current challenge index
local function initial_phase(warmup_queue, new_queue)
  if #warmup_queue > 0 then
    return "warmup"
  elseif #new_queue > 0 then
    return "new_challenges"
  else
    return "complete"
  end
end

--- Create new session state.
-- warmup_challenges: list of challenge tables
-- new_challenges: list of challenge tables
-- Returns state table
function M.new(warmup_challenges, new_challenges)
  local warmup_queue = copy_list(warmup_challenges)
  local new_queue = copy_list(new_challenges)
  local phase = initial_phase(warmup_queue, new_queue)

  return {
    phase = phase,
    warmup_queue = warmup_queue,
    warmup_done = 0,
    new_queue = new_queue,
    new_passed = 0,
    new_attempted = 0,
    current_challenge = nil, -- derived via M.current_challenge()
    soft_stop_triggered = false,
    started_at = nil,
  }
end

--- Get current challenge (nil if complete).
function M.current_challenge(state)
  if state.phase == "warmup" then
    return state.warmup_queue[1]
  elseif state.phase == "new_challenges" then
    return state.new_queue[1]
  else
    return nil
  end
end

--- Copy state (shallow fields, deep queues)
local function copy_state(state)
  return {
    phase = state.phase,
    warmup_queue = copy_list(state.warmup_queue),
    warmup_done = state.warmup_done,
    new_queue = copy_list(state.new_queue),
    new_passed = state.new_passed,
    new_attempted = state.new_attempted,
    current_challenge = state.current_challenge,
    soft_stop_triggered = state.soft_stop_triggered,
    started_at = state.started_at,
  }
end

--- Signal soft stop (30min elapsed).
-- Sets soft_stop_triggered = true.
-- If no current challenge, transitions to complete.
function M.trigger_soft_stop(state)
  local s = copy_state(state)
  s.soft_stop_triggered = true
  -- If already complete or no active challenge, ensure complete
  if s.phase ~= "complete" and M.current_challenge(s) == nil then
    s.phase = "complete"
  end
  return s
end

--- Advance queue: remove front element.
local function advance_queue(queue)
  local new_q = copy_list(queue)
  table.remove(new_q, 1)
  return new_q
end

--- Process result of current challenge.
-- result: "pass" | "fail" | "skip"
-- Returns new_state, side_effect
function M.on_result(state, result)
  -- No-op if complete
  if state.phase == "complete" then
    return copy_state(state), "end"
  end

  -- Skip: advance, no save
  if result == "skip" then
    local s = copy_state(state)
    if s.phase == "warmup" then
      s.warmup_queue = advance_queue(s.warmup_queue)
      if #s.warmup_queue == 0 then
        if #s.new_queue > 0 then
          s.phase = "new_challenges"
        else
          s.phase = "complete"
        end
      end
    elseif s.phase == "new_challenges" then
      s.new_queue = advance_queue(s.new_queue)
      if #s.new_queue == 0 then
        s.phase = "complete"
      end
    end
    return s, "end"
  end

  -- pass or fail
  local s = copy_state(state)

  if s.phase == "warmup" then
    -- Warmup doesn't track pass/fail counts
    s.warmup_done = s.warmup_done + 1
    s.warmup_queue = advance_queue(s.warmup_queue)
    if #s.warmup_queue == 0 then
      if #s.new_queue > 0 then
        s.phase = "new_challenges"
      else
        s.phase = "complete"
      end
    end
    -- Determine side effect
    if s.soft_stop_triggered then
      s.phase = "complete"
      return s, "save_and_end"
    end
    return s, "save"

  elseif s.phase == "new_challenges" then
    s.new_attempted = s.new_attempted + 1
    if result == "pass" then
      s.new_passed = s.new_passed + 1
    end
    s.new_queue = advance_queue(s.new_queue)
    if #s.new_queue == 0 then
      s.phase = "complete"
    end

    -- Hard stop: 5 passes
    if s.new_passed >= 5 then
      s.phase = "complete"
      return s, "save_and_end"
    end

    -- Soft stop check
    if s.soft_stop_triggered then
      s.phase = "complete"
      return s, "save_and_end"
    end

    return s, "save"
  end

  -- Should not reach here
  return s, "end"
end

return M
