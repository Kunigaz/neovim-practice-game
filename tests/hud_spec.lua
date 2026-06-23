-- hud_spec.lua
-- Integration tests for the floating HUD module.
-- Requires headless Neovim + plenary.nvim test harness.

local hud = require("nvim-practice.hud")

local base_opts = {
  level = 3,
  challenge_num = 2,
  total_challenges = 8,
  description = "Delete the word 'error' using diw",
  hint = nil,
  keystroke_count = 5,
  warmup_done = 2,
  warmup_total = 3,
  new_done = 1,
  new_total = 5,
  position = "top-right",
}

-- ---------------------------------------------------------------------------
-- _build_lines: pure content builder
-- ---------------------------------------------------------------------------

describe("hud._build_lines without hint", function()
  local lines

  before_each(function()
    lines = hud._build_lines(base_opts)
  end)

  it("returns a table", function()
    assert.is_table(lines)
  end)

  it("first line contains level and challenge fraction", function()
    assert.is_truthy(lines[1]:find("Level 3"))
    assert.is_truthy(lines[1]:find("2/8"))
  end)

  it("second line is a separator", function()
    -- Contains at least 5 dashes or box-drawing chars
    assert.is_truthy(lines[2]:find("─") or lines[2]:find("%-%-%-"))
  end)

  it("description appears in lines", function()
    local found = false
    for _, l in ipairs(lines) do
      if l:find("Delete the word") then found = true end
    end
    assert.is_true(found)
  end)

  it("keystroke count appears in lines", function()
    local found = false
    for _, l in ipairs(lines) do
      if l:find("Keys:") and l:find("5") then found = true end
    end
    assert.is_true(found)
  end)

  it("warmup progress appears in lines", function()
    local found = false
    for _, l in ipairs(lines) do
      if l:find("Warmup") and l:find("2/3") then found = true end
    end
    assert.is_true(found)
  end)

  it("new progress appears in lines", function()
    local found = false
    for _, l in ipairs(lines) do
      if l:find("New") and l:find("1/5") then found = true end
    end
    assert.is_true(found)
  end)

  it("no hint line when hint is nil", function()
    local found = false
    for _, l in ipairs(lines) do
      if l:find("Hint:") then found = true end
    end
    assert.is_false(found)
  end)
end)

describe("hud._build_lines with hint", function()
  it("hint line appears when hint is set", function()
    local opts = vim.tbl_extend("force", base_opts, {
      hint = "Use diw to delete inner word",
    })
    local lines = hud._build_lines(opts)
    local found = false
    for _, l in ipairs(lines) do
      if l:find("Hint:") then found = true end
    end
    assert.is_true(found)
  end)

  it("hint text appears in lines", function()
    local opts = vim.tbl_extend("force", base_opts, {
      hint = "Use diw to delete inner word",
    })
    local lines = hud._build_lines(opts)
    local found = false
    for _, l in ipairs(lines) do
      if l:find("diw") then found = true end
    end
    assert.is_true(found)
  end)
end)

-- ---------------------------------------------------------------------------
-- _calc_position: pure position calculator
-- ---------------------------------------------------------------------------

describe("hud._calc_position", function()
  local width = 40
  local height = 6

  it("top-right: row=1, anchor=NW", function()
    local cfg = hud._calc_position("top-right", width, height)
    assert.are.equal(1, cfg.row)
    assert.are.equal("NW", cfg.anchor)
  end)

  it("top-left: row=1, col=2, anchor=NW", function()
    local cfg = hud._calc_position("top-left", width, height)
    assert.are.equal(1, cfg.row)
    assert.are.equal(2, cfg.col)
    assert.are.equal("NW", cfg.anchor)
  end)

  it("top-right: col = vim.o.columns - width - 2", function()
    local cfg = hud._calc_position("top-right", width, height)
    assert.are.equal(vim.o.columns - width - 2, cfg.col)
  end)

  it("bottom-left: col=2, anchor=NW", function()
    local cfg = hud._calc_position("bottom-left", width, height)
    assert.are.equal(2, cfg.col)
    assert.are.equal("NW", cfg.anchor)
  end)

  it("bottom-right: row = vim.o.lines - height - 3", function()
    local cfg = hud._calc_position("bottom-right", width, height)
    assert.are.equal(vim.o.lines - height - 3, cfg.row)
  end)

  it("bottom-left: row = vim.o.lines - height - 3", function()
    local cfg = hud._calc_position("bottom-left", width, height)
    assert.are.equal(vim.o.lines - height - 3, cfg.row)
  end)

  it("unknown position defaults to top-right", function()
    local cfg = hud._calc_position("invalid", width, height)
    assert.are.equal(1, cfg.row)
    assert.are.equal(vim.o.columns - width - 2, cfg.col)
  end)
end)

-- ---------------------------------------------------------------------------
-- Integration: open / close / toggle / is_open
-- ---------------------------------------------------------------------------

describe("hud open/close lifecycle", function()
  after_each(function()
    -- Clean up: ensure HUD closed between tests
    if hud.is_open() then hud.close() end
  end)

  it("is_open returns false before open", function()
    assert.is_false(hud.is_open())
  end)

  it("is_open returns true after open", function()
    hud.open(base_opts)
    assert.is_true(hud.is_open())
  end)

  it("is_open returns false after close", function()
    hud.open(base_opts)
    hud.close()
    assert.is_false(hud.is_open())
  end)

  it("open creates a valid buffer", function()
    hud.open(base_opts)
    local buf = hud._state().buf
    assert.is_true(vim.api.nvim_buf_is_valid(buf))
  end)

  it("open creates a valid window", function()
    hud.open(base_opts)
    local win = hud._state().win
    assert.is_true(vim.api.nvim_win_is_valid(win))
  end)

  it("close invalidates the window", function()
    hud.open(base_opts)
    local win = hud._state().win
    hud.close()
    assert.is_false(vim.api.nvim_win_is_valid(win))
  end)

  it("calling open twice reuses or recreates without error", function()
    hud.open(base_opts)
    hud.open(base_opts)
    assert.is_true(hud.is_open())
  end)
end)

describe("hud.update", function()
  after_each(function()
    if hud.is_open() then hud.close() end
  end)

  it("update without open does not error", function()
    assert.has_no_errors(function()
      hud.update(base_opts)
    end)
  end)

  it("update after open refreshes buffer lines", function()
    hud.open(base_opts)
    local updated_opts = vim.tbl_extend("force", base_opts, {
      keystroke_count = 99,
    })
    hud.update(updated_opts)
    local buf = hud._state().buf
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local found = false
    for _, l in ipairs(lines) do
      if l:find("99") then found = true end
    end
    assert.is_true(found)
  end)
end)

describe("hud.toggle", function()
  after_each(function()
    if hud.is_open() then hud.close() end
  end)

  it("toggle when closed opens HUD", function()
    assert.is_false(hud.is_open())
    hud.toggle(base_opts)
    assert.is_true(hud.is_open())
  end)

  it("toggle when open closes HUD", function()
    hud.open(base_opts)
    hud.toggle(base_opts)
    assert.is_false(hud.is_open())
  end)

  it("double toggle restores open state", function()
    hud.open(base_opts)
    hud.toggle(base_opts)
    hud.toggle(base_opts)
    assert.is_true(hud.is_open())
  end)
end)
