---@module 'mdlinks.keymaps'

(function(ev)
	local ok_cfg, cfg = pcall(require, "mdlinks.config")
	if not ok_cfg then
		return
	end
	local key = cfg.get("keymap")
	local back = cfg.get("footnote_backref_key")

	-- Map follow via the user command to ensure notifications on errors
	if type(key) == "string" and key ~= "" then
		vim.keymap.set("n", key, function()
			vim.cmd("silent! MdlinksFollow")
		end, {
			buffer = ev.buf,
			silent = true,
			nowait = true,
			desc = "mdlinks: follow link/ref/url/footnote (with notifications)",
		})
	end

	if type(back) == "string" and back ~= "" then
		vim.keymap.set("n", back, function()
			vim.cmd("silent! MdlinksFootnoteBack")
		end, {
			buffer = ev.buf,
			silent = true,
			nowait = true,
			desc = "mdlinks: footnote backref (with notifications)",
		})
	end
end)()
