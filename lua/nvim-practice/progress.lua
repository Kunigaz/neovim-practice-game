local M = {}

local DATA_PATH = vim.fn.stdpath("data") .. "/nvim-practice/progress.json"

function M.default_record()
  return {
    attempt_count = 0,
    pass_count = 0,
    streak = 0,
    avg_keystrokes = 0,
    optimal_keystrokes = 0,
    last_played_date = nil,
    interval_days = 1,
    ease_factor = 2.5,
  }
end

function M.load()
  local dir = vim.fn.stdpath("data") .. "/nvim-practice"
  vim.fn.mkdir(dir, "p")

  local f = io.open(DATA_PATH, "r")
  if not f then
    return {}
  end

  local content = f:read("*a")
  f:close()

  if content == nil or content == "" then
    return {}
  end

  local ok, data = pcall(vim.fn.json_decode, content)
  if not ok or type(data) ~= "table" then
    return {}
  end

  return data
end

function M.save(data)
  local dir = vim.fn.stdpath("data") .. "/nvim-practice"
  vim.fn.mkdir(dir, "p")

  local encoded = vim.fn.json_encode(data)
  local f = io.open(DATA_PATH, "w")
  if not f then
    error("nvim-practice: cannot write to " .. DATA_PATH)
  end
  f:write(encoded)
  f:close()
end

function M.get_record(challenge_id)
  local data = M.load()
  return data[challenge_id] or M.default_record()
end

function M.update_record(challenge_id, record)
  local data = M.load()
  data[challenge_id] = record
  M.save(data)
end

return M
