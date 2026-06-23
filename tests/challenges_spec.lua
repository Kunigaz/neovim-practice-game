package.path = package.path .. ";/home/kunigaz/projects/neovim-practice-game/lua/?.lua"
package.path = package.path .. ";/home/kunigaz/projects/neovim-practice-game/lua/?/init.lua"

-- Helper: assert challenge has required intermediate fields (no required_keys, no max_keystrokes)
local function assert_intermediate(c, label)
  assert.is_not_nil(c.id,                  label .. ": id missing")
  assert.is_not_nil(c.level,               label .. ": level missing")
  assert.is_not_nil(c.description,         label .. ": description missing")
  assert.is_not_nil(c.hint1,               label .. ": hint1 missing")
  assert.is_not_nil(c.hint2,               label .. ": hint2 missing")
  assert.is_not_nil(c.setup_text,          label .. ": setup_text missing")
  assert.is_not_nil(c.goal_text,           label .. ": goal_text missing")
  assert.is_not_nil(c.optimal_keystrokes,  label .. ": optimal_keystrokes missing")
  assert.is_nil(c.required_keys,           label .. ": required_keys must be absent")
  assert.is_nil(c.max_keystrokes,          label .. ": max_keystrokes must be absent")
end

-- Helper: assert challenge has required advanced fields (no required_keys, HAS max_keystrokes)
local function assert_advanced(c, label)
  assert.is_not_nil(c.id,                  label .. ": id missing")
  assert.is_not_nil(c.level,               label .. ": level missing")
  assert.is_not_nil(c.description,         label .. ": description missing")
  assert.is_not_nil(c.hint1,               label .. ": hint1 missing")
  assert.is_not_nil(c.hint2,               label .. ": hint2 missing")
  assert.is_not_nil(c.setup_text,          label .. ": setup_text missing")
  assert.is_not_nil(c.goal_text,           label .. ": goal_text missing")
  assert.is_not_nil(c.max_keystrokes,      label .. ": max_keystrokes missing")
  assert.is_not_nil(c.optimal_keystrokes,  label .. ": optimal_keystrokes missing")
  assert.is_nil(c.required_keys,           label .. ": required_keys must be absent")
  assert.is_true(c.max_keystrokes >= c.optimal_keystrokes, label .. ": max_keystrokes must be >= optimal_keystrokes")
end

-- ─── Level 7 ────────────────────────────────────────────────────────────────

describe("level7 challenges", function()
  local challenges = dofile("/home/kunigaz/projects/neovim-practice-game/lua/nvim-practice/challenges/level7.lua")

  it("has at least 5 challenges", function()
    assert.is_true(#challenges >= 5, "expected >= 5, got " .. #challenges)
  end)

  it("all challenges are intermediate tier", function()
    for i, c in ipairs(challenges) do
      assert_intermediate(c, "L7[" .. i .. "]")
    end
  end)

  it("all challenges have level == 7", function()
    for i, c in ipairs(challenges) do
      assert.are.equal(7, c.level, "L7[" .. i .. "] wrong level")
    end
  end)

  it("ids are unique", function()
    local seen = {}
    for i, c in ipairs(challenges) do
      assert.is_nil(seen[c.id], "duplicate id '" .. c.id .. "' at L7[" .. i .. "]")
      seen[c.id] = true
    end
  end)
end)

-- ─── Level 8 ────────────────────────────────────────────────────────────────

describe("level8 challenges", function()
  local challenges = dofile("/home/kunigaz/projects/neovim-practice-game/lua/nvim-practice/challenges/level8.lua")

  it("has at least 5 challenges", function()
    assert.is_true(#challenges >= 5, "expected >= 5, got " .. #challenges)
  end)

  it("all challenges are intermediate tier", function()
    for i, c in ipairs(challenges) do
      assert_intermediate(c, "L8[" .. i .. "]")
    end
  end)

  it("all challenges have level == 8", function()
    for i, c in ipairs(challenges) do
      assert.are.equal(8, c.level, "L8[" .. i .. "] wrong level")
    end
  end)

  it("ids are unique", function()
    local seen = {}
    for i, c in ipairs(challenges) do
      assert.is_nil(seen[c.id], "duplicate id '" .. c.id .. "' at L8[" .. i .. "]")
      seen[c.id] = true
    end
  end)
end)

-- ─── Level 9 ────────────────────────────────────────────────────────────────

describe("level9 challenges", function()
  local challenges = dofile("/home/kunigaz/projects/neovim-practice-game/lua/nvim-practice/challenges/level9.lua")

  it("has at least 5 challenges", function()
    assert.is_true(#challenges >= 5, "expected >= 5, got " .. #challenges)
  end)

  it("all challenges are advanced tier (have max_keystrokes)", function()
    for i, c in ipairs(challenges) do
      assert_advanced(c, "L9[" .. i .. "]")
    end
  end)

  it("all challenges have level == 9", function()
    for i, c in ipairs(challenges) do
      assert.are.equal(9, c.level, "L9[" .. i .. "] wrong level")
    end
  end)

  it("ids are unique", function()
    local seen = {}
    for i, c in ipairs(challenges) do
      assert.is_nil(seen[c.id], "duplicate id '" .. c.id .. "' at L9[" .. i .. "]")
      seen[c.id] = true
    end
  end)
end)

-- ─── Level 10 ───────────────────────────────────────────────────────────────

describe("level10 challenges", function()
  local challenges = dofile("/home/kunigaz/projects/neovim-practice-game/lua/nvim-practice/challenges/level10.lua")

  it("has at least 4 challenges", function()
    assert.is_true(#challenges >= 4, "expected >= 4, got " .. #challenges)
  end)

  it("all challenges are advanced tier (have max_keystrokes)", function()
    for i, c in ipairs(challenges) do
      assert_advanced(c, "L10[" .. i .. "]")
    end
  end)

  it("all challenges have level == 10", function()
    for i, c in ipairs(challenges) do
      assert.are.equal(10, c.level, "L10[" .. i .. "] wrong level")
    end
  end)

  it("ids are unique", function()
    local seen = {}
    for i, c in ipairs(challenges) do
      assert.is_nil(seen[c.id], "duplicate id '" .. c.id .. "' at L10[" .. i .. "]")
      seen[c.id] = true
    end
  end)
end)
