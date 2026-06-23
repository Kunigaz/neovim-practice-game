package.path = package.path .. ";/home/kunigaz/projects/neovim-practice-game/lua/?.lua"
package.path = package.path .. ";/home/kunigaz/projects/neovim-practice-game/lua/?/init.lua"

local sm2 = require("nvim-practice.sm2")

describe("sm2.warmup_score", function()
  it("nil last_played -> very high score", function()
    local record = {
      last_played_date = nil,
      interval_days = 1,
      avg_keystrokes = 5,
      optimal_keystrokes = 5,
      streak = 0,
    }
    local score = sm2.warmup_score(record, "2026-06-16")
    -- days_since = 999, so score >= 999
    assert.is_true(score >= 999)
  end)

  it("recent play -> low days_since term", function()
    local record = {
      last_played_date = "2026-06-16",
      interval_days = 7,
      avg_keystrokes = 5,
      optimal_keystrokes = 5,
      streak = 0,
    }
    local score = sm2.warmup_score(record, "2026-06-16")
    -- days_since = 0, so days term = 0
    -- avg/opt = 1, streak term = 1/(0+1) = 1
    -- total = 0 + 1 + 1 = 2
    assert.are.equal(2, score)
  end)

  it("high streak -> lower streak term", function()
    local low_streak = {
      last_played_date = "2026-06-15",
      interval_days = 1,
      avg_keystrokes = 5,
      optimal_keystrokes = 5,
      streak = 0,
    }
    local high_streak = {
      last_played_date = "2026-06-15",
      interval_days = 1,
      avg_keystrokes = 5,
      optimal_keystrokes = 5,
      streak = 9,
    }
    local score_low = sm2.warmup_score(low_streak, "2026-06-16")
    local score_high = sm2.warmup_score(high_streak, "2026-06-16")
    assert.is_true(score_high < score_low)
  end)

  it("zero optimal_keystrokes -> skip keystroke term", function()
    local record = {
      last_played_date = "2026-06-16",
      interval_days = 1,
      avg_keystrokes = 10,
      optimal_keystrokes = 0,
      streak = 0,
    }
    local score = sm2.warmup_score(record, "2026-06-16")
    -- days_since=0 -> 0, keystroke term skipped -> 0, streak = 1/(0+1) = 1
    assert.are.equal(1, score)
  end)
end)

