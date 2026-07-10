local context = require("coder.context")

local M = {}

local function run_in_tmux(cmd_str)
	local escaped_cmd = vim.fn.shellescape(cmd_str)
	local tmux_cmd = string.format("tmux split-window -h %s", escaped_cmd)
	vim.fn.system(tmux_cmd)
end

local function run_in_terminal(cmd_str, split_direction)
	if split_direction == "vertical" then
		vim.cmd("vsplit")
	else
		vim.cmd("split")
	end
	vim.fn.termopen(cmd_str)
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

	run_in_terminal(cmd_str, config.terminal_split)
end

return M
