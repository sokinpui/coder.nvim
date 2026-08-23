local M = {}

function M.setup_prompt_keymaps(buf, actions, config)
	config = config or {}
	local submit_key = config.submit or "<C-j>"
	local close_key = config.close or "q"

	vim.keymap.set({ "i", "n" }, submit_key, actions.submit, {
		buffer = buf,
		silent = true,
		noremap = true,
	})

	vim.keymap.set("n", close_key, actions.close, {
		buffer = buf,
		silent = true,
		noremap = true,
	})

	vim.keymap.set("n", "<CR>", actions.submit, {
		buffer = buf,
		silent = true,
		noremap = true,
	})

	vim.keymap.set({ "i", "n" }, "<C-s>", actions.submit, {
		buffer = buf,
		silent = true,
		noremap = true,
	})

	vim.keymap.set("n", "<Esc>", actions.close, {
		buffer = buf,
		silent = true,
		noremap = true,
	})
end

function M.setup_terminal_keymaps(buf, passthrough_keys)
	if not passthrough_keys or #passthrough_keys == 0 then
		return
	end
	for _, key in ipairs(passthrough_keys) do
		vim.keymap.set("t", key, key, {
			buffer = buf,
			nowait = true,
			noremap = true,
		})
	end
end

return M
