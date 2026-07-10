local M = {}

function M.setup_prompt_keymaps(buf, actions, config)
	vim.keymap.set({ "i", "n" }, config.submit, actions.submit, {
		buffer = buf,
		silent = true,
		noremap = true,
	})

	vim.keymap.set("n", config.close, actions.close, {
		buffer = buf,
		silent = true,
		noremap = true,
	})
end

return M
