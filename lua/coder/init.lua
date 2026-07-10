local config = require("coder.config")
local executor = require("coder.executor")
local context = require("coder.context")
local ui = require("coder.ui")

local M = {}

function M.setup(opts)
	config.set(opts)
	require("coder.command").setup()
end

function M.session()
	executor.run({}, config.options)
end

function M.chat()
	executor.run({ "chat" }, config.options)
end

function M.run(opts)
	opts = opts or {}

	local current_file = vim.api.nvim_buf_get_name(0)
	local rel_current_file = vim.fn.fnamemodify(current_file, ":.")
	local is_visual = (opts.range and opts.range > 0)

	ui.open_prompt(" Coder ", config.options, function(user_prompt)
		local context_metadata = string.format("User is watching this file: `%s`", rel_current_file)

		if is_visual then
			local selection = context.get_selection(opts.line1, opts.line2)
			context_metadata = string.format(
				"In file `%s`, lines %d to %d:\n```\n%s\n```",
				selection.file,
				selection.start_line,
				selection.end_line,
				selection.content
			)
		end

		local final_prompt = string.format("%s\n\nUser request: %s", context_metadata, user_prompt)
		executor.run({ "-p", vim.fn.shellescape(final_prompt) }, config.options)
	end)
end

return M
