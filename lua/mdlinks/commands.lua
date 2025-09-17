---@module 'mdlinks.commands'

---@class MdlinksCommands
local M = {}

function M.register_user_commands()
  vim.api.nvim_create_user_command("MdlinksFollow", function()
    local ok_nav, nav = pcall(require, "mdlinks.core.nav")
    if not ok_nav then
      vim.notify("[mdlinks] internal error: nav not available", vim.log.levels.ERROR)
      return
    end
    local ok, err = nav.follow_under_cursor()
    if not ok then
      vim.notify(("[mdlinks] %s"):format(err or "no markdown entity under cursor"), vim.log.levels.WARN)
      return
    end
    -- Optional UI nicety: center after successful jumps/opens
    local cfg_ok, cfg = pcall(require, "mdlinks.core.config")
    if cfg_ok and cfg.get and cfg.get().debug then
      vim.cmd("normal! zz")
    end
  end, { desc = "Follow markdown entity (link/ref/url/footnote) under cursor" })

  vim.api.nvim_create_user_command("MdlinksFootnoteBack", function()
    local ok_nav, nav = pcall(require, "mdlinks.core.nav")
    if not ok_nav then
      vim.notify("[mdlinks] internal error: nav not available", vim.log.levels.ERROR)
      return
    end
    local ok, err = nav.jump_footnote_backref()
    if not ok then
      vim.notify("[mdlinks] " .. tostring(err or "no footnote definition here"), vim.log.levels.WARN)
    end
  end, { desc = "Jump from footnote definition back to first reference" })
end

return M
