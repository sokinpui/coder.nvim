local config = require("coder.config")
local executor = require("coder.executor")
local context = require("coder.context")
local ui = require("coder.ui")

local M = {}

function M.setup(opts)
	config.set(opts)
	require("coder.command").setup()
end

function M.toggle()
	executor.toggle(config.options)
end

function M.session()
	executor.open({}, config.options)
end

function M.chat()
	executor.open({ "--chat" }, config.options)
end

function M.add_current_file()
	local current_file = vim.api.nvim_buf_get_name(0)
	if current_file == "" then
		return
	end
	local rel_path = vim.fn.fnamemodify(current_file, ":.")
	executor.send("/file " .. rel_path, config.options, false)
	vim.notify("[Coder] Added file to context: " .. rel_path, vim.log.levels.INFO)
end

function M.close()
	executor.close()
end

function M.run(opts)
	opts = opts or {}

	local current_file = vim.api.nvim_buf_get_name(0)
	local rel_current_file = current_file ~= "" and vim.fn.fnamemodify(current_file, ":.") or ""

	local selection = nil
	if opts.range and opts.range > 0 then
		selection = context.get_selection(opts.line1, opts.line2)
	else
		local mode = vim.api.nvim_get_mode().mode
		if mode:find("^[vV]") or mode:find("^\22") then
			local line1 = vim.fn.line("v")
			local line2 = vim.fn.line(".")
			if line1 > line2 then
				line1, line2 = line2, line1
			end
			selection = context.get_selection(line1, line2)
		end
	end

	local function execute_prompt(user_prompt)
		local prompt_parts = {}

		if selection and selection.content ~= "" then
			local file_ext = vim.fn.fnamemodify(selection.file, ":e")
			table.insert(
				prompt_parts,
				string.format(
					"In `%s` (lines %d-%d):\n```%s\n%s\n```",
					selection.file,
					selection.start_line,
					selection.end_line,
					file_ext,
					selection.content
				)
			)
		elseif rel_current_file ~= "" and vim.fn.filereadable(current_file) == 1 then
			table.insert(prompt_parts, string.format("Regarding `%s`:", rel_current_file))
		end

		table.insert(prompt_parts, user_prompt)
		local final_prompt = table.concat(prompt_parts, "\n\n")

		if config.options.exec_mode == "tmux" then
			executor.run({ "-p", vim.fn.shellescape(final_prompt) }, config.options)
		else
			executor.send(final_prompt, config.options, true)
		end
	end

	if opts.args and vim.trim(opts.args) ~= "" then
		execute_prompt(opts.args)
	else
		ui.open_prompt("Coder", config.options, function(user_prompt)
			execute_prompt(user_prompt)
		end)
	end
end

function M.diagnostics(opts)
	opts = opts or {}
	local bufnr = vim.api.nvim_get_current_buf()
	local current_file = vim.api.nvim_buf_get_name(bufnr)
	local rel_current_file = current_file ~= "" and vim.fn.fnamemodify(current_file, ":.") or ""

	local line1, line2 = nil, nil
	local selection = nil

	if opts.range and opts.range > 0 then
		line1, line2 = opts.line1, opts.line2
		selection = context.get_selection(line1, line2)
	else
		local mode = vim.api.nvim_get_mode().mode
		if mode:find("^[vV]") or mode:find("^\22") then
			line1 = vim.fn.line("v")
			line2 = vim.fn.line(".")
			if line1 > line2 then
				line1, line2 = line2, line1
			end
			selection = context.get_selection(line1, line2)
		end
	end

	local diags = context.get_diagnostics(bufnr, line1, line2)
	if #diags == 0 then
		vim.notify("[Coder] No diagnostics found in current " .. (selection and "selection" or "buffer"), vim.log.levels.WARN)
		return
	end

	local diag_text = context.format_diagnostics(diags, rel_current_file, line1, line2)

	local function execute_prompt(user_prompt)
		local prompt_parts = {}

		if selection and selection.content ~= "" then
			local file_ext = vim.fn.fnamemodify(selection.file, ":e")
			table.insert(
				prompt_parts,
				string.format(
					"In `%s` (lines %d-%d):\n```%s\n%s\n```",
					selection.file,
					selection.start_line,
					selection.end_line,
					file_ext,
					selection.content
				)
			)
		elseif rel_current_file ~= "" and vim.fn.filereadable(current_file) == 1 then
			table.insert(prompt_parts, string.format("Regarding `%s`:", rel_current_file))
		end

		table.insert(prompt_parts, diag_text)
		table.insert(prompt_parts, (user_prompt and vim.trim(user_prompt) ~= "") and user_prompt or "Please fix the diagnostic issues reported above.")

		local final_prompt = table.concat(prompt_parts, "\n\n")
		if config.options.exec_mode == "tmux" then
			executor.run({ "-p", vim.fn.shellescape(final_prompt) }, config.options)
		else
			executor.send(final_prompt, config.options, true)
		end
	end

	if opts.args and vim.trim(opts.args) ~= "" then
		execute_prompt(opts.args)
	else
		ui.open_prompt("Coder Diagnostics", config.options, function(user_prompt)
			execute_prompt(user_prompt)
		end)
	end
end

return M
