-- lua/better-callouts/init.lua

local M = {}

-- Default configuration, which will be merged with the user's config.
M.default_config = {
	-- 1. A map/table of callout names to icons and highlight data.
	callouts = {
		-- Obsidian
		note = { icon = "", highlight = "DiagnosticInfo" },
		abstract = { icon = "", highlight = "Conditional", aliases = { "summary", "tldr" } },
		info = { icon = "", highlight = "Conditional" },
		todo = { icon = "", highlight = "@comment.todo" },
		tip = { icon = "", highlight = "DiagnosticOk", aliases = { "hint", "important" } }, --  or 󰈸
		success = { icon = "", highlight = "DiagnosticOk", aliases = { "check", "done" } },
		question = { icon = "", highlight = "DiagnosticOk", aliases = { "help", "faq" } },
		warning = { icon = "", highlight = "DiagnosticWarn", aliases = { "caution", "attention" } },
		failure = { icon = "", highlight = "DiagnosticWarn", aliases = { "fail", "missing" } },
		danger = { icon = "󱐌", highlight = "DiagnosticError", aliases = { "error" } },
		bug = { icon = "", highlight = "DiagnosticError" },
		example = { icon = "", highlight = "@comment.hint" },
		quote = { icon = "", highlight = "@markup", aliases = { "cite" } },

		-- Obsidian PDF++ highlights (it is easier than making an algorithm for now)
		["pdf|yellow"] = { icon = "", highlight = "@comment.warning", aliases = { "pdf" } },
		["pdf|red"] = { icon = "", highlight = "@comment.error" },
		["pdf|note"] = { icon = "", highlight = "@comment.todo" },
		["pdf|important"] = { icon = "", highlight = "@keyword.function" },

		-- Personal
		bible = { icon = "", highlight = "@label" },
		cf = { icon = "", highlight = "@module.builtin" }, -- cross reference

		x = { icon = "", highlight = "@conceal", aliases = { "twitter", "tweet" } },
	},
	-- Default embed color
	embed_color = "@none",
	-- 2. A function to be called if the map doesn't match.
	-- It receives the callout name and must return a table with 'icon' and 'highlight'.
	fallback = function(name)
		-- Let's create a more dynamic fallback
		local first_char = string.sub(name, 1, 1):upper()
		return {
			icon = "[" .. first_char .. "]",
			highlight = "Comment",
		}
	end,
	aliases = {},
}

-- The main setup function called by the user.
function M.setup(user_config)
	-- Merge user config with defaults
	M.config = vim.tbl_deep_extend("force", M.default_config, user_config or {})

	for name, data in pairs(M.config.callouts) do
		if data.aliases then
			for _, alias in ipairs(data.aliases) do
				M.config.aliases[alias] = name
			end
		end
	end

	-- Import the renderer module
	local renderer = require("better-callouts.renderer")
	-- Initialize the renderer with the final config
	renderer.setup(M.config)

	-- Create an augroup for our autocommands to keep it clean.
	local augroup = vim.api.nvim_create_augroup("BetterCallouts", { clear = true })

	-- Define the autocommands to trigger the renderer.
	-- This ensures it runs on BufEnter and on any text change.
	vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI", "CursorMoved", "CursorMovedI" }, {
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
