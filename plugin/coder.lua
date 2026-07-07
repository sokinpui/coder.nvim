if vim.g.loaded_coder == 1 then
  return
end
vim.g.loaded_coder = 1

vim.api.nvim_create_user_command("CoderAsk", function(opts)
  require("coder").ask(opts)
end, { range = true })
