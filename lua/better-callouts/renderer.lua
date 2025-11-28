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
	local i = 0

	while i < #lines do
		local line = lines[i + 1] -- Lua lists are 1-based

		-- Regex to match a callout title line: `> [!NAME] ...`
		-- Captures: 1. The full prefix (e.g., `> [!note]`), 2. The name (e.g., `note`), 3. The title text.
		local prefix, name, title_text = string.match(line, "^(> %[!([^%]]+)%])(%s*.*)$")

		if name then
			-- We found a callout block. Now, find its extent.
			local def = config.callouts[name] or config.callouts[config.aliases[name]] or config.fallback(name)
			local block_end_idx = i + 1

			-- Find the end of the block (consecutive lines starting with `> `)
			for j = i + 2, #lines do
				if not string.match(lines[j], "^> ") then
					break
				end
				block_end_idx = j
			end

			-- Render the entire block from start to end.
			for k = i, block_end_idx - 1 do
				local current_line = lines[k + 1]
				if k == vim.api.nvim_win_get_cursor(0)[1] - 1 then
					-- do nothing
				elseif k == i then
					-- --- Render Title Line ---
					-- Conceal the `> [!name]` part and overlay with `│ {icon}`
					vim.api.nvim_buf_set_extmark(bufnr, ns_id, k, 0, {
						end_col = #prefix,
						conceal = "",
						virt_text = { { "│ " .. def.icon, def.highlight } },
						virt_text_pos = "inline",
						hl_eol = true, -- highlight to end of line
					})
					-- Highlight the title text itself
					vim.api.nvim_buf_set_extmark(bufnr, ns_id, k, #prefix, {
						-- end_col = -1,
						end_col = #current_line,
						hl_group = def.highlight,
						hl_eol = true,
					})
				else
					-- --- Render Body Line ---
					local body_prefix = string.match(current_line, "^(> )")
					if body_prefix then
						local _, depth = current_line:gsub("> ", "")
						-- Conceal the `> ` part and overlay with `│ `
						vim.api.nvim_buf_set_extmark(bufnr, ns_id, k, 0, {
							-- end_col = #body_prefix,
							end_col = depth * 2,
							conceal = "",
							-- virt_text = { { "│ ", def.highlight } },
							virt_text = { { ("│ "):rep(depth), def.highlight } },
							virt_text_pos = "inline",
							hl_eol = true,
						})
						-- Highlight the body text itself
						vim.api.nvim_buf_set_extmark(bufnr, ns_id, k, #body_prefix, {
							-- end_col = #body_prefix + 1,
							-- end_col = -1,
							hl_group = def.highlight,
							hl_eol = true,
						})
					end
				end
			end

			-- Skip the lines we just processed
			i = block_end_idx
		else
			i = i + 1
		end
	end
end

return M
