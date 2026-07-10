local M = {}

function M.get_files()
	local paths = { "." }
	local seen = { ["."] = true }

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if not vim.api.nvim_buf_is_loaded(buf) then
			goto next_buffer
		end

		local name = vim.api.nvim_buf_get_name(buf)
		local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
		if name == "" or buftype ~= "" then
			goto next_buffer
		end

		local rel_path = vim.fn.fnamemodify(name, ":.")
		if vim.fn.getftype(rel_path) == "" then
			goto next_buffer
		end

		if not seen[rel_path] then
			table.insert(paths, rel_path)
			seen[rel_path] = true
		end
		::next_buffer::
	end
	return paths
end

function M.get_selection(line1, line2)
	local file = vim.api.nvim_buf_get_name(0)
	local rel_path = vim.fn.fnamemodify(file, ":.")
	local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
	local selection_content = table.concat(lines, "\n")
	return {
		file = rel_path,
		start_line = line1,
		end_line = line2,
		content = selection_content,
	}
end

return M
