local M = {}

M.config = {
  coder_bin = "coder",
  exec_mode = "tmux", -- "tmux" or "terminal"
  terminal_split = "horizontal", -- "horizontal" or "vertical"
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

local function get_buffer_files()
  local files = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
      if name ~= "" and buftype == "" then
        local rel_path = vim.fn.fnamemodify(name, ":.")
        if vim.fn.filereadable(rel_path) == 1 then
          table.insert(files, rel_path)
        end
      end
    end
  end
  return files
end

local function get_selection_metadata(line1, line2)
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

local function open_prompt_window(title, on_submit)
  local temp_file = vim.fn.tempname() .. ".md"
  local buf = vim.fn.bufadd(temp_file)
  vim.fn.bufload(buf)

  vim.api.nvim_buf_set_option(buf, "buflisted", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
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

  local saved = false
  local executed = false
  local group = vim.api.nvim_create_augroup("CoderPromptGroup_" .. buf, { clear = true })

  local function cleanup()
    if executed then return end
    executed = true
    pcall(vim.api.nvim_del_augroup_by_id, group)
    pcall(os.remove, temp_file)
  end

  local function submit()
    if executed then return end
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local prompt_content = table.concat(lines, "\n")

    executed = true
    cleanup()
    pcall(vim.api.nvim_buf_delete, buf, { force = true })

    if vim.trim(prompt_content) ~= "" then
      vim.schedule(function()
        on_submit(prompt_content)
      end)
    end
  end

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    buffer = buf,
    callback = function()
      saved = true
    end,
  })

  vim.api.nvim_create_autocmd({"BufDelete", "BufWipeout", "BufHidden"}, {
    group = group,
    buffer = buf,
    callback = function()
      if saved and not executed then
        executed = true
        local lines = vim.fn.readfile(temp_file)
        local prompt_content = table.concat(lines, "\n")
        cleanup()
        vim.schedule(function()
          on_submit(prompt_content)
        end)
      else
        cleanup()
      end
    end,
  })

  vim.keymap.set({"i", "n"}, "<C-j>", submit, { buffer = buf, silent = true, noremap = true })
  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true, noremap = true })

  vim.cmd("startinsert")
end

local function run_in_tmux(cmd_str)
  local escaped_cmd = vim.fn.shellescape(cmd_str)
  local tmux_cmd = string.format("tmux split-window -h %s", escaped_cmd)
  vim.fn.system(tmux_cmd)
end

local function run_in_terminal(cmd_str)
  if M.config.terminal_split == "vertical" then
    vim.cmd("vsplit")
  else
    vim.cmd("split")
  end
  vim.fn.termopen(cmd_str)
end

local function run_coder(cmd_parts)
  local cmd_str = table.concat(cmd_parts, " ")
  if M.config.exec_mode == "tmux" and os.getenv("TMUX") then
    run_in_tmux(cmd_str)
  else
    run_in_terminal(cmd_str)
  end
end

function M.ask(opts)
  opts = opts or {}
  local is_visual = (opts.range and opts.range > 0)

  if vim.fn.executable(M.config.coder_bin) ~= 1 then
    vim.api.nvim_err_writeln("[Coder] '" .. M.config.coder_bin .. "' not found in PATH")
    return
  end

  local files = get_buffer_files()

  if not is_visual then
    local cmd_parts = { M.config.coder_bin }
    for _, f in ipairs(files) do
      table.insert(cmd_parts, vim.fn.shellescape(f))
    end
    run_coder(cmd_parts)
    return
  end

  local selection = get_selection_metadata(opts.line1, opts.line2)

  open_prompt_window(" Coder Ask ", function(user_prompt)
    if vim.trim(user_prompt) == "" then
      return
    end

    local final_prompt = string.format(
      "In file `%s`, lines %d to %d:\n```\n%s\n```\n\nUser request: %s",
      selection.file,
      selection.start_line,
      selection.end_line,
      selection.content,
      user_prompt
    )

    local cmd_parts = {
      M.config.coder_bin,
      "-p",
      vim.fn.shellescape(final_prompt),
    }
    for _, f in ipairs(files) do
      table.insert(cmd_parts, vim.fn.shellescape(f))
    end
    run_coder(cmd_parts)
  end)
end

return M
