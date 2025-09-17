# mdlinks.nvim
```sh
                      _|  _|  _|            _|
_|_|_|  _|_|      _|_|_|  _|      _|_|_|    _|  _|      _|_|_|
_|    _|    _|  _|    _|  _|  _|  _|    _|  _|_|      _|_|
_|    _|    _|  _|    _|  _|  _|  _|    _|  _|  _|        _|_|
_|    _|    _|    _|_|_|  _|  _|  _|    _|  _|    _|  _|_|_|
```

![version](https://img.shields.io/badge/version-0.9-blue.svg)
![State](https://img.shields.io/badge/status-beta-orange.svg)
![Lazy.nvim compatible](https://img.shields.io/badge/lazy.nvim-supported-success)
![Neovim](https://img.shields.io/badge/Neovim-0.9+-success.svg)
![Lua](https://img.shields.io/badge/language-Lua-yellow.svg)

A tiny, robust Neovim plugin to **follow Markdown entities** under (or near) your cursor:

* Standard links `[label](http://…)`
* Local files (PDFs, images, any path)
* Headings / anchors (`[go](#my-heading)`, `[go](## My Heading)`)
* Line-fallback: if no link is *exactly* under the cursor, it picks the **nearest** link on that line.

---

* [Features](#features)
* [Installation (with Lazy.nvim)](#installation-with-lazynvim)
* [Dependencies](#dependencies)
* [Configuration](#configuration)

  * [Config reference](#config-reference)
  * [Windows/WSL notes](#windowswsl-notes)
* [Usage](#usage)

  * [Commands](#commands)
  * [Keymaps](#keymaps)
  * [Behavior details](#behavior-details)
* [Development](#development)
* [License](#license)
* [Feedback](#feedback)

---

## Features

* **URL, file, image, heading** — one command handles them all.
* **GitHub-style anchors**
  Follows `[go](#my-heading)` and `## My Heading` (with duplicate-aware slugs: `# foo`, `# foo` → `#foo`, `#foo-1`).
* **Nearest-on-line fallback**
  If your cursor isn’t *inside* a link, `mdlinks` selects the closest link on the **current line**.
* **Cross-platform openers**
  Uses platform defaults out-of-the-box:

  * Windows: `cmd.exe /c start "" <target>`
  * macOS: `open <target>`
  * Linux: `xdg-open <target>`
  * WSL: `wslview` (if available) or `powershell.exe Start-Process`
* **Safe argv execution** (no shell injection): openers run via `jobstart({argv...}, {detach=true})`.
* **Clean layering**
  Core returns `(true)` / `(false, "reason")`; only the UI layer shows notifications.

> Bonus: Images/PDFs open in your OS viewer. Text-like files (`*.md, *.txt, *.lua, …`) open in the current window via `:edit`.

---

## Installation (with Lazy.nvim)

```lua
{
  "StefanBartl/mdlinks.nvim",
  lazy = false, -- recommended so the command is always available
  config = function()
    require("mdlinks").setup({
      -- all fields are optional; see “Configuration” below
      -- keymap = "gx",
      -- debug = true,
      -- open_cmd = { "xdg-open" },
      -- open_url_cmd = { "xdg-open" },
      -- anchor_levels = { 1,2,3,4,5,6 },
    })
  end,
}
```

> You can also lazy-load by `cmd = { "MdlinksFollow", "MdlinksFootnoteBack" }`, or by a key mapping.

---

## Dependencies

No hard runtime dependencies besides Neovim (uses core Lua API + `jobstart`).
If you’re on **WSL**, `wslview` is recommended for the smoothest UX.

---

## Configuration

Call once in your init:

```lua
require("mdlinks").setup({
  keymap = "gx",             -- normal-mode mapping to follow under/near cursor
  footnote_backref_key = nil, -- optional mapping for footnote backrefs (if you add that feature)
  open_cmd = nil,            -- nil → platform default (argv)
  open_url_cmd = nil,        -- nil → platform default (argv)
  anchor_levels = {1,2,3,4,5,6},
  debug = false,             -- if true: center screen (zz) after successful jumps
})
```

### Config reference

| Option                 | Type                         | Default            | Description                                                                                                    |
| ---------------------- | ---------------------------- | ------------------ | -------------------------------------------------------------------------------------------------------------- |
| `keymap`               | `string \| nil`              | `"gx"`             | Normal-mode mapping that triggers follow. If `nil`, no mapping is created.                                     |
| `footnote_backref_key` | `string \| nil`              | `nil`              | Optional mapping to “jump back” from a footnote definition to first reference (if you implement that command). |
| `open_cmd`             | `string\[] \| string \| nil` | *platform default* | Program to open **local files** (argv form preferred). `nil` → platform default.                               |
| `open_url_cmd`         | `string\[] \| string \| nil` | *platform default* | Program to open **URLs** (argv form preferred). `nil` → platform default.                                      |
| `anchor_levels`        | `integer[]`                  | `{1,2,3,4,5,6}`    | Which `#` levels to consider when resolving anchors.                                                           |
| `debug`                | `boolean \| nil`             | `false`            | Center screen (`zz`) after successful jumps; helpful UX.                                                       |

> **Security & robustness:** Prefer **argv lists** (e.g. `{ "open" }`, `{ "xdg-open" }`) over shell strings.

### Windows/WSL notes

* **Windows (non-WSL)** uses `{"cmd.exe","/c","start",""}` to respect file associations and handle spaces.
* **WSL** prefers `{"wslview"}`. If not available, falls back to `{"powershell.exe","-NoProfile","-Command","Start-Process"}`.

These defaults are injected **before** normalization so your final config always contains **argv**.

---

## Usage

### Commands

| Command                | Description                                                                |
| ---------------------- | -------------------------------------------------------------------------- |
| `:MdlinksFollow`       | Follow the Markdown entity under the cursor; if none, use nearest on line. |
| `:MdlinksFootnoteBack` | (Optional) Jump from a footnote definition back to first reference.        |

### Keymaps

If you set `keymap = "gx"` (default), you can simply hover near any link and hit `gx`.
If you prefer manual mapping:

```lua
vim.keymap.set("n", "gx", "<cmd>MdlinksFollow<CR>", { desc = "mdlinks: follow link under/near cursor" })
```

### Behavior details

* **Heading links**
  Works with both styles:

  * Anchors: `[go](#my-heading)` → searches across `anchor_levels` with duplicate-aware GitHub-style slugs.
  * Level+Text: `[go](## My Heading)` → prefers level 2; tries text match (case/space-insensitive), then slug fallback.
    You can also pass a sluggy form like `[go](## my-heading)` or `[go](##-my-heading)`.
* **Nearest on line**
  If your cursor isn’t within a link range, `mdlinks` selects the closest link from that line (left/right).
* **Openers**

  * **Text-like** files (`*.md, *.txt, *.lua, *.json, *.toml, *.ya?ml`) open directly in Neovim via `:edit`.
  * Other files (PDFs, images, etc.) and URLs open via your system opener (argv).
* **Return values & notifications**
  Core returns `(true)` on success or `(false, "message")` on handled failure; only the user-command layer calls `vim.notify`. With `debug = true`, successful jumps run `zz` to center the view.

---

## Health check

Run `:checkhealth mdlinks` to diagnose common setup issues:
- Neovim version & OS/WSL detection
- Config sanity (keymaps, anchor levels, debug)
- Openers availability (`open_cmd`, `open_url_cmd`)
- Parser self-test (recognizes URL, heading, image, file on a sample line)

--

## License

[MIT LICENSE](./LICENSE)

---

## Feedback

Bugs, ideas, or questions? Open an issue or discussion on GitHub.
If the plugin helps you, a ⭐ makes my day!

---
