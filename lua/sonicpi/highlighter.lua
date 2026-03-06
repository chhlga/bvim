-- Line highlighter for SonicPi logs
-- Parses error messages and highlights corresponding lines in source buffer

local M = {
  _namespace = vim.api.nvim_create_namespace('sonicpi_line_highlight'),
  _live_loop_map = {},  -- Maps live_loop name -> {bufnr, start_line}
  _last_highlight = nil, -- Track last highlight for cleanup
  _active_highlights = {},  -- Track all active execution highlights: {bufnr, line}
}

-- Parse error messages for line numbers and live_loop context
-- Sonic Pi error format:
--   data[2]: "[eval] - Thread death +--> :live_loop_NAME\n error message..."
--   data[3]: "eval:LINE:in 'block (3 levels)...'" (stack trace with line numbers)
local function parse_error_message(msg, stack_trace)
  if not msg or type(msg) ~= 'string' then
    return nil
  end
  
  -- Debug: log what we're parsing
  vim.notify("[Highlighter] Parsing message: " .. msg:sub(1, 100), vim.log.levels.DEBUG)
  if stack_trace then
    vim.notify("[Highlighter] Parsing stack: " .. stack_trace:sub(1, 100), vim.log.levels.DEBUG)
  end
  
  -- Pattern 1: Extract from stack trace "eval:LINE:in"
  local line_num = nil
  if stack_trace then
    line_num = stack_trace:match('eval:(%d+):in')
  end
  
  -- Pattern 2: "line X" where X is relative to live_loop (fallback)
  if not line_num then
    line_num = msg:match('line%s+(%d+)')
  end
  
  -- Pattern 3: "[buffer X, line Y]" format (fallback)
  if not line_num then
    line_num = msg:match('%[.-line%s+(%d+)')
  end
  
  -- Pattern 4: "at line X" format (fallback)
  if not line_num then
    line_num = msg:match('at%s+line%s+(%d+)')
  end
  
  -- Look for live_loop name in message: "+--> :live_loop_NAME"
  local loop_name = msg:match('[+-]+>%s*:live_loop_(%w+)')
  
  -- Fallback: standard live_loop pattern
  if not loop_name then
    loop_name = msg:match('live_loop%s+:(%w+)')
  end
  
  local result = {
    line = line_num and tonumber(line_num),
    live_loop = loop_name
  }
  
  -- Debug: log what we found - SUPER VISIBLE
  if result.line then
    vim.notify(string.format("[Highlighter] ✅ Found line %d, loop: %s", 
      result.line, result.live_loop or 'none'), vim.log.levels.ERROR)
  else
    vim.notify("[Highlighter] No line number found in message", vim.log.levels.WARN)
  end
  
  return result
end

-- Scan buffer to find all live_loop definitions
function M.scan_live_loops(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  M._live_loop_map = {}
  
  for lnum, line in ipairs(lines) do
    -- Match: live_loop :name do
    local loop_name = line:match('live_loop%s+:(%w+)')
    if loop_name then
      M._live_loop_map[loop_name] = {
        bufnr = bufnr,
        start_line = lnum  -- 1-indexed
      }
    end
  end
end

-- Calculate absolute line number from live_loop relative line
local function resolve_line_number(parsed)
  if not parsed.line then
    return nil, nil
  end
  
  local absolute_line = parsed.line
  local bufnr = nil
  
  -- If live_loop context exists, we know which buffer it's in
  if parsed.live_loop and M._live_loop_map[parsed.live_loop] then
    local loop_info = M._live_loop_map[parsed.live_loop]
    bufnr = loop_info.bufnr
    -- Note: SonicPi's eval:LINE is ABSOLUTE, not relative to loop!
    -- The line number from stack trace is already correct
    absolute_line = parsed.line
  else
    -- Try to find the most recently edited sonicpi buffer
    local current_buf = vim.api.nvim_get_current_buf()
    local buf_ft = vim.api.nvim_buf_get_option(current_buf, 'filetype')
    
    if buf_ft == 'sonicpi' then
      bufnr = current_buf
    else
      -- Search for any sonicpi buffer
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and 
           vim.api.nvim_buf_get_option(buf, 'filetype') == 'sonicpi' then
          bufnr = buf
          break
        end
      end
    end
  end
  
  return bufnr, absolute_line
end

-- Clear previous highlight
function M.clear_highlight()
  if M._last_highlight then
    local bufnr = M._last_highlight.bufnr
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, M._namespace, 0, -1)
    end
    M._last_highlight = nil
  end
