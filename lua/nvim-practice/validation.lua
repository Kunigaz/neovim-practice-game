local M = {}

-- Compare current buffer text to goal text (exact match, trimmed)
function M.check_buffer(current_text, goal_text)
  local current = current_text:match("^%s*(.-)%s*$")
  local goal = goal_text:match("^%s*(.-)%s*$")
  return current == goal
end

-- Check keystroke count is within limit (nil limit always passes)
function M.check_keystroke_limit(count, max_keystrokes)
  if max_keystrokes == nil then
    return true
  end
  return count <= max_keystrokes
end

-- Determine challenge tier from level number
-- levels 1-5 -> "beginner", 6-8 -> "intermediate", 9-10 -> "advanced"
function M.get_tier(level)
  if level <= 5 then
    return "beginner"
  elseif level <= 8 then
    return "intermediate"
  else
    return "advanced"
  end
end

-- Grade a challenge attempt
-- challenge: {level, max_keystrokes (opt), goal_text}
-- Returns "pass" or "fail"
function M.grade(challenge, current_text, keystroke_count)
  local tier = M.get_tier(challenge.level)

  if tier == "beginner" or tier == "intermediate" then
    if not M.check_buffer(current_text, challenge.goal_text) then
      return "fail"
    end
    return "pass"

  else -- advanced
    if not M.check_buffer(current_text, challenge.goal_text) then
      return "fail"
    end
    if not M.check_keystroke_limit(keystroke_count, challenge.max_keystrokes) then
      return "fail"
    end
    return "pass"
  end
end

return M
