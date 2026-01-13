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

-- -- Renders all callouts in the given buffer.
-- function M.render_buffer(bufnr)
-- 	-- Clear all previous extmarks from our namespace before re-rendering.
-- 	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
--
-- 	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
-- 	local i = 0
-- 	local mode = vim.api.nvim_get_mode().mode
-- 	local is_visual_mode = mode == "v" or mode == "V" or mode == "CTRL-V"
--
-- 	while i < #lines do
-- 		local line = lines[i + 1] -- Lua lists are 1-based
--
-- 		-- Regex to match a callout title line: `> [!NAME] ...`
-- 		-- Captures: 1. The full prefix (e.g., `> [!note]`), 2. The name (e.g., `note`), 3. The title text.
-- 		local prefix, name, title = string.match(line, "^(> %[!([^%]]+)%])(%s*.*)$")
--
-- 		if name then
-- 			-- We found a callout block. Now, find its extent.
-- 			name = string.lower(name)
-- 			local def = config.callouts[name] or config.callouts[config.aliases[name]] or config.fallback(name)
-- 			local block_end_idx = i + 1
--
-- 			-- Find the end of the block (consecutive lines starting with `> `)
-- 			for j = i + 2, #lines do
-- 				if not string.match(lines[j], "^> ") then
-- 					break
-- 				end
-- 				block_end_idx = j
-- 			end
--
-- 			-- Render the entire block from start to end.
-- 			for k = i, block_end_idx - 1 do
-- 				local current_line = lines[k + 1]
-- 				-- Cursor line
-- 				if k == vim.api.nvim_win_get_cursor(0)[1] - 1 then
-- 					-- do nothing
--
-- 					-- Cursor visual selection
-- 					-- BUG: This is broken
-- 					-- elseif is_visual_mode and (vim.fn.getpos("'<")[2] - 1 < k and k <= vim.fn.getpos("'>")[2]) then
--
-- 					-- Callout title
-- 				elseif k == i then
-- 					-- --- Render Title Line ---
-- 					-- Conceal the `> [!name]` part and overlay with `│ {icon}`
-- 					vim.api.nvim_buf_set_extmark(bufnr, ns_id, k, 0, {
-- 						end_col = #prefix,
-- 						conceal = "",
-- 						virt_text = { { "│ " .. def.icon, def.highlight } },
-- 						virt_text_pos = "inline",
-- 						hl_eol = true, -- highlight to end of line
-- 					})
-- 					-- Highlight the title text itself
-- 					vim.api.nvim_buf_set_extmark(bufnr, ns_id, k, #prefix, {
-- 						-- end_col = -1,
-- 						end_col = #current_line,
-- 						hl_group = def.highlight,
-- 						hl_eol = true,
-- 					})
-- 				-- Callout body
-- 				else
-- 					-- --- Render Body Line ---
-- 					local body_prefix = string.match(current_line, "^(> )")
-- 					if body_prefix then
-- 						local _, depth = current_line:gsub("> ", "")
-- 						-- Conceal the `> ` part and overlay with `│ `
-- 						vim.api.nvim_buf_set_extmark(bufnr, ns_id, k, 0, {
-- 							-- end_col = #body_prefix,
-- 							end_col = depth * 2,
-- 							conceal = "",
-- 							-- virt_text = { { "│ ", def.highlight } },
-- 							virt_text = { { ("│ "):rep(depth), def.highlight } },
-- 							virt_text_pos = "inline",
-- 							hl_eol = true,
-- 						})
-- 						-- Highlight the body text itself
-- 						vim.api.nvim_buf_set_extmark(bufnr, ns_id, k, #body_prefix, {
-- 							-- end_col = #body_prefix + 1,
-- 							-- end_col = -1,
-- 							hl_group = def.highlight,
-- 							hl_eol = true,
-- 						})
-- 					end
-- 				end
-- 			end
--
-- 			-- Skip the lines we just processed
-- 			i = block_end_idx
-- 		else
-- 			i = i + 1
-- 		end
-- 	end
-- end

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
	local current_callout = nil
	local inside_embed = true
	while i < #lines do
		local line = lines[i + 1] -- Lua lists are 1-based

		-- local name, start = string.match(line, "%[!([^%]]+)%]")
		local start_col, end_col = string.find(line, "%[![^%]]+%]")
		if start_col then
			local name = string.sub(line, start_col + 2, end_col - 1)
			local callout = config.callouts[name] or config.callouts[config.aliases[name]] or config.fallback(name)
			current_callout = callout
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

		-- Embeds are broken by a blank line
		if #line == 0 then
			inside_embed = false
		end

		local is_embed = string.match(line, "^> ")

		if is_embed then
			inside_embed = true
			local _, replacement_count = line:gsub("> ", "")
			local depth = replacement_count or 0 -- maybe this is already what happens
			-- local depth = 1
			-- if not Cursor line
			if i ~= vim.api.nvim_win_get_cursor(0)[1] - 1 then
				-- I need a callout stack
				vim.api.nvim_buf_set_extmark(bufnr, ns_id, i, 0, {
					end_col = depth * 2,
					conceal = "",
					virt_text = { { ("│ "):rep(depth), (current_callout or {}).highlight } },
					-- virt_text = { { ("│ "):rep(depth) } },
					virt_text_pos = "inline",
					hl_eol = true,
				})
			end
		-- Embeds are broken by a blank line
		elseif inside_embed then
			-- if not Cursor line
			if i ~= vim.api.nvim_win_get_cursor(0)[1] - 1 then
				-- I need a callout stack
				vim.api.nvim_buf_set_extmark(bufnr, ns_id, i, 0, {
					end_col = 0,
					conceal = "",
					virt_text = { { "│ ", (current_callout or {}).highlight } },
					-- virt_text = { { ("│ "):rep(depth) } },
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
