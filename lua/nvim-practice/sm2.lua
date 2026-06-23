-- SM-2 spaced repetition module
-- Pure Lua: zero Neovim API dependencies. Runnable with plain lua/busted.

local M = {}

-- Parse "YYYY-MM-DD" -> days since epoch (integer)
local function date_to_days(date_str)
  local y, m, d = date_str:match("^(%d+)-(%d+)-(%d+)$")
  assert(y, "invalid date: " .. tostring(date_str))
  return os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0, min = 0, sec = 0 })
      / 86400
end

-- Days between two "YYYY-MM-DD" strings (today - past, floored)
local function days_between(past_str, today_str)
  return math.floor(date_to_days(today_str) - date_to_days(past_str))
end

--- Compute warmup priority score for a single record.
-- Higher score = higher priority for warmup selection.
-- @param record table with fields:
--   last_played_date (string|nil), interval_days (number),
--   avg_keystrokes (number), optimal_keystrokes (number), streak (number)
-- @param today_date_str string "YYYY-MM-DD"
-- @return number
function M.warmup_score(record, today_date_str)
  local days_since
  if record.last_played_date == nil then
    days_since = 999
  else
    days_since = days_between(record.last_played_date, today_date_str)
  end

  local days_term = days_since / record.interval_days

  local keystroke_term = 0
  if record.optimal_keystrokes and record.optimal_keystrokes > 0 then
    keystroke_term = record.avg_keystrokes / record.optimal_keystrokes
  end

  local streak_term = 1 / (record.streak + 1)

  return days_term + keystroke_term + streak_term
end

--- Select top-n challenges by warmup score.
-- @param records table keyed by challenge_id; each value is a record table
-- @param n integer
-- @param today_date_str string "YYYY-MM-DD"
-- @return list of {id=string, record=table, score=number} sorted desc by score
function M.select_warmup(records, n, today_date_str)
  local scored = {}
  for id, record in pairs(records) do
    local score = M.warmup_score(record, today_date_str)
    scored[#scored + 1] = { id = id, record = record, score = score }
  end

  table.sort(scored, function(a, b) return a.score > b.score end)

  local result = {}
  for i = 1, math.min(n, #scored) do
    result[#result + 1] = scored[i]
  end
  return result
end

--- Update a record after an attempt. Does NOT mutate input.
-- @param record table (existing challenge record)
-- @param outcome string: "clean" | "sloppy" | "fail"
-- @param today_date_str string "YYYY-MM-DD"
-- @return updated_record table (new copy)
function M.update(record, outcome, today_date_str)
  -- shallow copy
  local r = {}
  for k, v in pairs(record) do r[k] = v end

  r.attempt_count = (r.attempt_count or 0) + 1
  r.last_played_date = today_date_str

  if outcome == "clean" then
    r.interval_days = r.interval_days * r.ease_factor
    r.ease_factor = r.ease_factor + 0.1
    r.streak = (r.streak or 0) + 1
    r.pass_count = (r.pass_count or 0) + 1

  elseif outcome == "sloppy" then
    -- interval and ease unchanged
    r.streak = 0
    r.pass_count = (r.pass_count or 0) + 1

  elseif outcome == "fail" then
    r.interval_days = 1
    r.ease_factor = math.max(1.3, r.ease_factor - 0.2)
    r.streak = 0
    -- pass_count unchanged

  else
    error("unknown outcome: " .. tostring(outcome))
  end

  return r
end

return M
