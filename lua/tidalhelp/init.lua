-- TidalHelp Neovim Integration
-- Full TidalCycles integration: sending code, completions, hints, status
-- Replaces tidal.nvim entirely
local M = {}
M._setup_done = false

local process = require('tidalhelp.process')
local cmp_source = require('tidalhelp.cmp')
local analysis = require('tidalhelp.analysis')

M.config = {
  tidalhelp_path = 'tidalhelp',
  osc_addr = '127.0.0.1:57121',
  socket_path = '/tmp/tidalhelp.sock',
  target = 'terminal', -- 'terminal' (neovim split), 'tmux' (split in current session), or 'tmux_session' (external session)
  split_size = 40,     -- width percentage for split
  tmux_session_name = 'tidalhelp',  -- name for external tmux session
  tmux_window_name = 'control',     -- window name in external session
  auto_start = true,
  keymaps = true,
}

---Setup tidalhelp integration
---@param opts table|nil Configuration options
function M.setup(opts)
  if M._setup_done then return end
  M._setup_done = true

  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  vim.api.nvim_set_hl(0, 'TidalPlayer',   { fg = '#ff79c6', bold = true, default = true })
  vim.api.nvim_set_hl(0, 'TidalFunction', { fg = '#8be9fd', default = true })
  vim.api.nvim_set_hl(0, 'TidalOperator', { fg = '#ff5555', bold = true, default = true })
  vim.api.nvim_set_hl(0, 'TidalScale',    { fg = '#50fa7b', default = true })
  vim.api.nvim_set_hl(0, 'TidalSynth',    { fg = '#ffb86c', default = true })
  vim.api.nvim_set_hl(0, 'TidalSample',   { fg = '#f1fa8c', default = true })
  vim.api.nvim_set_hl(0, 'TidalPattern',  { fg = '#bd93f9', default = true })
  vim.api.nvim_set_hl(0, 'TidalNumber',   { fg = '#bd93f9', default = true })
  vim.api.nvim_set_hl(0, 'TidalKeyword',  { fg = '#ff5555', italic = true, default = true })
  vim.api.nvim_set_hl(0, 'TidalCursorHint', { fg = '#6272a4', italic = true, default = true })

  -- Pass config to process module
  process.config = M.config
  -- Create user commands
  vim.api.nvim_create_user_command('TidalStart', process.start, {})
  vim.api.nvim_create_user_command('TidalStop', process.stop, {})
  vim.api.nvim_create_user_command('TidalSend', M.send_line, {})
  vim.api.nvim_create_user_command('TidalHush', M.hush, {})
  vim.api.nvim_create_user_command('TidalHint', M.hint, {})
  vim.api.nvim_create_user_command('TidalStatus', M.status, {})
  vim.api.nvim_create_user_command('TidalToggle', process.toggle, {})
  vim.api.nvim_create_user_command('TidalFocus', process.focus, {})
  vim.api.nvim_create_user_command('TidalShowPanel', process.show_panel, {})
  vim.api.nvim_create_user_command('TidalAttachPanel', process.attach_panel, {})

  -- Set up keymaps for .tidal files
  if M.config.keymaps then
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'tidal',
      callback = function()
        M._setup_keymaps()
        analysis.attach(vim.api.nvim_get_current_buf())
      end,
    })
    if vim.bo.filetype == 'tidal' then
      M._setup_keymaps()
      analysis.attach(vim.api.nvim_get_current_buf())
    end
  end

  -- Auto-start if configured
  if M.config.auto_start then
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'tidal',
      once = true,
      callback = function()
        vim.defer_fn(process.start, 100)
      end,
    })
  end

  -- Stop tidalhelp when vim exits
  -- Stop tidalhelp when vim exits (only for non-external sessions)
  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
      -- Don't kill external tmux session on vim exit
      if M.config.target ~= 'tmux_session' then
        process.stop()
      end
    end,
  })

  -- Register cmp source for blink.compat
  local has_cmp, cmp = pcall(require, 'cmp')
  if has_cmp then
    cmp.register_source('tidalhelp', cmp_source.new())
  end
end

