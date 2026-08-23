# coder.nvim

A Neovim plugin for the [AI coding TUI `coder`](https://github.com/sokinpui/coder).

`coder.nvim` seamlessly integrates the interactive Coder TUI with Neovim as a persistent, toggleable sidebar or floating window with bi-directional IPC support.

## Prerequisites

- [`coder` CLI](https://github.com/sokinpui/coder) installed and available in your `$PATH`.
- (Optional) `tmux` for `exec_mode = "tmux"`.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "sokinpui/coder.nvim",
    opts = {
        exec_mode = "terminal", -- "terminal" | "float" | "tmux"
        terminal = {
            split = "vertical",
            width = 55,
        },
        auto_reload = true,
    },
}
```

### Lazy-loading Configuration

You can lazy load the plugin on specific commands or keymaps to keep your startup time fast.

```lua
{
    "sokinpui/coder.nvim",
    cmd = {
        "CoderToggle",
        "Coder",
        "CoderAddCurrent",
        "CoderClose",
    },
    keys = {
        { "<C-p>", "<cmd>CoderToggle<CR>", mode = { "n", "v" }, desc = "Toggle Coder TUI" },
        { "<leader>cf", "<cmd>CoderAddCurrent<CR>", desc = "Add current file to Coder context" },
        {
            "<leader>ca",
            "<cmd>Coder<CR>",
            mode = { "n", "v" },
            desc = "Coder Prompt",
        },
    },
    opts = {},
}
```

## Configuration

Default options:

```lua
require("coder").setup({
    -- Path to the coder executable
    coder_bin = "coder",

    -- Execution mode: "terminal", "float", or "tmux"
    exec_mode = "terminal",

    -- Configuration for terminal split drawer
    terminal = {
        split = "vertical", -- "vertical" | "horizontal"
        width = 55,
        height = 15,
    },

    -- Configuration for floating window
    float = {
        width = 0.85,
        height = 0.85,
        border = "rounded",
    },

    -- Automatically run checktime when switching away from Coder (applies ITF changes immediately)
    auto_reload = true,
    passthrough_keys = { "<C-h>", "<C-v>" },
    keymaps = {
        submit = "<C-j>",
        close = "q",
        toggle = "<C-p>",
        prompt = "<leader>ca",
        add_file = "<leader>cf",
    },
})
```

## Commands

| Command            | Description                                                                   |
| ------------------ | ----------------------------------------------------------------------------- |
| `:CoderToggle`     | Toggles the persistent Coder TUI window without restarting the session.       |
| `:Coder`           | Opens a floating window to input a prompt. Passes open buffers as context.    |
| `:'<,'>Coder`      | (Visual Mode) Same as above, but includes the selected text and line numbers. |
| `:CoderAddCurrent` | Injects `/file <current_file>` directly into the active Coder instance.       |
| `:CoderClose`      | Closes the active `coder` terminal or tmux pane.                              |

## Bi-Directional Features

1. **Persistent Session**: Coder runs in a persistent background terminal buffer. Hiding or showing the window maintains the running model state and chat history.
2. **Neovim RPC Integration**: Searching files inside Coder with `Ctrl+F` targets the parent Neovim window directly (`:edit <file>`) instead of spawning nested editors.
3. **Auto Buffer Reload**: When code modifications are applied via `Ctrl+A` (`itf`) inside Coder, Neovim automatically detects the disk updates without prompting.
