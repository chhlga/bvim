-- TidalHelp process management
-- Handles starting/stopping tidalhelp and communication via stdin/stderr
-- Supports terminal (neovim split) or tmux targets

local M = {}

M.job_id = nil
M.term_buf = nil
M.term_win = nil
M.tmux_pane = nil
M.socket_path = '/tmp/tidalhelp.sock'
M.pending_completions = {}
M.config = {
  tidalhelp_path = 'tidalhelp',
  osc_addr = '127.0.0.1:57121',
  socket_path = '/tmp/tidalhelp.sock',
  target = 'terminal', -- 'terminal' (neovim), 'tmux' (split in current session), or 'tmux_session' (external session)
  split_size = 40,     -- width percentage for terminal split
  tmux_session_name = 'tidalhelp',  -- name for external tmux session
  tmux_window_name = 'control',     -- window name in external session
}

---Start tidalhelp process
function M.start()
  if M.job_id then
    vim.notify('TidalHelp already running', vim.log.levels.WARN)
    return
  end

  if M.config.target == 'tmux' then
    M._start_tmux()
  elseif M.config.target == 'tmux_session' then
    M._start_tmux_session()
  else
    M._start_terminal()
  end
end

---Start tidalhelp in neovim terminal (right split)
function M._start_terminal()
  -- Save current window
  local orig_win = vim.api.nvim_get_current_win()

  -- Calculate split width
  local width = math.floor(vim.o.columns * M.config.split_size / 100)

  -- Create vertical split on the right
  vim.cmd('botright ' .. width .. 'vsplit')
  M.term_win = vim.api.nvim_get_current_win()

  -- Create new buffer and set it in the split window
  M.term_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(M.term_win, M.term_buf)

  -- Build command
  local cmd = string.format('%s --headless --osc-addr %s --socket %s',
    M.config.tidalhelp_path,
    M.config.osc_addr,
    M.config.socket_path
  )

  -- Start terminal in the new buffer
  -- Note: termopen replaces current buffer, so we must be in term_win
  M.job_id = vim.fn.termopen(cmd, {
    on_exit = function(_, code, _)
      M.job_id = nil
      M.term_buf = nil
      M.term_win = nil
    end,
  })

  -- After termopen, current buffer is the terminal buffer
  M.term_buf = vim.api.nvim_get_current_buf()

  -- Set buffer/window options
  vim.bo[M.term_buf].buflisted = false
  vim.wo[M.term_win].number = false
  vim.wo[M.term_win].relativenumber = false
  vim.wo[M.term_win].signcolumn = 'no'
  vim.wo[M.term_win].winfixwidth = true

  -- Go back to original window
  vim.api.nvim_set_current_win(orig_win)

  if M.job_id <= 0 then
    M.job_id = nil
    if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
      vim.api.nvim_win_close(M.term_win, true)
    end
    M.term_win = nil
    M.term_buf = nil
  end
end

