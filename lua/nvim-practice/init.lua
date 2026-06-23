local M = {}

M.setup = function(opts)
  opts = opts or {}
  M.opts = {
    hud_position = opts.hud_position or "top-right",
  }
end

M.start = function()
  local orchestrator = require("nvim-practice.orchestrator")
  orchestrator.start_session()
end

M.skip = function()
  local orchestrator = require("nvim-practice.orchestrator")
  orchestrator.skip()
end

return M
