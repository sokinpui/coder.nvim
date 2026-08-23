local context = require("coder.context")
local keymap = require("coder.keymap")

local M = {}

local state = {
	terminal_buf = nil,
	tmux_pane = nil,
	terminal_win = nil,
	chan_id = nil,
	prev_win = nil,
}

local function build_cmd_string(args, config)
	local parts = { config.coder_bin }
	if args then
		for _, arg in ipairs(args) do
			table.insert(parts, vim.fn.shellescape(arg))
		end
	end
	for _, f in ipairs(context.get_files()) do
		table.insert(parts, vim.fn.shellescape(f))
	end
	return table.concat(parts, " ")
end

local function run_in_tmux(cmd_str, config)
	local escaped_cmd = vim.fn.shellescape(cmd_str)
	local tmux_cmd = string.format("tmux split-window -h -P -F '#{pane_id}' %s", escaped_cmd)
	local pane_id = vim.fn.system(tmux_cmd)
	state.tmux_pane = vim.trim(pane_id)
end

local function create_window(config, buf)
	local mode = config.exec_mode
	if mode == "float" then
		local width = math.floor(vim.o.columns * (config.float.width or 0.75))
		local height = math.floor(vim.o.lines * (config.float.height or 0.75))
		local row = math.floor((vim.o.lines - height) / 2)
		local col = math.floor((vim.o.columns - width) / 2)
		return vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = width,
			height = height,
			row = row,
			col = col,
			style = "minimal",
			border = config.float.border or "rounded",
			title = " Coder ",
			title_pos = "center",
		})
	end

	local is_vert = (config.terminal.split or "vertical") == "vertical"
	if is_vert then
		local width = config.terminal.width or 55
		vim.cmd("botright " .. width .. "vsplit")
	else
		local height = config.terminal.height or 15
		vim.cmd("botright " .. height .. "split")
	end

	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)
	return win
end

local function setup_autocmds(buf, config)
	if not config.auto_reload then
		return
	end
	local group = vim.api.nvim_create_augroup("CoderTermAutoReload_" .. buf, { clear = true })
	vim.api.nvim_create_autocmd({ "TermLeave", "BufLeave" }, {
		group = group,
		buffer = buf,
		callback = function()
			vim.cmd("checktime")
		end,
	})
end

function M.close()
	if state.terminal_win and vim.api.nvim_win_is_valid(state.terminal_win) then
		pcall(vim.api.nvim_win_close, state.terminal_win, true)
		state.terminal_win = nil
	end

	if state.tmux_pane and os.getenv("TMUX") then
		local check_cmd = string.format("tmux has-session -t %s 2>/dev/null", state.tmux_pane)
		if os.execute(check_cmd) == 0 then
			vim.fn.system(string.format("tmux kill-pane -t %s 2>/dev/null", state.tmux_pane))
		end
		state.tmux_pane = nil
	end
end

function M.toggle(config)
	if config.exec_mode == "tmux" then
		if state.tmux_pane then
			M.close()
			return
		end
		M.run({}, config)
		return
	end

	if state.terminal_win and vim.api.nvim_win_is_valid(state.terminal_win) then
		local curr_win = vim.api.nvim_get_current_win()
		if curr_win == state.terminal_win then
			pcall(vim.api.nvim_win_hide, state.terminal_win)
			state.terminal_win = nil
			if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
				vim.api.nvim_set_current_win(state.prev_win)
			end
			if config.auto_reload then
				vim.cmd("checktime")
			end
			return
		end
		vim.api.nvim_set_current_win(state.terminal_win)
		vim.cmd("startinsert")
		return
	end

	M.open({}, config)
end

