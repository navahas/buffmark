<div align="center">
    <img alt="buffmark" height="140" src="/assets/buffmark.png" />

# buffmark
</div>

### Why [▮▮▮▯][buff][mark]

I like keeping things minimal, using built-ins instead of large plugins. (netrw user spoted here)

Neovim already has bookmarks (global marks) for jumping between files, but they are stored in **shada**, a shared data file on disk.
That means marks are global and persistent across sessions, which is not ideal when you just want quick, temporary pins.

You could use **[Harpoon](https://github.com/ThePrimeagen/harpoon/tree/harpoon2)** which is larger, persistent, and feature-rich. If that suits you, go for it. This script is a few lines of Lua that keep bookmarks only in memory, simple and local, and gone when you quit.

It is not meant to grow or be configurable beyond its four-bookmark limit.<br>
It remains light, simple, and quietly useful.
```
[▮▮▮▯][buff][mark][buff][▮▮▮▯][mark][▮▮▮▯][mark][buff][▮▮▮▯][buff][mark][buff][▮▮▮▯][mark][▮▮▮▯][mark][buff]
```

## Installation

**lazy.nvim**:
```lua
return {
    "navahas/buffmark",
    config = function()
        -- config here --
    end,
}
```

**builtin (nvim 0.12+ nightly)**:
```lua
vim.pack.add({
    { src = "https://github.com/navahas/buffmark" },
})

vim.cmd.packadd('buffmark')

-- config here --
```

Or just copy `lua/buffmark.lua` to your `~/.config/nvim/lua/` directory, adding respective require.

## Configuration

```lua
local buffmark = require('buffmark')

-- Setup with toggle key (automatically creates the keymap)
buffmark.setup({
    toggle_key = "<leader>bl"
})

-- Set your other keymaps
vim.keymap.set("n", "<leader>a", buffmark.add, { desc = "Bookmark add" })
vim.keymap.set("n", "<leader>1", function() buffmark.jump(1) end, { desc = "Bookmark 1" })
vim.keymap.set("n", "<leader>2", function() buffmark.jump(2) end, { desc = "Bookmark 2" })
vim.keymap.set("n", "<leader>3", function() buffmark.jump(3) end, { desc = "Bookmark 3" })
vim.keymap.set("n", "<leader>4", function() buffmark.jump(4) end, { desc = "Bookmark 4" })
vim.keymap.set("n", "<leader>bc", buffmark.clear, { desc = "Bookmark clear" })
```

## Usage

* `buffmark.add()` — add current buffer
* `buffmark.jump(i)` — jump to slot *i* (1–4)
* `buffmark.list()` — toggle popup
* `buffmark.remove(i)` — remove slot *i*
* `buffmark.clear()` — clear all

In the popup: `<CR>` jump · `r` replace · `dd` delete · `q` or toggle key to close

## Contributions

Contributions that simplify or refine the existing logic are welcome. If you want to tweak it much further or extend it, fork or copy it.

If you have a minimal idea that fits the same spirit, open an issue. I would love to hear it and might add it, or encourage you to do so. I am also open to keeping dedicated branches for ideas that some might enjoy but do not fit my use case.

**Ideas not pursued** (but you might want to try):
- **Quickfix integration**
> Add bookmarks to a quickfix list for batch navigation
- **Editable mark list**
> Allow editing the popup buffer like Harpoon does. This is trickier since buffmarks are in-memory, not file-backed. You would need to generate a temp file, let the user edit it, then parse and rebuild the bookmark list (or hook into buffer close to call `buffmark.clear()` and re-add in the new order)

---

That's all folks.
*Stay light. Stay focused.*
