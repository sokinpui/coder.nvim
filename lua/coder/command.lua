local M = {}

function M.setup()
	vim.api.nvim_create_user_command("Coder", function(opts)
		require("coder").run(opts)
	end, { range = true })

	vim.api.nvim_create_user_command("CoderChat", function()
		require("coder").chat()
	end, {})

	vim.api.nvim_create_user_command("CoderSession", function()
		require("coder").session()
	end, {})

	vim.api.nvim_create_user_command("CoderClose", function()
		require("coder").close()
	end, {})
end

return M
