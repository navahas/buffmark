local M = {}

local bookmarks = {}
local config = {
    toggle_key = nil -- will be set by user in setup()
}

-- Optional setup for configuration
function M.setup(opts)
    config = vim.tbl_extend("force", config, opts or {})

    -- If toggle_key is configured, automatically set the keymap
    if config.toggle_key then
        vim.keymap.set("n", config.toggle_key, M.list, { desc = "Bookmark list" })
    end
end

-- Helper to print messages that auto-clear after duration
local function print_timed(msg, duration)
    duration = duration or 1110 -- default ~1 second
    print(msg)
    vim.defer_fn(function()
        vim.cmd('echon ""')
    end, duration)
end

-- add or replace using a specific filename
local function set_bookmark(slot, filename)
    if filename == "" then
        print_timed("No file name")
        return
    end
    bookmarks[slot] = filename
    print_timed("Bookmark [" .. slot .. "] = " .. vim.fn.fnamemodify(filename, ":~:."))
end

-- Add current buffer as bookmark (append until 4)
function M.add(slot)
    local name = vim.api.nvim_buf_get_name(0)
    if name == "" then
        print_timed("No file name")
        return
    end

    -- if slot is given, this is a replace
    if slot then
        set_bookmark(slot, name)
        return
    end

    -- avoid duplicates
    for _, b in ipairs(bookmarks) do
        if b == name then
            print_timed("Already bookmarked")
            return
        end
    end

    if #bookmarks >= 4 then
        print_timed("Max 4 bookmarks reached — replace one (open list and press r)", 2110)
        return
    end

    table.insert(bookmarks, name)
    print_timed("Bookmarked [" .. #bookmarks .. "]: " .. vim.fn.fnamemodify(name, ":~:."))
end

function M.jump(i)
    -- Prevent jumping from inside the popup
    -- Using buffer-local flag instead of checking buftype == "nofile"
    -- to avoid blocking legitimate jumps from other nofile buffers
    if vim.b.buffmark_popup then
        return
    end
    local name = bookmarks[i]
    if not name then
        print_timed("No bookmark at [" .. i .. "]")
        return
    end
    vim.cmd("edit " .. vim.fn.fnameescape(name))
end

function M.remove(i)
    if not bookmarks[i] then
        print_timed("No bookmark at [" .. i .. "]")
        return
    end
    table.remove(bookmarks, i)
    print_timed("Removed bookmark [" .. i .. "]")
end

function M.clear()
    bookmarks = {}
    print_timed("All bookmarks cleared")
end

-- popup
function M.list()
    -- capture the buffer the user was in BEFORE opening popup
    local source_buf = vim.api.nvim_get_current_buf()

    -- build lines (always 4 slots for consistency)
    local lines = {}
    local has_any = false
    for i = 1, 4 do
        local mark = bookmarks[i]
        if mark then
            has_any = true
            table.insert(lines, string.format("[%d] %s", i, vim.fn.fnamemodify(mark, ":~:.")))
        else
            table.insert(lines, string.format("[%d] — empty", i))
        end
    end
    if not has_any then
        print_timed("No bookmarks")
        return
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].modifiable = false
    vim.b[buf].buffmark_popup = true

    -- Calculate dimensions
    local height = #lines + 1
    -- Ensure width is wide enough for long paths (80% of screen or minimum 60)
    local min_width = 60
    local max_width = math.floor(vim.o.columns * 0.8)
    local content_width = 0
    for _, l in ipairs(lines) do
        if #l > content_width then content_width = #l end
    end
    local width = math.max(min_width, math.min(content_width + 4, max_width))

    -- Dim the footer text
    vim.api.nvim_set_hl(0, "FloatFooter", { fg = "#7A7A7A", bg = "NONE" })

    -- Build footer based on config
    local footer_text = " 1-4: jump • r: replace • dd: delete • q: quit "

    -- Position right above status line (bottom of screen)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        style = "minimal",
        border = "rounded",
        title = " [▮▮▮▯][buff][mark] ",
        title_pos = "right",
        footer = footer_text,
        footer_pos = "center",
        width = width,
        height = height,
        row = vim.o.lines - height - 4, -- Right above status line
        col = 0
        -- col = math.floor((vim.o.columns - width) / 2),  -- Center horizontally
    })

    vim.wo[win].cursorline = true

    -- disable editing keys inside the popup
    local disable_keys = { "d", "i", "a", "I", "A", "o", "O", "c", "s", "S", "R" }
    for _, key in ipairs(disable_keys) do
        vim.keymap.set("n", key, "<Nop>", { buffer = buf, silent = true })
    end

    -- q to close
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })

    -- toggle_key to close if configured
    if config.toggle_key then
        vim.keymap.set("n", config.toggle_key, "<cmd>close<CR>", { buffer = buf, silent = true })
    end

    -- <CR> to jump
    vim.keymap.set("n", "<CR>", function()
        local idx = tonumber(vim.api.nvim_get_current_line():match("%[(%d+)%]"))
        if idx and bookmarks[idx] then
            vim.cmd("close")
            M.jump(idx)
        end
    end, { buffer = buf, silent = true })

    -- Direct jump with number keys (1-4) without navigating
    for i = 1, 4 do
        vim.keymap.set("n", tostring(i), function()
            if bookmarks[i] then
                vim.cmd("close")
                M.jump(i)
            end
        end, { buffer = buf, silent = true })
    end

    -- dd to delete current slot
    vim.keymap.set("n", "dd", function()
        local idx = tonumber(vim.api.nvim_get_current_line():match("%[(%d+)%]"))
        if idx then
            M.remove(idx)
            vim.cmd("close")
            M.list() -- refresh
        end
    end, { buffer = buf, silent = true })

    -- r to REPLACE selected slot with the buffer we had BEFORE the popup
    vim.keymap.set("n", "r", function()
        local idx = tonumber(vim.api.nvim_get_current_line():match("%[(%d+)%]"))
        if not idx then return end

        -- Only allow replacing occupied slots
        if not bookmarks[idx] then
            print_timed("Cannot replace empty slot")
            return
        end

        -- get filename from the buffer we were in before opening the popup
        local src_name = vim.api.nvim_buf_get_name(source_buf)
        if src_name == "" then
            print_timed("Original buffer had no file name")
            return
        end

        -- if this file is already bookmarked, move it instead of duplicating
        local existing
        for i, b in ipairs(bookmarks) do
            if b == src_name then
                existing = i
                break
            end
        end

        if existing then
            -- move existing bookmark to new slot
            if existing == idx then
                print_timed("Already at slot [" .. idx .. "]")
                return
            end
            bookmarks[existing], bookmarks[idx] = bookmarks[idx], bookmarks[existing]
            print_timed("Moved bookmark to slot [" .. idx .. "]")
        else
            -- normal replace
            bookmarks[idx] = src_name
            print_timed("Replaced slot [" .. idx .. "]")
        end

        vim.cmd("close")
        M.list() -- refresh view
    end, { buffer = buf, silent = true })
end

return M
