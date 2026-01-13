-- lua/better-callouts/renderer.lua

local M = {}

-- Source - https://stackoverflow.com/a
-- Posted by hookenz, modified by community. See post 'Timeline' for change history
-- Retrieved 2026-01-12, License - CC BY-SA 4.0

function dump(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. "[" .. k .. "] = " .. dump(v) .. ","
		end
		return s .. "} "
	else
		return tostring(o)
	end
end

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
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1
	local i = 0
	local mode = vim.api.nvim_get_mode().mode
	local is_visual_mode = mode == "v" or mode == "V" or mode == "CTRL-V"

	-- TODO: This needs to be a stack for when I have multiple
	local callout_stack = {}
	local inside_embed = false
	while i < #lines do
		local line = lines[i + 1] -- Lua lists are 1-based

		-- Embeds are broken by a blank line
		if #line == 0 then
			inside_embed = false
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

			-- if i == vim.api.nvim_win_get_cursor(0)[1] - 1 then
			-- 	print("Depth: " .. depth .. " Count: " .. count)
			-- 	-- print(dump(callout_stack))
			-- end

			local start_col, end_col = string.find(line, "%[![^%]]+%]")
			if start_col then
				local name = string.sub(line, start_col + 2, end_col - 1)
				local callout = config.callouts[name] or config.callouts[config.aliases[name]] or config.fallback(name)
				table.insert(callout_stack, callout) -- push
				-- if not Cursor line
				if i ~= vim.api.nvim_win_get_cursor(0)[1] - 1 then
					-- --- Render Title Line ---
					-- Conceal the `> [!name]` part and overlay with `│ {icon}`
					vim.api.nvim_buf_set_extmark(bufnr, ns_id, i, start_col, {
						end_col = end_col,
						conceal = "",
						virt_text = { { callout.icon, callout.highlight } },
						virt_text_pos = "inline",
						hl_eol = true, -- highlight to end of line
					})
					-- Highlight the title text itself
					vim.api.nvim_buf_set_extmark(bufnr, ns_id, i, end_col, {
						-- end_col = -1,
						end_col = #line,
						hl_group = callout.highlight,
						hl_eol = true,
					})
				end
				inside_embed = true
			end

			if i ~= vim.api.nvim_win_get_cursor(0)[1] - 1 then
				for d = 1, depth do
					local current_callout = callout_stack[d]
					vim.api.nvim_buf_set_extmark(bufnr, ns_id, i, (d - 1) * 2, {
						end_col = d * 2,
						conceal = "",
						-- virt_text = { { ("│ "):rep(depth), (current_callout or {}).highlight } },
						virt_text = { { "│ ", (current_callout or {}).highlight or config.embed_color } },
						-- virt_text = { { ("│ "):rep(depth) } },
						virt_text_pos = "inline",
						hl_eol = true,
					})
				end
			end

		-- Embeds are broken by a blank line
		elseif inside_embed then
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
