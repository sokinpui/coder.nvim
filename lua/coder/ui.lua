local keymap = require("coder.keymap")

local M = {}

function M.open_prompt(title, config, on_submit)
	local temp_file = vim.fn.tempname() .. ".md"
	local buf = vim.fn.bufadd(temp_file)
	vim.fn.bufload(buf)

	vim.api.nvim_buf_set_option(buf, "buflisted", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "coder")
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

	local width = math.floor(vim.o.columns * 0.7)
	local height = math.floor(vim.o.lines * 0.5)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = title,
		title_pos = "center",
	})

	vim.api.nvim_win_set_option(win, "wrap", true)
	vim.api.nvim_win_set_option(win, "number", true)

	local state = {
		saved = false,
		executed = false,
		group = vim.api.nvim_create_augroup("CoderPromptGroup_" .. buf, { clear = true }),
	}

	local function cleanup()
		if state.executed then
			return
		end
		state.executed = true
		pcall(vim.api.nvim_del_augroup_by_id, state.group)
		pcall(os.remove, temp_file)
	end

	local function submit()
		if state.executed then
			return
		end
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local prompt_content = table.concat(lines, "\n")

		state.executed = true
		cleanup()

		if vim.api.nvim_buf_is_valid(buf) then
			pcall(vim.api.nvim_buf_delete, buf, { force = true })
		end

		if vim.trim(prompt_content) == "" then
			return
		end

		vim.schedule(function()
			on_submit(prompt_content)
		end)
	end

	vim.api.nvim_create_autocmd("BufWritePost", {
		group = state.group,
		buffer = buf,
		callback = function()
			state.saved = true
		end,
	})

	vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout", "BufHidden" }, {
		group = state.group,
		buffer = buf,
		callback = function()
			if not state.saved or state.executed then
				cleanup()
				return
			end

			state.executed = true
			local lines = vim.fn.readfile(temp_file)
			local prompt_content = table.concat(lines, "\n")
			cleanup()

			vim.schedule(function()
				on_submit(prompt_content)
			end)
		end,
	})

	keymap.setup_prompt_keymaps(buf, {
		submit = submit,
		close = function()
			vim.api.nvim_win_close(win, true)
		end,
	}, config.keymaps)

	vim.cmd("startinsert")
end

return M
