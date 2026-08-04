local context = require("coder.context")

local M = {}

local state = {
	terminal_buf = nil,
	tmux_pane = nil,
}

local function run_in_tmux(cmd_str)
	local escaped_cmd = vim.fn.shellescape(cmd_str)
	local tmux_cmd = string.format("tmux split-window -h -P -F '#{pane_id}' %s", escaped_cmd)
	local pane_id = vim.fn.system(tmux_cmd)
	state.tmux_pane = vim.trim(pane_id)
end

local function run_in_terminal(cmd_str, split_direction, width)
	M.close()

	local prefix = ""
	if split_direction == "vertical" then
		prefix = width .. "vsplit"
	else
		prefix = "split"
	end

	vim.cmd(prefix .. " | enew")
	local buf = vim.api.nvim_get_current_buf()

	vim.opt_local.number = false
	vim.opt_local.relativenumber = false
	vim.opt_local.signcolumn = "no"

	vim.fn.termopen(cmd_str)
	state.terminal_buf = buf
	vim.cmd("startinsert")
end

function M.close()
	if state.terminal_buf and vim.api.nvim_buf_is_valid(state.terminal_buf) then
		vim.api.nvim_buf_delete(state.terminal_buf, { force = true })
		state.terminal_buf = nil
		return
	end

	if state.tmux_pane and os.getenv("TMUX") then
		local check_cmd = string.format("tmux has-session -t %s 2>/dev/null", state.tmux_pane)
		if os.execute(check_cmd) == 0 then
			vim.fn.system(string.format("tmux kill-pane -t %s", state.tmux_pane))
		end
		state.tmux_pane = nil
		return
	end
end

function M.run(args, config)
	if vim.fn.executable(config.coder_bin) ~= 1 then
		vim.api.nvim_err_writeln("[Coder] '" .. config.coder_bin .. "' not found in PATH")
		return
	end

	local cmd_parts = { config.coder_bin }
	vim.list_extend(cmd_parts, args or {})

	for _, f in ipairs(context.get_files()) do
		table.insert(cmd_parts, vim.fn.shellescape(f))
	end

	local cmd_str = table.concat(cmd_parts, " ")

	if config.exec_mode == "tmux" and os.getenv("TMUX") then
		run_in_tmux(cmd_str)
		return
	end

	run_in_terminal(cmd_str, config.terminal_split, config.terminal_width)
end

return M
