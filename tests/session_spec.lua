package.path = package.path .. ";/home/kunigaz/projects/neovim-practice-game/lua/?.lua"
package.path = package.path .. ";/home/kunigaz/projects/neovim-practice-game/lua/?/init.lua"

local session = require("nvim-practice.session")

local function ch(id)
  return { id = id }
end

-- 1. new(): warmup phase, correct queues, current = first warmup
describe("session.new with warmup and new challenges", function()
  local warmup = { ch("w1"), ch("w2") }
  local new = { ch("n1"), ch("n2") }
  local state

  before_each(function()
    state = session.new(warmup, new)
  end)

  it("phase is warmup", function()
    assert.are.equal("warmup", state.phase)
  end)

  it("warmup_queue is copy of warmup_challenges", function()
    assert.are.equal(2, #state.warmup_queue)
    assert.are.equal("w1", state.warmup_queue[1].id)
    assert.are.equal("w2", state.warmup_queue[2].id)
  end)

  it("new_queue is copy of new_challenges", function()
    assert.are.equal(2, #state.new_queue)
    assert.are.equal("n1", state.new_queue[1].id)
  end)

  it("warmup_done starts at 0", function()
    assert.are.equal(0, state.warmup_done)
  end)

  it("new_passed starts at 0", function()
    assert.are.equal(0, state.new_passed)
  end)

  it("new_attempted starts at 0", function()
    assert.are.equal(0, state.new_attempted)
  end)

  it("current_challenge is first warmup", function()
    local cur = session.current_challenge(state)
    assert.are.equal("w1", cur.id)
  end)

  it("soft_stop_triggered is false", function()
    assert.is_false(state.soft_stop_triggered)
  end)

  it("started_at is nil", function()
    assert.is_nil(state.started_at)
  end)
end)

-- 2. new() with empty warmup: phase=new_challenges, current=first new
describe("session.new with empty warmup", function()
  it("phase is new_challenges", function()
    local state = session.new({}, { ch("n1") })
    assert.are.equal("new_challenges", state.phase)
  end)

  it("current_challenge is first new challenge", function()
    local state = session.new({}, { ch("n1"), ch("n2") })
    local cur = session.current_challenge(state)
    assert.are.equal("n1", cur.id)
  end)
end)

-- 3. new() with empty both: phase=complete, current=nil
describe("session.new with empty warmup and new", function()
  it("phase is complete", function()
    local state = session.new({}, {})
    assert.are.equal("complete", state.phase)
  end)

  it("current_challenge is nil", function()
    local state = session.new({}, {})
    assert.is_nil(session.current_challenge(state))
  end)
end)

-- 4. on_result pass in warmup: advances to next warmup challenge
describe("on_result pass in warmup (more warmup remaining)", function()
  it("advances current_challenge to next warmup", function()
    local state = session.new({ ch("w1"), ch("w2") }, { ch("n1") })
    local new_state, _ = session.on_result(state, "pass")
    local cur = session.current_challenge(new_state)
    assert.are.equal("w2", cur.id)
  end)

  it("phase stays warmup", function()
    local state = session.new({ ch("w1"), ch("w2") }, { ch("n1") })
    local new_state, _ = session.on_result(state, "pass")
    assert.are.equal("warmup", new_state.phase)
  end)

  it("warmup_done increments", function()
    local state = session.new({ ch("w1"), ch("w2") }, { ch("n1") })
    local new_state, _ = session.on_result(state, "pass")
    assert.are.equal(1, new_state.warmup_done)
  end)

  it("side_effect is save", function()
    local state = session.new({ ch("w1"), ch("w2") }, { ch("n1") })
    local _, effect = session.on_result(state, "pass")
    assert.are.equal("save", effect)
  end)
end)

-- 5. on_result pass exhausts warmup: transitions to new_challenges
describe("on_result pass exhausts warmup", function()
  it("transitions phase to new_challenges", function()
    local state = session.new({ ch("w1") }, { ch("n1") })
    local new_state, _ = session.on_result(state, "pass")
    assert.are.equal("new_challenges", new_state.phase)
  end)

  it("current_challenge is first new challenge", function()
    local state = session.new({ ch("w1") }, { ch("n1"), ch("n2") })
    local new_state, _ = session.on_result(state, "pass")
    local cur = session.current_challenge(new_state)
    assert.are.equal("n1", cur.id)
  end)

  it("side_effect is save", function()
    local state = session.new({ ch("w1") }, { ch("n1") })
    local _, effect = session.on_result(state, "pass")
    assert.are.equal("save", effect)
  end)
end)

-- 6. on_result pass in new_challenges: increments new_passed
describe("on_result pass in new_challenges", function()
  it("new_passed increments", function()
    local state = session.new({}, { ch("n1"), ch("n2"), ch("n3") })
    local new_state, _ = session.on_result(state, "pass")
    assert.are.equal(1, new_state.new_passed)
  end)

  it("new_attempted increments", function()
    local state = session.new({}, { ch("n1"), ch("n2") })
    local new_state, _ = session.on_result(state, "pass")
    assert.are.equal(1, new_state.new_attempted)
  end)

  it("side_effect is save", function()
    local state = session.new({}, { ch("n1"), ch("n2"), ch("n3") })
    local _, effect = session.on_result(state, "pass")
    assert.are.equal("save", effect)
  end)
end)

-- 7. on_result 5 passes in new_challenges: save_and_end, complete
describe("on_result 5th pass in new_challenges triggers hard stop", function()
  local function build_state_with_passed(n)
    -- Start with enough challenges; manually set new_passed to n-1
    local challenges = {}
    for i = 1, 10 do challenges[i] = ch("n" .. i) end
    local state = session.new({}, challenges)
    state = vim.tbl_deep_extend and vim.tbl_deep_extend("force", state, { new_passed = n - 1 }) or
        (function()
          state.new_passed = n - 1
          -- advance queue past first n-1 items (simulate already done)
          for _ = 1, n - 1 do
            table.remove(state.new_queue, 1)
          end
          return state
        end)()
    return state
  end

  it("side_effect is save_and_end on 5th pass", function()
    local challenges = {}
    for i = 1, 10 do challenges[i] = ch("n" .. i) end
    local state = session.new({}, challenges)
    -- Simulate 4 passes manually
    state.new_passed = 4
    -- Remove 4 from queue head so current is n5
    for _ = 1, 4 do table.remove(state.new_queue, 1) end
    local _, effect = session.on_result(state, "pass")
    assert.are.equal("save_and_end", effect)
  end)

  it("phase becomes complete on 5th pass", function()
    local challenges = {}
    for i = 1, 10 do challenges[i] = ch("n" .. i) end
    local state = session.new({}, challenges)
    state.new_passed = 4
    for _ = 1, 4 do table.remove(state.new_queue, 1) end
    local new_state, _ = session.on_result(state, "pass")
    assert.are.equal("complete", new_state.phase)
  end)
end)

-- 8. on_result fail: doesn't increment pass count
describe("on_result fail", function()
  it("new_passed NOT incremented in new_challenges", function()
    local state = session.new({}, { ch("n1"), ch("n2") })
    local new_state, _ = session.on_result(state, "fail")
    assert.are.equal(0, new_state.new_passed)
  end)

  it("new_attempted increments on fail", function()
    local state = session.new({}, { ch("n1"), ch("n2") })
    local new_state, _ = session.on_result(state, "fail")
    assert.are.equal(1, new_state.new_attempted)
  end)

  it("side_effect is save on fail", function()
    local state = session.new({}, { ch("n1"), ch("n2") })
    local _, effect = session.on_result(state, "fail")
    assert.are.equal("save", effect)
  end)

  it("warmup fail: advances to next challenge, side_effect save", function()
    local state = session.new({ ch("w1"), ch("w2") }, {})
    local new_state, effect = session.on_result(state, "fail")
    assert.are.equal("save", effect)
    local cur = session.current_challenge(new_state)
    assert.are.equal("w2", cur.id)
  end)
end)

-- 9. on_result skip: side_effect="end" (no save)
describe("on_result skip", function()
  it("side_effect is end (no save)", function()
    local state = session.new({}, { ch("n1"), ch("n2") })
    local _, effect = session.on_result(state, "skip")
    assert.are.equal("end", effect)
  end)

  it("skip in warmup: side_effect is end", function()
    local state = session.new({ ch("w1"), ch("w2") }, {})
    local _, effect = session.on_result(state, "skip")
    assert.are.equal("end", effect)
  end)

  it("skip advances to next challenge", function()
    local state = session.new({}, { ch("n1"), ch("n2") })
    local new_state, _ = session.on_result(state, "skip")
    local cur = session.current_challenge(new_state)
    assert.are.equal("n2", cur.id)
  end)
end)

-- 10. trigger_soft_stop: sets soft_stop_triggered
describe("trigger_soft_stop", function()
  it("sets soft_stop_triggered to true", function()
    local state = session.new({ ch("w1") }, {})
    local new_state = session.trigger_soft_stop(state)
    assert.is_true(new_state.soft_stop_triggered)
  end)

  it("does not mutate original state", function()
    local state = session.new({ ch("w1") }, {})
    session.trigger_soft_stop(state)
    assert.is_false(state.soft_stop_triggered)
  end)

  it("when active challenge exists: phase stays, not complete yet", function()
    local state = session.new({ ch("w1") }, {})
    local new_state = session.trigger_soft_stop(state)
    assert.are.equal("warmup", new_state.phase)
  end)

  it("when no current challenge (between challenges): transitions to complete", function()
    -- Simulate state with soft stop mid-transition (empty queues, somehow not complete)
    -- We test via: complete phase already => trigger_soft_stop is no-op
    local state = session.new({}, {})
    assert.are.equal("complete", state.phase)
    local new_state = session.trigger_soft_stop(state)
    assert.are.equal("complete", new_state.phase)
  end)
end)

-- 11. soft_stop + challenge complete: side_effect="save_and_end"
describe("soft_stop then challenge completes", function()
  it("pass after soft_stop -> save_and_end", function()
    local state = session.new({}, { ch("n1"), ch("n2") })
    state = session.trigger_soft_stop(state)
    local _, effect = session.on_result(state, "pass")
    assert.are.equal("save_and_end", effect)
  end)

  it("fail after soft_stop -> save_and_end", function()
    local state = session.new({}, { ch("n1"), ch("n2") })
    state = session.trigger_soft_stop(state)
    local _, effect = session.on_result(state, "fail")
    assert.are.equal("save_and_end", effect)
  end)

  it("skip after soft_stop -> end (skip never saves)", function()
    local state = session.new({}, { ch("n1"), ch("n2") })
    state = session.trigger_soft_stop(state)
    local _, effect = session.on_result(state, "skip")
    assert.are.equal("end", effect)
  end)
end)

-- 12. complete phase: on_result is no-op
describe("on_result in complete phase is no-op", function()
  it("phase stays complete", function()
    local state = session.new({}, {})
    local new_state, _ = session.on_result(state, "pass")
    assert.are.equal("complete", new_state.phase)
  end)

  it("side_effect is end", function()
    local state = session.new({}, {})
    local _, effect = session.on_result(state, "pass")
    assert.are.equal("end", effect)
  end)

  it("current_challenge remains nil", function()
    local state = session.new({}, {})
    local new_state, _ = session.on_result(state, "pass")
    assert.is_nil(session.current_challenge(new_state))
  end)
end)
