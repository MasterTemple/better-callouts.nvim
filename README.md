Example Lazy.nvim config at `~/.config/nvim/lua/plugins/better-callouts.lua`

```lua
return {
  -- For local development, use 'dir'
  -- dir = '/path/to/your/projects/better-callouts.nvim',

  -- For installing from a GitHub repository (once you publish it)
  -- 'your-username/better-callouts.nvim',

  -- Example using a placeholder GitHub repo for demonstration
  -- 'nvim-lua/plenary.nvim', -- A dependency, just as an example
  name = 'better-callouts.nvim', -- Optional: set a custom name for the plugin
  -- dir = vim.fn.stdpath 'config' .. '/path/to/plugin/better-callouts.nvim', -- Example local path
  dir = '/home/dgmastertemple/Development/lua/better-callouts.nvim', -- Local dev path
  ft = 'markdown', -- Lazy-load only for markdown filetypes

  opts = {
    -- This is where you override the default options.
    callouts = {
      -- You can add your own callouts or override existing ones.
      info = {
        icon = '?',
        highlight = 'DiagnosticInfo',
      },
      quote = {
        icon = '?',
        highlight = 'String',
      },
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
