local M = {}

local ns_id = vim.api.nvim_create_namespace("custom_grid_dashboard")
local dashboard_buf = nil

-- Store dashboard state for restoration
local dashboard_state = {
  win = nil,
  saved_win_options = {},
  saved_guicursor = nil,
}

local logo = {
  [[       █                                                                   ]],
  [[     █▒▒░░██                                                               ]],
  [[    █░▒▒▒▓░▒▒█                                                             ]],
  [[    █░▒▒▒▒░▒▒▒░█                                    ██▒░░░░█               ]],
  [[    █░▒▒▒▒░░░▓▒▒▒█                              ██▒▒▒░░▒▒▒▒██              ]],
  [[    █░▒▒▒▒░░░░░░▒▒░█                         ██▒▒▒▒▒▒░░▒▒▒▒░█              ]],
  [[    █░▒▒▒▒▒░░░░░▓▒▒░░██ ████▒▒▒▒▒▒█████   ▓█▒▒▒▒▒░▒░░░▒▒▒▒▒░█              ]],
  [[    █░░▒▒▒▒▒░░░░░▓▒▓▒▒▒▒▓▒▒▒▒▒▒▒▒▓▒▒▒▓░▒▓█▒▒▒▒▒░▒░░░▒▒▒▒▒▒▒░█              ]],
  [[     █░▒▒▒▒▓▓▓▓░▓▓░░▒▒▒▒▒▒▒▒▓▒▒▓▒▒▒▓▓▒▒▓▒▒▓▓▒░▒▒░░░░░░▒▒▒▒▒██              ]],
  [[     █▒▒░░▒▓▓▓▓▓░▒▒▒▒▒▒▓▒▓▒▓▒░▒▒▒▓▒▓▒▒▒▓▒▒▒▓▒▓░▒▓░▓▒▒▒▒▒▒▒░█               ]],
  [[     █░░░▓▒▓▓▓▒▒▒▒▒▒▒▒▓▓▒▓░▒░░▒░▒▒▓▓▒▒▓▒▓▒░▒░░▓▓▒▒▓▓▒▒▒▓░░██               ]],
  [[     ██░░▒▓▓▓▒▒▒▒▒▒▓▒░▒░░░░░░░▓░▒▒▒▒▒▒▒▒░▒▒▒▒░░▓░▓▓▓▒▒▒░▒▒██               ]],
  [[      █░░▒▒▒▒▒▒▒▒░░▒▒▓░░░░░░░░░░░░░▒▒▒░▒▒▒▒▒▒░▒░▓░▒▓▒▒░░▓░█                ]],
  [[      ██▒▓▒▒▒▒░░▒▓░░░░▒░░░░░░░░░░░░░▒░░░▒▒▒▒▒▒▒▒░░▒▒▒▒░░░██                ]],
  [[     ██▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒░▒░░░░█                 ]],
  [[     █▓▒▒░░░░░░███░█░░░░░░░░░░░░░░░░░▒███░░░░░▒▒▒▒▒▒▓░▒░▒░█                ]],
  [[    █▒▓░░░░░░░███████░░░░░░░░░░░░░░░████░█░░░░░░░░▒▒▒░▒▒▓░▒█               ]],
  [[   ██▓▒░░░░░░░██████░░░░░░░░░░░░░░░████████░░░░░░▒▒▒▒░▒▒▒░░██              ]],
  [[   █░░░░░░▒░░░░████░░░░░░░░░░░░░░░░░███████░░░░░░░░▒░▓░▒▒░░░█              ]],
  [[   █▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████░░░░░░░░░░░░▒░▒░▓░░██             ]],
  [[  ██▒░░░░░▒░░░░░░░░░██░░░░███░░░░██░░░░░░░░░░░░░░░░░░░░░░░░▒░█             ]],
  [[  █▓▒▒░░░░░░░░░░░░░░░██░██░▓██░███░░░░░░░░░░░▒░░░░░░░░░░░░░▒▒░█            ]],
  [[  █▒▒▒░░░░░░░░░░░░░░░░██░░░░░███░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒██          ]],
  [[  █▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒██         ]],
  [[  █▒▒▒▒▒░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░▒▒▒▒▒██        ]],
  [[  █░▒▒▒▒▒▒▒░░░░░░░░░░░░▒░░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░░░▓▒▒▒▒▒█        ]],
  [[  ██▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒██       ]],
  [[   █▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒█       ]],
  [[   ██▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒█       ]],
  [[    ██▒░▒░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░░░▒▒▓▒▓▒▒▓█       ]],
  [[     ██▒░▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▒▒▒██        ]],
  [[       ███▒▒▒▒░░░░░░░░░░░░▒░░░░░░░▒░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▒███         ]],
  [[          ████░▒▒▒▒▒▒▒░▒░░▒░▒░▒▒▒░▒▒▒░░░░░░░▒░░▒░░░░░░░░░░▒████            ]],
  [[                █████████▒░▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░███████████                  ]],
  [[                                                                           ]],
  " ",
}