end

-- Highlight a line in the source buffer
function M.highlight_line(bufnr, line_num, opts)
  opts = opts or {}
  local duration = opts.duration
  if duration == nil then
    duration = 3000  -- Default 3s for errors
  end
  
  local highlight_group = opts.highlight or 'DiffAdd'  -- Green for execution, red for errors
  
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  
  -- Ensure line number is within buffer bounds
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line_num < 1 or line_num > line_count then
    return
  end
  
  -- For error highlighting (duration > 0), clear previous highlight
  if duration > 0 then
    M.clear_highlight()
  end
  
  -- Add highlight (0-indexed for extmark)
  local line_idx = line_num - 1
  vim.api.nvim_buf_add_highlight(
    bufnr,
    M._namespace,
    highlight_group,
    line_idx,
    0,
    -1
  )
  
  -- Track highlight
  if duration > 0 then
    -- Error highlight - store as last_highlight
    M._last_highlight = {
      bufnr = bufnr,
      line = line_num
    }
  else
    -- Execution highlight - add to active_highlights
    table.insert(M._active_highlights, {
      bufnr = bufnr,
      line = line_num
    })
  end
  
  -- Auto-clear after duration (only for errors)
  if duration > 0 then
    vim.defer_fn(function()
      M.clear_highlight()
    end, duration)
  end
end

---Clear all execution highlights
function M.clear_execution_highlights()
  for _, hl in ipairs(M._active_highlights) do
    if vim.api.nvim_buf_is_valid(hl.bufnr) then
      vim.api.nvim_buf_clear_namespace(hl.bufnr, M._namespace, 0, -1)
    end
  end
  M._active_highlights = {}
end


-- Process a log message and highlight if it contains error info
function M.process_log_message(msg_data)
  -- Debug: log that we received a message - SUPER VISIBLE
  vim.notify("[Highlighter] 🔴 PROCESS_LOG_MESSAGE CALLED!", vim.log.levels.ERROR)
  
  -- Handle different message formats
  local message_text = nil
  local stack_trace = nil
  
  if type(msg_data) == 'string' then
    message_text = msg_data
  elseif type(msg_data) == 'table' then
    -- Debug: log message structure
    vim.notify("[Highlighter] Message is table: " .. vim.inspect(vim.tbl_keys(msg_data)), vim.log.levels.DEBUG)
    
    -- From OSC data: data[2] has error message, data[3] has stack trace
    if msg_data.data and msg_data.data[2] then
      message_text = msg_data.data[2]
      stack_trace = msg_data.data[3]  -- Contains line numbers!
      
      -- Decode HTML entities (SonicPi sends HTML-encoded messages)
      message_text = message_text:gsub('&gt;', '>')
      message_text = message_text:gsub('&lt;', '<')
      message_text = message_text:gsub('&amp;', '&')
      message_text = message_text:gsub('&#(%d+);', function(x)
        return string.char(tonumber(x))
      end)
      
      if stack_trace then
        stack_trace = stack_trace:gsub('&gt;', '>')
        stack_trace = stack_trace:gsub('&lt;', '<')
        stack_trace = stack_trace:gsub('&amp;', '&')
        stack_trace = stack_trace:gsub('&#(%d+);', function(x)
          return string.char(tonumber(x))
        end)
      end
      
      vim.notify("[Highlighter] Using data[2]: " .. message_text:sub(1, 50), vim.log.levels.DEBUG)
      if stack_trace then
        vim.notify("[Highlighter] Stack trace: " .. stack_trace:sub(1, 80), vim.log.levels.DEBUG)
      end
    elseif msg_data.lines then
      -- From buffer stream: join lines
      message_text = table.concat(msg_data.lines, '\n')
      vim.notify("[Highlighter] Using lines: " .. message_text:sub(1, 50), vim.log.levels.DEBUG)
    end
  end
  
  if not message_text then
    vim.notify("[Highlighter] No message text extracted", vim.log.levels.WARN)
    return
  end
  
  -- Parse the message (pass both message and stack trace)
  local parsed = parse_error_message(message_text, stack_trace)
  if not parsed.line then
    return
  end
  
  -- Scan for live_loops in all sonicpi buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and 
       vim.api.nvim_buf_get_option(buf, 'filetype') == 'sonicpi' then
      M.scan_live_loops(buf)
    end
  end
  
  -- Resolve absolute line number
  local bufnr, line_num = resolve_line_number(parsed)
  
  if bufnr and line_num then
    M.highlight_line(bufnr, line_num)
  end
