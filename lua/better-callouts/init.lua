-- lua/better-callouts/init.lua

local M = {}

-- Default configuration, which will be merged with the user's config.
M.default_config = {
	-- 1. A map/table of callout names to icons and highlight data.
	callouts = {
		note = { icon = "?", highlight = "DiagnosticInfo" },
		tip = { icon = "?", highlight = "DiagnosticOk" },
		important = { icon = "?", highlight = "DiagnosticHint" },
		warning = { icon = "?", highlight = "DiagnosticWarn" },
		danger = { icon = "?", highlight = "DiagnosticError" },
		-- Example from the request
		bible = { icon = "", highlight = "@label" },
		pdf = { icon = "󰸱", highlight = "@comment.warning" },
	},
	-- 2. A function to be called if the map doesn't match.
	-- It receives the callout name and must return a table with 'icon' and 'highlight'.
	fallback = function(name)
		return {
			icon = "CL",
			highlight = "Comment",
		}
	end,
}

-- The main setup function called by the user.
function M.setup(user_config)
	-- Merge user config with defaults
	M.config = vim.tbl_deep_extend("force", M.default_config, user_config or {})

	-- Import the renderer module
	local renderer = require("better-callouts.renderer")
	-- Initialize the renderer with the final config
	renderer.setup(M.config)

	-- Create an augroup for our autocommands to keep it clean.
	local augroup = vim.api.nvim_create_augroup("BetterCallouts", { clear = true })

	-- Define the autocommands to trigger the renderer.
	-- This ensures it runs on BufEnter and on any text change.
	vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
		group = augroup,
		pattern = "*.md",
		callback = function(args)
			-- Set conceal options for the buffer. This is crucial for the 'conceal' feature to work.
			vim.opt_local.conceallevel = 2
			-- vim.opt_local.concealcursor = "nc"

			-- Trigger the rendering for the current buffer.
			renderer.render_buffer(args.buf)
		end,
	})
end

return M