describe("sm2.select_warmup", function()
  local function make_record(last_played, interval, streak)
    return {
      last_played_date = last_played,
      interval_days = interval or 1,
      avg_keystrokes = 5,
      optimal_keystrokes = 5,
      streak = streak or 0,
    }
  end

  it("returns top-n sorted descending by score", function()
    local records = {
      a = make_record("2026-06-16", 1, 0), -- recent, low score
      b = make_record("2026-06-10", 1, 0), -- 6 days ago, higher score
      c = make_record(nil, 1, 0),          -- nil -> score ~1001
    }
    local result = sm2.select_warmup(records, 2, "2026-06-16")
    assert.are.equal(2, #result)
    -- first must be c (nil last_played = huge score)
    assert.are.equal("c", result[1].id)
    -- second must be b (older)
    assert.are.equal("b", result[2].id)
  end)

  it("n > len(records) returns all records", function()
    local records = {
      x = make_record("2026-06-15", 1, 0),
      y = make_record("2026-06-14", 1, 0),
    }
    local result = sm2.select_warmup(records, 10, "2026-06-16")
    assert.are.equal(2, #result)
  end)

  it("each result has id, record, score fields", function()
    local records = {
      z = make_record("2026-06-15", 1, 0),
    }
    local result = sm2.select_warmup(records, 1, "2026-06-16")
    assert.is_not_nil(result[1].id)
    assert.is_not_nil(result[1].record)
    assert.is_not_nil(result[1].score)
  end)
end)

describe("sm2.update clean", function()
  local base = {
    last_played_date = "2026-06-15",
    interval_days = 4,
    ease_factor = 2.0,
    streak = 2,
    attempt_count = 5,
    pass_count = 3,
    avg_keystrokes = 5,
    optimal_keystrokes = 5,
  }

  it("interval grows by ease_factor", function()
    local updated = sm2.update(base, "clean", "2026-06-16")
    assert.are.equal(8, updated.interval_days) -- 4 * 2.0
  end)

  it("ease_factor increases by 0.1", function()
    local updated = sm2.update(base, "clean", "2026-06-16")
    assert.are.equal(2.1, updated.ease_factor)
  end)

  it("streak increments", function()
    local updated = sm2.update(base, "clean", "2026-06-16")
    assert.are.equal(3, updated.streak)
  end)

  it("attempt_count increments", function()
    local updated = sm2.update(base, "clean", "2026-06-16")
    assert.are.equal(6, updated.attempt_count)
  end)

  it("pass_count increments", function()
    local updated = sm2.update(base, "clean", "2026-06-16")
    assert.are.equal(4, updated.pass_count)
  end)

  it("last_played_date updated", function()
    local updated = sm2.update(base, "clean", "2026-06-16")
    assert.are.equal("2026-06-16", updated.last_played_date)
  end)

  it("does not mutate input", function()
    sm2.update(base, "clean", "2026-06-16")
    assert.are.equal(4, base.interval_days)
    assert.are.equal(2.0, base.ease_factor)
    assert.are.equal(2, base.streak)
  end)
end)

describe("sm2.update sloppy", function()
  local base = {
    last_played_date = "2026-06-15",
    interval_days = 4,
    ease_factor = 2.0,
    streak = 2,
    attempt_count = 5,
    pass_count = 3,
    avg_keystrokes = 5,
    optimal_keystrokes = 5,
  }

  it("interval unchanged", function()
    local updated = sm2.update(base, "sloppy", "2026-06-16")
    assert.are.equal(4, updated.interval_days)
  end)

  it("ease_factor unchanged", function()
    local updated = sm2.update(base, "sloppy", "2026-06-16")
    assert.are.equal(2.0, updated.ease_factor)
  end)

  it("streak resets to 0", function()
    local updated = sm2.update(base, "sloppy", "2026-06-16")
    assert.are.equal(0, updated.streak)
  end)

  it("attempt_count increments", function()
    local updated = sm2.update(base, "sloppy", "2026-06-16")
    assert.are.equal(6, updated.attempt_count)
  end)

  it("pass_count increments", function()
    local updated = sm2.update(base, "sloppy", "2026-06-16")
    assert.are.equal(4, updated.pass_count)
  end)
end)

describe("sm2.update fail", function()
  local base = {
    last_played_date = "2026-06-15",
    interval_days = 8,
    ease_factor = 2.5,
    streak = 5,
    attempt_count = 10,
    pass_count = 8,
    avg_keystrokes = 5,
    optimal_keystrokes = 5,
  }

  it("interval resets to 1", function()
    local updated = sm2.update(base, "fail", "2026-06-16")
    assert.are.equal(1, updated.interval_days)
  end)

  it("ease_factor decreases by 0.2", function()
    local updated = sm2.update(base, "fail", "2026-06-16")
    assert.are.equal(2.3, updated.ease_factor)
  end)

  it("ease_factor floor is 1.3", function()
    local low = {
      last_played_date = "2026-06-15",
      interval_days = 2,
      ease_factor = 1.4,
      streak = 0,
      attempt_count = 3,
      pass_count = 1,
      avg_keystrokes = 5,
      optimal_keystrokes = 5,
    }
    local updated = sm2.update(low, "fail", "2026-06-16")
    assert.are.equal(1.3, updated.ease_factor)
  end)

  it("streak resets to 0", function()
    local updated = sm2.update(base, "fail", "2026-06-16")
    assert.are.equal(0, updated.streak)
  end)

  it("attempt_count increments", function()
    local updated = sm2.update(base, "fail", "2026-06-16")
    assert.are.equal(11, updated.attempt_count)
  end)

  it("pass_count NOT incremented", function()
    local updated = sm2.update(base, "fail", "2026-06-16")
    assert.are.equal(8, updated.pass_count)
  end)
end)
