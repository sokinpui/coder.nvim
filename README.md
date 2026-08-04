# coder.nvim

A Neovim plugin for the [AI coding TUI `coder`](https://github.com/sokinpui/coder).

## Prerequisites

- [`coder` CLI](https://github.com/example/coder) installed and available in your `$PATH`.
- (Optional) `tmux` for `exec_mode = "tmux"`.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

### Basic Setup

```lua
{
    "sokinpui/coder.nvim",
    opts = {
        -- your configuration here
    },
}
```

### Lazy Loading (Recommended)

You can lazy load the plugin on specific commands or keymaps to keep your startup time fast.

```lua
{
    "sokinpui/coder.nvim",
    cmd = {
        "Coder",
        "CoderChat",
        "CoderSession",
        "CoderClose",
    },
    keys = {
        { "<leader>cc", "<cmd>CoderChat<cr>", desc = "Coder Chat" },
        { "<leader>cs", "<cmd>CoderSession<cr>", desc = "Coder Session" },
        {
            "<leader>ca",
            ":Coder<cr>",
            mode = { "n", "v" },
            desc = "Coder Prompt (Contextual)",
        },
    },
    opts = {
        exec_mode = "tmux", -- or "terminal"
    },
}
```

## Default Configuration

```lua
require("coder").setup({
    -- Path to the coder executable
    coder_bin = "coder",

    -- Execution mode: "tmux" or "terminal"
    -- "tmux" opens a split in your current tmux session
    -- "terminal" opens a Neovim terminal split
    exec_mode = "tmux",

    -- Split direction for Neovim terminal: "horizontal" or "vertical"
    terminal_split = "vertical",

    -- Width of the vertical terminal split
    terminal_width = 50,

    -- Keymaps for the prompt window
    keymaps = {
        submit = "<C-j>",
        close = "q",
    },
})
```

## Usage

### Commands

| Command         | Description                                                                   |
| --------------- | ----------------------------------------------------------------------------- |
| `:Coder`        | Opens a floating window to input a prompt. Passes open buffers as context.    |
| `:'<,'>Coder`   | (Visual Mode) Same as above, but includes the selected text and line numbers. |
| `:CoderChat`    | Opens the `coder chat` interface in the configured execution mode.            |
| `:CoderClose`   | Closes the active `coder` terminal or tmux pane.                              |
| `:CoderSession` | Opens the base `coder` session in the configured execution mode.              |

## How it works

1.  **Context Gathering**: The plugin scans all loaded buffers in your current Neovim session and collects their relative file paths.
2.  **Execution**: Upon submission, it constructs a command: `coder <context_paths> -p <your_prompt>` and executes it in the specified `exec_mode`.
