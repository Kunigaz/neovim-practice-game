package.path = package.path .. ";/home/kunigaz/projects/neovim-practice-game/lua/?.lua"
package.path = package.path .. ";/home/kunigaz/projects/neovim-practice-game/lua/?/init.lua"

local validation = require("nvim-practice.validation")

describe("validation.check_buffer", function()
  it("exact match passes", function()
    assert.is_true(validation.check_buffer("hello world", "hello world"))
  end)

  it("mismatch fails", function()
    assert.is_false(validation.check_buffer("hello world", "hello vim"))
  end)

  it("leading whitespace trimmed", function()
    assert.is_true(validation.check_buffer("  hello", "hello"))
  end)

  it("trailing whitespace trimmed", function()
    assert.is_true(validation.check_buffer("hello  ", "hello"))
  end)

  it("both sides trimmed", function()
    assert.is_true(validation.check_buffer("  hello  ", "  hello  "))
  end)
end)


describe("validation.check_keystroke_limit", function()
  it("at limit passes", function()
    assert.is_true(validation.check_keystroke_limit(5, 5))
  end)

  it("under limit passes", function()
    assert.is_true(validation.check_keystroke_limit(3, 5))
  end)

  it("over limit fails", function()
    assert.is_false(validation.check_keystroke_limit(6, 5))
  end)

  it("nil limit always passes", function()
    assert.is_true(validation.check_keystroke_limit(999, nil))
  end)
end)

describe("validation.get_tier", function()
  it("level 1 -> beginner", function()
    assert.are.equal("beginner", validation.get_tier(1))
  end)

  it("level 5 -> beginner", function()
    assert.are.equal("beginner", validation.get_tier(5))
  end)

  it("level 6 -> intermediate", function()
    assert.are.equal("intermediate", validation.get_tier(6))
  end)

  it("level 8 -> intermediate", function()
    assert.are.equal("intermediate", validation.get_tier(8))
  end)

  it("level 9 -> advanced", function()
    assert.are.equal("advanced", validation.get_tier(9))
  end)

  it("level 10 -> advanced", function()
    assert.are.equal("advanced", validation.get_tier(10))
  end)
end)

describe("validation.grade beginner", function()
  local challenge = {
    level = 1,
    goal_text = "world",
  }

  it("correct buffer -> pass", function()
    local result = validation.grade(challenge, "world", 2)
    assert.are.equal("pass", result)
  end)

  it("wrong buffer -> fail", function()
    local result = validation.grade(challenge, "hello world", 2)
    assert.are.equal("fail", result)
  end)
end)

describe("validation.grade intermediate", function()
  local challenge = {
    level = 6,
    goal_text = "world",
  }

  it("correct buffer -> pass", function()
    local result = validation.grade(challenge, "world", 10)
    assert.are.equal("pass", result)
  end)

  it("wrong buffer -> fail", function()
    local result = validation.grade(challenge, "hello world", 10)
    assert.are.equal("fail", result)
  end)
end)

describe("validation.grade advanced", function()
  local challenge = {
    level = 9,
    max_keystrokes = 5,
    goal_text = "world",
  }

  it("correct buffer + under limit -> pass", function()
    local result = validation.grade(challenge, "world", 3)
    assert.are.equal("pass", result)
  end)

  it("correct buffer + at limit -> pass", function()
    local result = validation.grade(challenge, "world", 5)
    assert.are.equal("pass", result)
  end)

  it("correct buffer + over limit -> fail", function()
    local result = validation.grade(challenge, "world", 6)
    assert.are.equal("fail", result)
  end)

  it("wrong buffer + under limit -> fail", function()
    local result = validation.grade(challenge, "hello world", 3)
    assert.are.equal("fail", result)
  end)
end)
