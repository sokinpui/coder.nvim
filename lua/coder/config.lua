local M = {}

M.options = {
	coder_bin = "coder",
	exec_mode = "terminal", -- "terminal" | "float" | "tmux"
	terminal = {
		split = "vertical", -- "vertical" | "horizontal"
		width = 55,
		height = 15,
	},
	float = {
		width = 0.85,
		height = 0.85,
		border = "rounded",
	},
	auto_reload = true,
	passthrough_keys = { "<C-h>", "<C-v>" },
	keymaps = {
		submit = "<C-j>",
		close = "q",
		toggle = "<C-p>",
		prompt = "<leader>ca",
		add_file = "<leader>cf",
	},
}

function M.set(opts)
	M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M