function M.open(args, config)
	if vim.fn.executable(config.coder_bin) ~= 1 then
		vim.api.nvim_err_writeln("[Coder] '" .. config.coder_bin .. "' not found in PATH")
		return
	end

	if config.exec_mode == "tmux" and os.getenv("TMUX") then
		local cmd_str = build_cmd_string(args, config)
		run_in_tmux(cmd_str, config)
		return
	end

	state.prev_win = vim.api.nvim_get_current_win()

	if state.terminal_buf and vim.api.nvim_buf_is_valid(state.terminal_buf) then
		if not state.terminal_win or not vim.api.nvim_win_is_valid(state.terminal_win) then
			state.terminal_win = create_window(config, state.terminal_buf)
		else
			vim.api.nvim_set_current_win(state.terminal_win)
		end
		vim.cmd("startinsert")
		return state.chan_id
	end

	local cmd_str = build_cmd_string(args, config)
	local buf = vim.api.nvim_create_buf(false, true)
	state.terminal_buf = buf

	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "hide"
	vim.bo[buf].buflisted = false
	vim.bo[buf].swapfile = false

	state.terminal_win = create_window(config, buf)

	vim.wo[state.terminal_win].number = false
	vim.wo[state.terminal_win].relativenumber = false
	vim.wo[state.terminal_win].signcolumn = "no"

	state.chan_id = vim.fn.termopen(cmd_str, {
		env = {
			CODER_OPEN_CMD = 'for f in "$@"; do nvim --server ' .. vim.fn.shellescape(vim.v.servername) .. ' --remote-expr "v:lua.require(\'coder.executor\').open_file(\'"$f"\')"; done',
		},
		on_exit = function()
			state.chan_id = nil
			if state.terminal_buf and vim.api.nvim_buf_is_valid(state.terminal_buf) then
				pcall(vim.api.nvim_buf_delete, state.terminal_buf, { force = true })
			end
			state.terminal_buf = nil
			state.terminal_win = nil
		end,
	})

	setup_autocmds(buf, config)
	keymap.setup_terminal_keymaps(buf, config.passthrough_keys)
	vim.cmd("startinsert")
	return state.chan_id
end

function M.open_file(filepath)
	if not filepath or filepath == "" then
		return ""
	end

	local target_win = state.prev_win
	if not target_win or not vim.api.nvim_win_is_valid(target_win) or target_win == state.terminal_win then
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if win ~= state.terminal_win and vim.api.nvim_win_get_config(win).relative == "" then
				target_win = win
				break
			end
		end
	end

	if target_win and vim.api.nvim_win_is_valid(target_win) then
		vim.api.nvim_set_current_win(target_win)
	else
		vim.cmd("wincmd p")
	end

	vim.cmd("edit " .. vim.fn.fnameescape(filepath))
	return ""
end

function M.send(text, config, new_session)
	if not state.terminal_buf or not vim.api.nvim_buf_is_valid(state.terminal_buf) or not state.chan_id then
		M.open({}, config)
		local paste_sequence = string.format("\27[200~%s\27[201~\n", text)
		vim.defer_fn(function()
			if state.chan_id then
				vim.api.nvim_chan_send(state.chan_id, paste_sequence)
			end
		end, 150)
		return
	end

	if not state.terminal_win or not vim.api.nvim_win_is_valid(state.terminal_win) then
		state.terminal_win = create_window(config, state.terminal_buf)
	else
		vim.api.nvim_set_current_win(state.terminal_win)
	end
	vim.cmd("startinsert")

	-- Use terminal bracketed paste sequence so multiline prompts insert cleanly,
	-- followed by newline (\n / Ctrl+J) to submit to Coder.
	local paste_sequence = string.format("\27[200~%s\27[201~\n", text)
	if new_session then
		vim.api.nvim_chan_send(state.chan_id, "\3/new\n")
		vim.defer_fn(function()
			if state.chan_id then
				vim.api.nvim_chan_send(state.chan_id, paste_sequence)
			end
		end, 60)
	else
		vim.api.nvim_chan_send(state.chan_id, paste_sequence)
	end
end

M.run = M.open
return M