end

-- Setup autocmd to scan live_loops when buffer changes
function M.setup()
  vim.notify("[Highlighter] Setting up SonicPi line highlighter", vim.log.levels.INFO)
  
  vim.api.nvim_create_autocmd({'BufWritePost', 'BufEnter'}, {
    pattern = '*.sonicpi',
    callback = function(ev)
      M.scan_live_loops(ev.buf)
    end,
    desc = 'Scan SonicPi buffer for live_loop definitions'
  })
  
  -- Initial scan of existing buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and 
       vim.api.nvim_buf_get_option(buf, 'filetype') == 'sonicpi' then
      M.scan_live_loops(buf)
    end
  end
  
  vim.notify("[Highlighter] Setup complete", vim.log.levels.INFO)
end


---Parse execution tracking from multi_message OSC data
---@param data table OSC data array
---@return table|nil Parsed execution info
local function parse_multi_message(data)
  if not data or #data < 6 then
    return nil
  end
  
  local run = data[1]
  local live_loop_name = data[2]
  local beats = data[3]
  local pair_count = data[4]
  
  -- Extract live_loop name without :live_loop_ prefix
  local loop_name = nil
  if type(live_loop_name) == 'string' then
    loop_name = live_loop_name:match(':live_loop_(.+)')
  end
  
  if not loop_name then
    return nil
  end
  
  -- Parse line/action pairs starting at data[5]
  local lines = {}
  local idx = 5
  for i = 1, pair_count do
    local relative_line = data[idx]
    local action = data[idx + 1]
    
    if relative_line and action then
      table.insert(lines, {
        relative_line = tonumber(relative_line) or 0,
        action = tostring(action)
      })
    end
    
    idx = idx + 2
  end
  
  return {
    live_loop = loop_name,
    beats = beats,
    lines = lines
  }
end


---Process multi_message for execution line highlighting
---@param msg_data table OSC message data
function M.process_execution_message(msg_data)
  if not msg_data or not msg_data.data then
    return
  end
  
  local parsed = parse_multi_message(msg_data.data)
  if not parsed or not parsed.live_loop then
    return
  end
  
  -- Scan for live_loops to get start line
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and 
       vim.api.nvim_buf_get_option(buf, 'filetype') == 'sonicpi' then
      M.scan_live_loops(buf)
    end
  end
  
  -- Get loop start line
  local loop_info = M._live_loop_map[parsed.live_loop]
  if not loop_info then
    return
  end
  
  -- Highlight all executed lines
  for _, line_info in ipairs(parsed.lines) do
    local absolute_line = loop_info.start_line + line_info.relative_line
    M.highlight_line(loop_info.bufnr, absolute_line, {
      duration = 0  -- Stay highlighted (no auto-clear)
    })
  end
end

return M
