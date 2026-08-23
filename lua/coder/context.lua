local M = {}

local severity_names = {
	[vim.diagnostic.severity.ERROR] = "ERROR",
	[vim.diagnostic.severity.WARN] = "WARN",
	[vim.diagnostic.severity.INFO] = "INFO",
	[vim.diagnostic.severity.HINT] = "HINT",
}

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
	if not line1 or not line2 then
		return nil
	end

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

function M.get_diagnostics(bufnr, line1, line2)
	bufnr = (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_get_current_buf()
	if not vim.diagnostic or not vim.diagnostic.get then
		return {}
	end

	local diags = vim.diagnostic.get(bufnr)
	if not diags or #diags == 0 then
		return {}
	end

	local result = {}
	for _, d in ipairs(diags) do
		local line = (d.lnum or 0) + 1
		local end_line = (d.end_lnum or d.lnum or 0) + 1
		local in_range = true
		if line1 and line2 then
			in_range = not (end_line < line1 or line > line2)
		end

		if in_range then
			local sev = severity_names[d.severity] or "INFO"
			local src = d.source and string.format(" (%s)", d.source) or ""
			local code = d.code and string.format(" [%s]", d.code) or ""
			local col_info = d.col and string.format(":%d", d.col + 1) or ""
			table.insert(result, {
				lnum = line,
				end_lnum = end_line,
				col = d.col,
				severity = sev,
				source = d.source,
				code = d.code,
				message = d.message or "",
				formatted = string.format("- [%s] Line %d%s: %s%s%s", sev, line, col_info, d.message or "", src, code),
			})
		end
	end

	table.sort(result, function(a, b)
		if a.lnum == b.lnum then
			return (a.col or 0) < (b.col or 0)
		end
		return a.lnum < b.lnum
	end)

	return result
end

function M.format_diagnostics(diagnostics, file_rel_path, line1, line2)
	if not diagnostics or #diagnostics == 0 then
		return nil
	end

	local header = (line1 and line2) and string.format("Diagnostics in `%s` (lines %d-%d):", file_rel_path, line1, line2)
		or (file_rel_path ~= "" and string.format("Diagnostics in `%s`:", file_rel_path) or "Diagnostics:")
	return table.concat(vim.list_extend({ header }, vim.tbl_map(function(d) return d.formatted end, diagnostics)), "\n")
end

return M