M.layout = function()
  local mru_files = M.get_mru_files(9)
  local buttons = {
    { key = "n", label = "New File", action = function() vim.cmd("enew") end },
    { key = "f", label = "Find File", action = function() Snacks.picker.files() end },
    { key = "g", label = "Grep Text", action = function() Snacks.picker.grep() end },
    { key = "p", label = "Projects", action = function() M.open_projects() end },
    { key = "s", label = "Restore Session", action = function() require('persistence').load({ last = true }) end },
    { 
      key = "c", 
      label = "Config", 
      action = function() 
        vim.schedule(function()
          vim.cmd("enew")
          vim.cmd("edit " .. vim.fn.stdpath("config") .. "/init.lua")
        end)
      end 
    },
    { key = "q", label = "Quit", action = function() vim.cmd("qa") end },
  }
  
  return {
    { type = "padding", size = 2 },
    {
      type = "text",
      content = logo,
      hl = "Title",
      align = "center",
    },
    { type = "padding", size = 2 },
    {
      type = "columns",
      gap = 8,
      items = {
        {
          type = "group",
          width = 45,
          items = {
            { type = "text", content = "MRU", hl = "Special", align = "left" },
            { type = "padding", size = 1 },
            {
              type = "mru",
              files = mru_files,
              hl = "String",
              format = function(idx, file)
                local ok, devicons = pcall(require, "nvim-web-devicons")
                local icon = " "
                
                if ok then
                  local ext = vim.fn.fnamemodify(file, ":e")
                  local filename = vim.fn.fnamemodify(file, ":t")
                  icon, _ = devicons.get_icon(filename, ext, { default = true })
                  icon = icon and (icon .. " ") or " "
                end
                
                local parts = vim.split(file, "/")
                local short_path = file
                
                if #parts > 2 then
                  short_path = "../" .. parts[#parts - 1] .. "/" .. parts[#parts]
                elseif #parts == 2 then
                  short_path = parts[1] .. "/" .. parts[2]
                else
                  short_path = file
                end
                
                return string.format("[%d] %s%s", idx, icon, short_path)
              end,
            },
          },
        },
        {
          type = "group",
          width = 45,
          items = {
            { type = "text", content = "Actions", hl = "Special", align = "left" },
            { type = "padding", size = 1 },
            {
              type = "buttons",
              items = buttons,
              hl = "Function",
              format = function(key, label)
                return string.format("[%s] %s", key, label)
              end,
            },
          },
        },
      },
    },
    { type = "padding", size = 10 },
    {
      type = "text",
      content = function()
        local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
        local git_branch = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD 2>/dev/null")[1] or "no-git"
        return string.format(" %s  %s ", cwd, git_branch)
      end,
      hl = "Comment",
      align = "center",
    },
  }
end

function M.get_mru_files(limit)
  local oldfiles = vim.v.oldfiles or {}
  local cwd = vim.fn.getcwd()
  local files = {}
  
  for _, file in ipairs(oldfiles) do
    if vim.fn.filereadable(file) == 1 then
      if vim.startswith(file, cwd) then
        local relative = vim.fn.fnamemodify(file, ":.")
        
        if not string.match(relative, "^%.git/") and not string.match(relative, "/%.git/") then
          table.insert(files, relative)
          if #files >= limit then break end
        end
      end
    end
  end
  
  return files
end

local function render_element(element, width, render_context)
  local lines = {}
  local highlights = {}
  local keymaps = {}
  
  if element.type == "padding" then
    for _ = 1, element.size do
      table.insert(lines, "")
    end
    
  elseif element.type == "text" then
    local content = type(element.content) == "function" and element.content() or element.content
    if type(content) == "string" then
      content = { content }
    end
    
    for _, line in ipairs(content) do
      local aligned_line = line
      local line_width = vim.fn.strwidth(line)
      
      if element.align == "center" then
        local padding = math.max(0, math.floor((width - line_width) / 2))
        aligned_line = string.rep(" ", padding) .. line
        if line_width < width then
          aligned_line = aligned_line .. string.rep(" ", width - line_width - padding)
        end
      elseif element.align == "right" then
        local padding = math.max(0, width - line_width)
        aligned_line = string.rep(" ", padding) .. line
      elseif element.align == "left" or not element.align then
        if line_width < width then
          aligned_line = line .. string.rep(" ", width - line_width)
        end
      end
      
      table.insert(lines, aligned_line)
      if element.hl then
        table.insert(highlights, { line = render_context.current_line + #lines - 1, hl = element.hl })
      end
    end
    
  elseif element.type == "columns" then
    local total_width = 0
    for _, item in ipairs(element.items) do
      total_width = total_width + (item.width or 40)
    end
    total_width = total_width + (element.gap or 4) * (#element.items - 1)
    
    local start_col = math.floor((width - total_width) / 2)
    local col_results = {}
    
    for _, item in ipairs(element.items) do
      local col_lines, col_highlights, col_keymaps = render_element(item, item.width or 40, { current_line = render_context.current_line })
      table.insert(col_results, { lines = col_lines, highlights = col_highlights, keymaps = col_keymaps })
    end
    
    local max_rows = 0
    for _, result in ipairs(col_results) do
      max_rows = math.max(max_rows, #result.lines)
    end
    
    for row = 1, max_rows do
      local line_parts = {}
      table.insert(line_parts, string.rep(" ", start_col))
      
      for col_idx, result in ipairs(col_results) do
        local col_line = result.lines[row] or ""
        local col_width = element.items[col_idx].width or 40
        
        if vim.fn.strwidth(col_line) < col_width then
          col_line = col_line .. string.rep(" ", col_width - vim.fn.strwidth(col_line))
        end
        
        table.insert(line_parts, col_line)
        
        if col_idx < #col_results then
          table.insert(line_parts, string.rep(" ", element.gap or 4))
        end
      end
      
      table.insert(lines, table.concat(line_parts))
    end
    
    for col_idx, result in ipairs(col_results) do
      local col_offset = start_col
      for i = 1, col_idx - 1 do
        col_offset = col_offset + (element.items[i].width or 40) + (element.gap or 4)
      end
      
      for _, hl in ipairs(result.highlights) do
        table.insert(highlights, {
          line = render_context.current_line + hl.line,
          col_start = col_offset,
          col_end = col_offset + (element.items[col_idx].width or 40),
          hl = hl.hl
        })
      end
      
      for _, km in ipairs(result.keymaps) do
        table.insert(keymaps, km)
      end
    end
    
  elseif element.type == "group" then
    for _, item in ipairs(element.items) do
      local item_lines, item_highlights, item_keymaps = render_element(item, element.width or width, { current_line = render_context.current_line + #lines })
      
      for _, line in ipairs(item_lines) do
        table.insert(lines, line)
      end
      
      for _, hl in ipairs(item_highlights) do
        table.insert(highlights, hl)
      end
      
      for _, km in ipairs(item_keymaps) do
        table.insert(keymaps, km)
      end
    end
    
  elseif element.type == "mru" then
    for idx, file in ipairs(element.files) do
      local formatted = element.format and element.format(idx, file) or file
      local line_width = vim.fn.strwidth(formatted)
      
      if line_width < width then
        formatted = formatted .. string.rep(" ", width - line_width)
      elseif line_width > width then
        formatted = string.sub(formatted, 1, width - 3) .. "..."
      end
      
      table.insert(lines, formatted)
      
      if element.hl then
        table.insert(highlights, { line = render_context.current_line + #lines - 1, hl = element.hl })
      end
      
      if idx <= 9 then
        table.insert(keymaps, {
          key = tostring(idx),
          action = function()
            local filepath = file
            vim.schedule(function()
              vim.cmd("enew")
              vim.cmd("edit " .. vim.fn.fnameescape(filepath))
            end)
          end
        })
      end
    end
    
  elseif element.type == "buttons" then
    for _, btn in ipairs(element.items) do
      local formatted = element.format and element.format(btn.key, btn.label) or btn.label
      local line_width = vim.fn.strwidth(formatted)
      
      if line_width < width then
        formatted = formatted .. string.rep(" ", width - line_width)
      end
      
      table.insert(lines, formatted)
      
      if element.hl then
        table.insert(highlights, { line = render_context.current_line + #lines - 1, hl = element.hl })
      end
      
      table.insert(keymaps, {
        key = btn.key,
        action = btn.action
      })
    end
  end
  
  return lines, highlights, keymaps
end

function M.draw()
  local buf = vim.api.nvim_create_buf(false, true)
  dashboard_buf = buf
  
  vim.api.nvim_buf_set_option(buf, "filetype", "dashboard")
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "buflisted", false)
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  
  local width = vim.o.columns
  local layout = M.layout()
  
  local all_lines = {}
  local all_highlights = {}
  local all_keymaps = {}
  
  for _, element in ipairs(layout) do
    local lines, highlights, keymaps = render_element(element, width, { current_line = #all_lines })
    
    for _, line in ipairs(lines) do
      table.insert(all_lines, line)
    end
    
    for _, hl in ipairs(highlights) do
      table.insert(all_highlights, hl)
    end
    
    for _, km in ipairs(keymaps) do
      table.insert(all_keymaps, km)
    end
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, all_lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  
  local current_win = vim.api.nvim_get_current_win()
  
  -- Store state at module level for restoration
  dashboard_state.win = current_win
  -- Store defaults from options.lua for restoration
  dashboard_state.saved_win_options = {
    number = true,
    relativenumber = true,
    cursorline = true,
    cursorcolumn = false,
    signcolumn = "auto",
    foldcolumn = "0",
    spell = false,
    list = false,
  }
  dashboard_state.saved_guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50"
  
  vim.api.nvim_win_set_buf(current_win, buf)
  
  vim.api.nvim_win_set_option(current_win, "number", false)
  vim.api.nvim_win_set_option(current_win, "relativenumber", false)
  vim.api.nvim_win_set_option(current_win, "cursorline", false)
  vim.api.nvim_win_set_option(current_win, "cursorcolumn", false)
  vim.api.nvim_win_set_option(current_win, "signcolumn", "no")
  vim.api.nvim_win_set_option(current_win, "foldcolumn", "0")
  vim.api.nvim_win_set_option(current_win, "spell", false)
  vim.api.nvim_win_set_option(current_win, "list", false)
  
  vim.cmd("setlocal nocursorline nocursorcolumn")
  vim.opt_local.guicursor = "a:DashboardCursor"
  vim.cmd("highlight DashboardCursor blend=100")
  
  for _, hl in ipairs(all_highlights) do
    vim.api.nvim_buf_add_highlight(buf, ns_id, hl.hl, hl.line, hl.col_start or 0, hl.col_end or -1)
  end
  
  for _, km in ipairs(all_keymaps) do
    vim.api.nvim_buf_set_keymap(buf, "n", km.key, "", {
      noremap = true,
      silent = true,
      callback = km.action
    })
  end
  
  vim.api.nvim_buf_set_keymap(buf, "n", "r", "", {
    noremap = true,
    silent = true,
    callback = function() M.draw() end
  })
  
  for _, key in ipairs({"i", "a", "I", "A", "o", "O", "j", "k", "<Up>", "<Down>", "<C-d>", "<C-u>", "<C-f>", "<C-b>", "gg", "G"}) do
    vim.api.nvim_buf_set_keymap(buf, "n", key, "", { noremap = true, silent = true })
  end
  
  vim.api.nvim_create_autocmd("VimResized", {
    buffer = buf,
    callback = function()
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_get_current_buf() == buf then
        M.draw()
      end
    end
  })
  
  -- Restore window options when any non-dashboard buffer enters the window
  local restore_autocmd_id
  restore_autocmd_id = vim.api.nvim_create_autocmd("BufWinEnter", {
    callback = function(args)
      -- If a non-dashboard buffer enters the dashboard window, restore settings
      local entering_buf = args.buf
      local win = vim.api.nvim_get_current_win()
      
      if entering_buf ~= buf and win == current_win and vim.api.nvim_win_is_valid(win) then
        for opt, val in pairs(dashboard_state.saved_win_options) do
          pcall(vim.api.nvim_win_set_option, win, opt, val)
        end
        
        -- Restore global guicursor
        vim.opt.guicursor = dashboard_state.saved_guicursor
        
        -- Remove this autocmd after first trigger
        if restore_autocmd_id then
          pcall(vim.api.nvim_del_autocmd, restore_autocmd_id)
        end
      end
    end,
  })
  
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    once = true,
    callback = function()
      -- Ensure restoration happens even if BufWinEnter didn't fire
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(current_win) then
          local current_buf = vim.api.nvim_win_get_buf(current_win)
          if current_buf ~= buf then
            for opt, val in pairs(dashboard_state.saved_win_options) do
              pcall(vim.api.nvim_win_set_option, current_win, opt, val)
            end
          end
        end
        
        -- Always restore guicursor
        vim.opt.guicursor = dashboard_state.saved_guicursor
        
        -- Clean up autocmd if it still exists
        if restore_autocmd_id then
          pcall(vim.api.nvim_del_autocmd, restore_autocmd_id)
        end
      end)
      
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
      dashboard_buf = nil
    end
  })
end

-- Restore window settings after session load
function M.restore_settings()
  -- Restore settings to all windows
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      local ft = vim.bo[buf].filetype
      
      -- Skip dashboard and special filetypes
      if ft ~= "dashboard" then
        -- Restore window options
        for opt, val in pairs(dashboard_state.saved_win_options) do
          pcall(vim.api.nvim_win_set_option, win, opt, val)
        end
        
        -- Force filetype detection and syntax highlighting
        vim.api.nvim_buf_call(buf, function()
          vim.cmd('filetype detect')
          vim.cmd('syntax on')
        end)
      end
    end
  end
  
  -- Always restore guicursor
  if dashboard_state.saved_guicursor then
    vim.opt.guicursor = dashboard_state.saved_guicursor
  end
end

function M.open_projects()
  local ok, project_nvim = pcall(require, "project_nvim")
  if not ok then
    vim.notify("project_nvim not found", vim.log.levels.ERROR)
    return
  end
  
  local projects = project_nvim.get_recent_projects()
  local items = {}
  
  for _, path in ipairs(projects) do
    local name = vim.fn.fnamemodify(path, ":t")
    table.insert(items, {
      text = name,
      file = path,
      preview = { text = path },
    })
  end

  Snacks.picker.pick({
    source = "projects",
    title = "Projects",
    items = items,
    format = function(item)
      return {
        { item.text, "SnacksPickerFile" },
        { "  " },
        { item.file, "SnacksPickerComment" },
      }
    end,
    confirm = function(picker, item)
      if not item then return end
      picker:close()
      vim.cmd("cd " .. item.file)
      vim.schedule(function()
        Snacks.picker.files()
      end)
    end,
  })
end

function M.setup(user_layout)
  if user_layout then
    M.layout = user_layout
  end
  
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      if vim.fn.argc() == 0 and vim.fn.line2byte("$") == -1 then
        M.draw()
      end
    end
  })
  
  vim.api.nvim_create_user_command("Dashboard", function()
    M.draw()
  end, {})
  
  -- Hook into persistence.nvim's post-load event
  vim.api.nvim_create_autocmd("User", {
    pattern = "PersistenceLoadPost",
    callback = function()
      vim.schedule(function()
        M.restore_settings()
      end)
    end,
  })
end

return M
