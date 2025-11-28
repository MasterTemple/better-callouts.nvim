# `better-callouts.nvim`

Render callouts in Neovim

## Setup

Example Lazy.nvim config at `~/.config/nvim/lua/plugins/better-callouts.lua`

```lua
return {
  'mastertemple/better-callouts.nvim',
  ft = 'markdown', -- Lazy-load only for markdown filetypes

  opts = {
    -- This is where you override the default options.
    callouts = {
      bible = {
        icon = '',
        highlight = '@label',
      },
    },
    -- You can provide your own fallback function.
    fallback = function(name)
      -- Let's create a more dynamic fallback
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

## Screenshots

Example rendering:

![](./assets/screenshot.png)
