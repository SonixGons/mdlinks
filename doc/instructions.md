# Instructions

{
  dir = vim.fn.expand(vim.env.REPOS_DIR .. "/mdlinks"),
  ft = "markdown",
  config = function()
    require("mdlinks.config").setup({
      keymap = "j",                    -- follow under cursor
      footnote_backref_key = "K",      -- jump back from [^id]: definition
      open_cmd = nil,                  -- auto: xdg-open/open
      open_url_cmd = nil,              -- e.g. {"firefox","--new-tab"} or {"open","-a","Safari","--args","-new-tab"}
      anchor_levels = {1,2,3,4,5,6},   -- ATX levels to match
    })
    require("mdlinks.commands").register_user_commands()
  end,
},