---Start tidalhelp in tmux pane (right split)
function M._start_tmux()
  -- Check if we're in tmux
  if not os.getenv('TMUX') then
    vim.notify('Not running inside tmux. Use target = "terminal" instead.', vim.log.levels.ERROR)
    return
  end

  -- Save current pane ID before split
  local original_pane = vim.fn.system('tmux display-message -p "#{pane_id}"'):gsub('%s+', '')

  -- Calculate pane width percentage
  local pane_size = M.config.split_size

  -- Create tmux split running bash (we'll start tidalhelp via send-keys)
  local cmd = string.format('tmux split-window -h -l %d%%', pane_size)
  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify('Failed to create tmux pane: ' .. result, vim.log.levels.ERROR)
    return
  end

  -- Get the new pane ID (it's now active)
  M.tmux_pane = vim.fn.system('tmux display-message -p "#{pane_id}"'):gsub('%s+', '')

  -- Start tidalhelp in the new pane via send-keys
  local tidalhelp_cmd = string.format('%s --headless --osc-addr %s --socket %s',
    M.config.tidalhelp_path,
    M.config.osc_addr,
    M.config.socket_path
  )
  vim.fn.system(string.format('tmux send-keys -t %s %q Enter', M.tmux_pane, tidalhelp_cmd))

  -- Focus back to the original pane (neovim)
  vim.fn.system('tmux select-pane -t ' .. original_pane)

  M.job_id = -1 -- Marker that we're using tmux

  vim.notify('TidalHelp started (tmux)', vim.log.levels.INFO)
end

---Show TidalHelp panel by switching to tmux session
function M.show_panel()
  if M.config.target ~= 'tmux_session' then
    vim.notify('show_panel only works with target = "tmux_session"', vim.log.levels.WARN)
    return
  end
  
  local session_name = M.config.tmux_session_name or 'tidalhelp'
  
  -- Check if we're in tmux
  if not os.getenv('TMUX') then
    vim.notify('Not running inside tmux', vim.log.levels.ERROR)
    return
  end
  
  -- Switch to the session
  local cmd = string.format('tmux switch-client -t %s', session_name)
  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify('Failed to switch to session: ' .. result, vim.log.levels.ERROR)
  end
end

---Attach TidalHelp panel in a split pane
function M.attach_panel()
  if M.config.target ~= 'tmux_session' then
    vim.notify('attach_panel only works with target = "tmux_session"', vim.log.levels.WARN)
    return
  end
  
  local session_name = M.config.tmux_session_name or 'tidalhelp'
  local window_name = M.config.tmux_window_name or 'control'
  
  -- Check if we're in tmux
  if not os.getenv('TMUX') then
    vim.notify('Not running inside tmux', vim.log.levels.ERROR)
    return
  end
  
  -- Calculate pane width percentage
  local pane_size = M.config.split_size
  
  -- Create split showing the external session
  local cmd = string.format('tmux split-window -h -l %d%% "tmux attach-session -t %s:%s"',
    pane_size,
    session_name,
    window_name
  )
  
  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify('Failed to attach panel: ' .. result, vim.log.levels.ERROR)
  end
end

---Start tidalhelp in external tmux session
function M._start_tmux_session()
  local session_name = M.config.tmux_session_name or 'tidalhelp'
  local window_name = M.config.tmux_window_name or 'control'
  
  -- Check if session exists
  local check_cmd = string.format('tmux has-session -t %s 2>/dev/null', session_name)
  local session_exists = vim.fn.system(check_cmd)
  
  if vim.v.shell_error ~= 0 then
    -- Session doesn't exist, create it
    local tidalhelp_cmd = string.format('%s --headless --osc-addr %s --socket %s',
      M.config.tidalhelp_path,
      M.config.osc_addr,
      M.config.socket_path
    )
    
    local cmd = string.format(
      'tmux new-session -d -s %s -n %s %q',
      session_name,
      window_name,
      tidalhelp_cmd
    )
    
    local result = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      vim.notify('Failed to create tmux session: ' .. result, vim.log.levels.ERROR)
      return
    end
    
    vim.notify(string.format('TidalHelp started (tmux session: %s)', session_name), vim.log.levels.INFO)
  else
    vim.notify(string.format('TidalHelp session already exists: %s', session_name), vim.log.levels.INFO)
  end
  
  M.job_id = -2 -- Marker for external tmux session
end

---Stop tidalhelp process
function M.stop()
  if M.config.target == 'tmux_session' and M.job_id == -2 then
    -- Kill the external tmux session
    local session_name = M.config.tmux_session_name or 'tidalhelp'
    vim.fn.system(string.format('tmux kill-session -t %s 2>/dev/null', session_name))
    M.job_id = nil
    vim.notify('TidalHelp session stopped', vim.log.levels.INFO)
  elseif M.config.target == 'tmux' and M.tmux_pane then
    -- Send quit then kill tmux pane
    vim.fn.system(string.format('tmux send-keys -t %s quit Enter', M.tmux_pane))
    vim.defer_fn(function()
      vim.fn.system('tmux kill-pane -t ' .. M.tmux_pane)
      M.tmux_pane = nil
      M.job_id = nil
    end, 200)
    vim.notify('TidalHelp stopped', vim.log.levels.INFO)
  elseif M.job_id and M.job_id > 0 then
    -- Send quit command and close terminal
    vim.fn.chansend(M.job_id, 'quit\n')

    -- Close terminal window if it exists
    if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
      vim.api.nvim_win_close(M.term_win, true)
    end

    M.job_id = nil
    M.term_buf = nil
    M.term_win = nil
    vim.notify('TidalHelp stopped', vim.log.levels.INFO)
  end
end

---Focus the TidalHelp window/pane
function M.focus()
  if M.config.target == 'tmux' and M.tmux_pane then
    vim.fn.system('tmux select-pane -t ' .. M.tmux_pane)
  elseif M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
    vim.api.nvim_set_current_win(M.term_win)
  else
    vim.notify('TidalHelp not running', vim.log.levels.WARN)
  end
end

---Toggle TidalHelp window visibility (terminal mode only)
function M.toggle()
  if M.config.target == 'tmux' then
    vim.notify('Toggle not supported in tmux mode', vim.log.levels.WARN)
    return
  end
  
  if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
    -- Hide window
    vim.api.nvim_win_close(M.term_win, false)
    M.term_win = nil
  elseif M.term_buf and vim.api.nvim_buf_is_valid(M.term_buf) then
    -- Restore window
    local width = math.floor(vim.o.columns * M.config.split_size / 100)
    vim.cmd('botright ' .. width .. 'vsplit')
    M.term_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(M.term_win, M.term_buf)
    vim.wo[M.term_win].number = false
    vim.wo[M.term_win].relativenumber = false
    vim.wo[M.term_win].signcolumn = 'no'
    vim.wo[M.term_win].winfixwidth = true
    vim.cmd('wincmd p')
  else
    -- Not running, start it
    M.start()
  end
end

---Send command to tidalhelp via Unix socket and handle response
---@param cmd string Command to send
---@param callback function|nil Optional callback for response
function M.send(cmd, callback)
  local socket_path = M.config.socket_path
  local uv = vim.loop

  local pipe = uv.new_pipe(false)
  pipe:connect(socket_path, function(err)
    if err then
      if callback then
        vim.schedule(function()
          callback(nil, err)
        end)
      end
      return
    end

    -- Send command
    pipe:write(cmd .. '\n')

    -- Read response
    local response_data = ''
    pipe:read_start(function(read_err, data)
      if read_err then
        pipe:close()
        if callback then
          vim.schedule(function()
            callback(nil, read_err)
          end)
        end
        return
      end

      if data then
        response_data = response_data .. data
        -- Check if we have a complete JSON line
        local newline_pos = response_data:find('\n')
        if newline_pos then
          local json_line = response_data:sub(1, newline_pos - 1)
          pipe:read_stop()
          pipe:close()
          vim.schedule(function()
            M._handle_response(json_line)
            if callback then
              callback(json_line, nil)
            end
          end)
        end
      else
        -- EOF
        pipe:close()
      end
    end)
  end)
end

---Send command without expecting response (fire and forget)
---@param cmd string Command to send
function M.send_async(cmd)
  M.send(cmd, nil)
end

---Request completions asynchronously
---@param prefix string Word prefix
---@param callback function Callback receiving items
function M.complete(prefix, callback)
  if not M.is_running() then
    callback({})
    return
  end

  table.insert(M.pending_completions, callback)
  M.send('complete ' .. prefix)
end

---Request smart completions with full context (line, cursor position, word)
---@param line string The current line of code
---@param col number Cursor column position
---@param word string Word prefix
---@param callback function Callback receiving items
function M.complete_smart(line, col, word, callback)
  if not M.is_running() then
    callback({})
    return
  end

  table.insert(M.pending_completions, callback)
  -- Format: complete line:col:word
  -- Escape colons in the line content
  local escaped_line = line:gsub(':', [[\:]])
  M.send(string.format('complete %s:%d:%s', escaped_line, col, word))
end
---Handle JSON response from stderr
---@param line string JSON line
function M._handle_response(line)
  local ok, response = pcall(vim.json.decode, line)
  if not ok then
    return
  end

  if response.type == 'completions' then
    local callback = table.remove(M.pending_completions, 1)
    if callback then
      callback(response.items or {})
    end
  elseif response.type == 'hint' then
    if response.hint then
      M._show_hint(response.hint)
    end
  elseif response.type == 'error' then
    vim.notify('TidalHelp: ' .. (response.error or 'Unknown error'), vim.log.levels.ERROR)
  elseif response.type == 'analysis' then
  elseif response.type == 'evaluate' then
    if response.result then
      M._show_evaluate(response.expr or '', response.result)
    end
  elseif response.type == 'success' then
  elseif response.type == 'status' then
    M._show_status(response)
  end
end

---Show hint in floating window
---@param hint table Hint data
function M._show_hint(hint)
  local lines = {}
  
  if hint.name then
    table.insert(lines, '# ' .. hint.name)
    table.insert(lines, '')
  end
  if hint.signature then
    table.insert(lines, '```haskell')
    table.insert(lines, hint.signature)
    table.insert(lines, '```')
    table.insert(lines, '')
  end
  if hint.summary then
    -- Wrap summary text
    for _, l in ipairs(vim.split(hint.summary, '\n')) do
      table.insert(lines, l)
    end
  end
  if hint.examples and #hint.examples > 0 then
    table.insert(lines, '')
    table.insert(lines, '## Examples')
    table.insert(lines, '')
    for _, ex in ipairs(hint.examples) do
      table.insert(lines, '```haskell')
      for _, l in ipairs(vim.split(ex, '\n')) do
        table.insert(lines, l)
      end
      table.insert(lines, '```')
    end
  end

  vim.lsp.util.open_floating_preview(lines, 'markdown', {
    border = 'rounded',
    max_width = 80,
    max_height = 25,
  })
end

---Show status in floating window
---@param status table Status data
function M._show_status(status)
  local lines = {
    '# TidalHelp Status',
    '',
    string.format('**CPS:** %.4f', status.cps or 0),
    '',
  }
  
  if status.patterns and #status.patterns > 0 then
    table.insert(lines, '## Active Patterns')
    table.insert(lines, '')
    for _, p in ipairs(status.patterns) do
      local event_info = ''
      if p.currentEvent then
        event_info = string.format(' → %s @ %.2f', p.currentEvent.sound, p.currentEvent.cycle)
      end
      table.insert(lines, string.format('- **d%d**%s', p.id, event_info))
    end
  else
    table.insert(lines, '_No active patterns_')
  end

  vim.lsp.util.open_floating_preview(lines, 'markdown', {
    border = 'rounded',
    max_width = 60,
    max_height = 20,
  })
end

local UNICODE_FRACS = {
  ['½'] = 0.5, ['⅓'] = 1/3, ['⅔'] = 2/3,
  ['¼'] = 0.25, ['¾'] = 0.75,
  ['⅕'] = 0.2,  ['⅖'] = 0.4,  ['⅗'] = 0.6,  ['⅘'] = 0.8,
  ['⅙'] = 1/6,  ['⅚'] = 5/6,
  ['⅛'] = 0.125,['⅜'] = 0.375,['⅝'] = 0.625,['⅞'] = 0.875,
}

local function parse_frac(s)
  if not s or s == '' then return nil end
  local f = UNICODE_FRACS[s]
  if f then return f end
  local n, d = s:match('^(%d+)/(%d+)$')
  if n then return tonumber(n) / tonumber(d) end
  return tonumber(s)
end

local function arc_bar(t0, t1, width)
  local lo = math.floor(t0 * width + 0.5)
  local hi = math.floor(t1 * width + 0.5)
  local bar = {}
  for i = 1, width do
    bar[i] = (i > lo and i <= hi) and '█' or '·'
  end
  return table.concat(bar)
end

local function format_arc_lines(raw_lines)
  local events = {}
  local max_val = 0
  for _, l in ipairs(raw_lines) do
    local s, e, val = l:match('^%((.-)%>(.-)%)|(.*)')
    if s then
      local t0 = parse_frac(vim.trim(s))
      local t1 = parse_frac(vim.trim(e))
      local v  = vim.trim(val):gsub('^"(.*)"$', '%1')
      if t0 and t1 then
        table.insert(events, { t0 = t0, t1 = t1, val = v })
        if #v > max_val then max_val = #v end
      end
    end
  end

  if #events == 0 then return raw_lines end

  local BAR = 16
  local out = {}
  for _, ev in ipairs(events) do
    local pad = string.rep(' ', max_val - #ev.val)
    local bar = arc_bar(ev.t0, ev.t1, BAR)
    table.insert(out, string.format('%s%s  %s', ev.val, pad, bar))
  end
  return out
end

function M._show_evaluate(expr, result_lines)
  local display = format_arc_lines(result_lines)

  local lines = {}
  if expr and expr ~= '' then
    table.insert(lines, expr)
    table.insert(lines, string.rep('─', math.min(#expr + 2, 60)))
  end
  for _, l in ipairs(display) do
    table.insert(lines, l)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'

  local width = 0
  for _, l in ipairs(lines) do
    if #l > width then width = #l end
  end
  width = math.max(width + 2, 30)

  local win_h = math.min(#lines + 2, 20)
  local win_w = math.min(width, 80)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local screen_row = vim.fn.screenpos(0, row, 1).row

  vim.api.nvim_open_win(buf, false, {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = win_w,
    height = win_h,
    style = 'minimal',
    border = 'rounded',
    focusable = false,
  })

  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close<cr>', { noremap = true, silent = true })

  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end, 8000)
end

---Check if tidalhelp is running
---@return boolean
function M.is_running()
  -- Check if we have a job running
  if M.config.target == 'tmux_session' then
    if M.job_id == -2 then return true end
  elseif M.config.target == 'tmux' then
    if M.tmux_pane ~= nil then return true end
  else
    if M.job_id ~= nil and M.job_id > 0 then return true end
  end
  
  -- Fallback: check if socket exists (tidalhelp might be running externally)
  local socket_path = M.config.socket_path
  if socket_path then
    local stat = vim.loop.fs_stat(socket_path)
    if stat and stat.type == 'socket' then
      return true
    end
  end
  
  return false
end

return M
