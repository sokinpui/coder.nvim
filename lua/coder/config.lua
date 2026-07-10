local M = {}

M.options = {
	coder_bin = "coder",
	exec_mode = "tmux",
	terminal_split = "horizontal",
	keymaps = {
		submit = "<C-j>",
		close = "q",
	},
}

function M.set(opts)
	M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M
