local keymap = require("coder.keymap")

local M = {}

function M.open_prompt(title, config, on_submit)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].filetype = "markdown"
	vim.bo[buf].bufhidden = "wipe"

	local width = math.floor(vim.o.columns * ((config.float and config.float.prompt_width) or 0.6))
	local height = math.floor(vim.o.lines * ((config.float and config.float.prompt_height) or 0.35))
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = (config.float and config.float.border) or "rounded",
		title = " " .. title .. " [Ctrl+J: Submit | Esc: Cancel] ",
		title_pos = "center",
	})

	vim.wo[win].wrap = true
	vim.wo[win].number = true

	local closed = false

	local function close_window()
		if closed then
			return
		end
		closed = true
		if vim.api.nvim_win_is_valid(win) then
			pcall(vim.api.nvim_win_close, win, true)
		end
		if vim.api.nvim_buf_is_valid(buf) then
			pcall(vim.api.nvim_buf_delete, buf, { force = true })
		end
	end

	local function submit()
		if closed then
			return
		end
		vim.cmd("stopinsert")
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local prompt_content = table.concat(lines, "\n")

		close_window()

		if vim.trim(prompt_content) == "" then
			return
		end

		vim.schedule(function()
			on_submit(prompt_content)
		end)
	end

	local function cancel()
		if closed then
			return
		end
		vim.cmd("stopinsert")
		close_window()
	end

	keymap.setup_prompt_keymaps(buf, {
		submit = submit,
		close = cancel,
	}, config.keymaps)

	vim.cmd("startinsert")
end

return M
