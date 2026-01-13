# `better-callouts.nvim`

Render embeds & callouts in Neovim.

## Features

- Custom color for default embeds
- Extendable callout list
- Callout title, icon, and gutter highlighting
- Dynamic callout fallback function
- Nest callouts and embeds
- Auto-continue top-level callouts/embed

![](./assets/screenshot.png)

## Setup

Example Lazy.nvim config at `~/.config/nvim/lua/plugins/better-callouts.lua`

```lua
return {
  'MasterTemple/better-callouts.nvim',
  ft = 'markdown', -- Lazy-load only for markdown filetypes

  -- All of these are optional
  opts = {
    -- This is where you override the default options.
    callouts = {
      warning = {
        icon = "",
        highlight = "DiagnosticWarn",
        aliases = { "caution", "attention" }
      },
    },
    -- Default embed color
    embed_color = '@none',
    -- Provide your own fallback function.
    fallback = function(name)
      -- `asdf` -> `[A]`
      local first_char = string.sub(name, 1, 1):upper()
      return {
        icon = '[' .. first_char .. ']',
        highlight = 'Comment',
      }
    end,
  },

  -- The `config` function is executed after the plugin is loaded.
  -- It's the standard way to call a plugin's setup function.
  config = function(_, opts)
    require('better-callouts').setup(opts)
  end,
}
```

## TODO

1. Fix visual selection preview