---Set up buffer-local keymaps (matches tidal.nvim style)
function M._setup_keymaps()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Alt+Enter: evaluate line/block (normal and insert mode)
  vim.keymap.set({'n', 'i'}, '<M-CR>', M.send_line, {
    buffer = bufnr,
    desc = 'TidalHelp: Evaluate line/block',
  })

  -- Alt+Enter: evaluate selection (visual mode)
  vim.keymap.set('x', '<M-CR>', M.send_visual, {
    buffer = bufnr,
    desc = 'TidalHelp: Evaluate selection',
  })

  -- Leader+Enter: evaluate block
  vim.keymap.set('n', '<leader><CR>', M.send_line, {
    buffer = bufnr,
    desc = 'TidalHelp: Evaluate block',
  })

  -- Leader+Escape: hush (stop all)
  vim.keymap.set('n', '<leader><Esc>', M.hush, {
    buffer = bufnr,
    desc = 'TidalHelp: Hush (stop all)',
  })

  -- Ctrl+H: hush (alternative)
  vim.keymap.set({'n', 'i'}, '<C-h>', M.hush, {
    buffer = bufnr,
    desc = 'TidalHelp: Hush (stop all)',
  })

  -- K: show hint for word under cursor
  vim.keymap.set('n', 'K', M.hint, {
    buffer = bufnr,
    desc = 'TidalHelp: Show hint',
  })

  -- Silence pattern under cursor (Alt+Backspace)
  vim.keymap.set({'n', 'i'}, '<M-BS>', M.silence_pattern, {
    buffer = bufnr,
    desc = 'TidalHelp: Silence pattern under cursor',
  })

  -- Alt+s: Pick sample/synth
  vim.keymap.set({'n', 'i'}, '<M-s>', M.pick_sound, {
    buffer = bufnr,
    desc = 'TidalHelp: Pick sample/synth',
  })

  -- Alt+c: Pick scale
  vim.keymap.set({'n', 'i'}, '<M-c>', M.pick_scale, {
    buffer = bufnr,
    desc = 'TidalHelp: Pick scale',
  })

  -- Alt+x: Pick chord
  vim.keymap.set({'n', 'i'}, '<M-x>', M.pick_chord, {
    buffer = bufnr,
    desc = 'TidalHelp: Pick chord',
  })

  -- Alt+n: Pick note
  vim.keymap.set({'n', 'i'}, '<M-n>', M.pick_note, {
    buffer = bufnr,
    desc = 'TidalHelp: Pick note',
  })
end

---Send current line or detected block to Tidal
function M.send_line()
  local filepath = vim.fn.expand('%:p')
  local line = vim.fn.line('.')
  process.send(string.format('send %s:%d', filepath, line))
end

---Send visual selection to Tidal
function M.send_visual()
  -- Exit visual mode first to get marks
  vim.cmd('normal! ')
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local filepath = vim.fn.expand('%:p')
  process.send(string.format('send %s:%d-%d', filepath, start_line, end_line))
end

---Send hush command
function M.hush()
  local tmpfile = vim.fn.tempname() .. '.tidal'
  local f = io.open(tmpfile, 'w')
  if f then
    f:write('hush')
    f:close()
    process.send(string.format('send %s:1', tmpfile))
    vim.defer_fn(function()
      os.remove(tmpfile)
    end, 100)
  end
end

---Silence pattern under cursor (d1 silence, d2 silence, etc.)
function M.silence_pattern()
  local line = vim.api.nvim_get_current_line()
  local pattern_id = line:match('^d(%d+)')
  if pattern_id then
    local tmpfile = vim.fn.tempname() .. '.tidal'
    local f = io.open(tmpfile, 'w')
    if f then
      f:write('d' .. pattern_id .. ' silence')
      f:close()
      process.send(string.format('send %s:1', tmpfile))
      vim.defer_fn(function()
        os.remove(tmpfile)
      end, 100)
    end
  end
end

---Show hint for word under cursor
function M.hint()
  local word = vim.fn.expand('<cword>')
  if word and word ~= '' then
    process.send('hint ' .. word)
  end
end

---Show tidalhelp status
function M.status()
  process.send('status')
end

---Request completions (async, used by cmp source)
---@param prefix string Word prefix to complete
---@param callback function Callback receiving completion items
function M.complete(prefix, callback)
  process.complete(prefix, callback)
end

-- Export cmp source for blink.compat
M.cmp_source = cmp_source

---Show picker for samples/synths and insert selection
function M.pick_sound()
  M._show_picker('sound', 'Samples & Synths')
end

---Show picker for scales and insert selection
function M.pick_scale()
  M._show_picker('scale', 'Scales')
end

---Show picker for chords and insert selection
function M.pick_chord()
  M._show_picker('chord', 'Chords')
end

---Show picker for notes and insert selection
function M.pick_note()
  M._show_picker('note', 'Notes')
end

---Generic picker using vim.ui.select
---@param type string Type of completion (sound, scale, chord, note)
---@param title string Picker title
function M._show_picker(type, title)
  if not process.is_running() then
    vim.notify('TidalHelp not running', vim.log.levels.WARN)
    return
  end

  -- Request completions from tidalhelp
  process.send('list ' .. type, function(response)
    if not response then return end
    
    local ok, data = pcall(vim.json.decode, response)
    if not ok or not data.items then return end
    
    local items = data.items
    if #items == 0 then
      vim.notify('No ' .. title .. ' found', vim.log.levels.INFO)
      return
    end
    
    -- Format items for picker
    local choices = {}
    for _, item in ipairs(items) do
      table.insert(choices, {
        label = item.label,
        detail = item.detail or '',
      })
    end
    
    -- Show picker
    vim.ui.select(choices, {
      prompt = title .. ': ',
      format_item = function(item)
        if item.detail and item.detail ~= '' then
          return item.label .. ' (' .. item.detail .. ')'
        end
        return item.label
      end,
    }, function(selected)
      if selected then
        -- Insert at cursor
        local col = vim.fn.col('.')
        local line = vim.api.nvim_get_current_line()
        local before = line:sub(1, col - 1)
        local after = line:sub(col)
        vim.api.nvim_set_current_line(before .. selected.label .. after)
        vim.fn.cursor(vim.fn.line('.'), col + #selected.label)
      end
    end)
  end)
end

return M
