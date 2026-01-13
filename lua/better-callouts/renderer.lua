-- lua/better-callouts/renderer.lua

local M = {}

-- Namespace for our extmarks, to avoid conflicts with other plugins.
local ns_id = vim.api.nvim_create_namespace("better_callouts")
-- Store the config passed from init.lua
local config

-- Sets up the renderer with the user configuration.
function M.setup(user_config)
	config = user_config
end

-- Renders all callouts in the given buffer.
function M.render_buffer(bufnr)
	-- Clear all previous extmarks from our namespace before re-rendering.
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	-- TODO: When I use this value, I get errors when modifying the buffer
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1
	local i = 0
	local mode = vim.api.nvim_get_mode().mode
	local is_visual_mode = mode == "v" or mode == "V" or mode == "CTRL-V"

	local callout_stack = {}
	-- Used by Auto-continuing Embeds
	local inside_embed = false
	while i < #lines do
		-- Lua lists are 1-based
		local line = lines[i + 1]

		-- Embeds are broken by a blank line
		if #line == 0 then
			inside_embed = false
			callout_stack = {}
		end

		local is_embed = string.match(line, "^> ")

		if is_embed then
			inside_embed = true
			local _, replacement_count = line:gsub("> ", "")
			local depth = replacement_count or 0 -- maybe this is already what happens

			-- Make stack correspond to current level
			local count = #callout_stack
			if count > depth then
				-- The difference between the depth and the count (minus the current one that has not been added yet) is how many entries to remove
				for _ = depth, count - 1 do
					table.remove(callout_stack) -- pop
				end
			end

			local start_col, end_col = string.find(line, "%[![^%]]+%]")
			if start_col then
				local name = string.sub(line, start_col + 2, end_col - 1)
				local lowercase_name = string.lower(name)
				local callout = config.callouts[lowercase_name]
					or config.callouts[config.aliases[lowercase_name]]
					or config.fallback(name)
				table.insert(callout_stack, callout) -- push
				-- If the cursor is not here
				if i ~= vim.api.nvim_win_get_cursor(0)[1] - 1 then
					-- Render callout icon in place of the callout identifier
					vim.api.nvim_buf_set_extmark(bufnr, ns_id, i, start_col, {
						end_col = end_col,
						conceal = "",
						virt_text = { { callout.icon, callout.highlight } },
						virt_text_pos = "inline",
						hl_eol = true,
					})
					-- Highlight the title text itself
					vim.api.nvim_buf_set_extmark(bufnr, ns_id, i, end_col, {
						end_col = #line,
						hl_group = callout.highlight,
						hl_eol = true,
					})
				end
				inside_embed = true
			end

			-- If the cursor is not here
			if i ~= vim.api.nvim_win_get_cursor(0)[1] - 1 then
				for d = 1, depth do
					local current_callout = callout_stack[d]
					vim.api.nvim_buf_set_extmark(bufnr, ns_id, i, (d - 1) * 2, {
						end_col = d * 2,
						conceal = "",
						virt_text = { { "│ ", (current_callout or {}).highlight or config.embed_color } },
						virt_text_pos = "inline",
						hl_eol = true,
					})
				end
			end

		-- Embeds are broken by a blank line
		elseif inside_embed then
			-- If the cursor is not here
			if i ~= vim.api.nvim_win_get_cursor(0)[1] - 1 then
				vim.api.nvim_buf_set_extmark(bufnr, ns_id, i, 0, {
					end_col = 0,
					conceal = "",
					-- If I am part of an existing callout, use that, or use the default embed color
					-- This only works for top-level callouts
					virt_text = { { "│ ", (callout_stack[1] or {}).highlight or config.embed_color } },
					virt_text_pos = "inline",
					hl_eol = true,
				})
			end
		end

		-- Advance iteration
		i = i + 1
	end
end

return M
