local M = {}

function M.setup()
	vim.api.nvim_create_user_command("CoderToggle", function()
		require("coder").toggle()
	end, {})

	vim.api.nvim_create_user_command("Coder", function(opts)
		require("coder").run(opts)
	end, { range = true, nargs = "*" })

	vim.api.nvim_create_user_command("CoderDiagnostics", function(opts)
		require("coder").diagnostics(opts)
	end, { range = true, nargs = "*" })

	vim.api.nvim_create_user_command("CoderSession", function()
		require("coder").session()
	end, {})

	vim.api.nvim_create_user_command("CoderChat", function()
		require("coder").chat()
	end, {})

	vim.api.nvim_create_user_command("CoderClose", function()
		require("coder").close()
	end, {})

	vim.api.nvim_create_user_command("CoderAddCurrent", function()
		require("coder").add_current_file()
	end, {})
end

return M
