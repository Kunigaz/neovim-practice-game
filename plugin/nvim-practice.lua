vim.api.nvim_create_user_command("NPractice", function()
  require("nvim-practice").start()
end, {})

vim.api.nvim_create_user_command("NPracticeSkip", function()
  require("nvim-practice").skip()
end, {})
