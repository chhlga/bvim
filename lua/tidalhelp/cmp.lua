-- TidalHelp completion source for nvim-cmp / blink.compat
-- Provides Tidal function completions via tidalhelp headless mode

local process = require('tidalhelp.process')

local source = {}

source.new = function()
  return setmetatable({}, { __index = source })
end

---Get source name
---@return string
function source:get_debug_name()
  return 'tidalhelp'
end

---Check if source is available
---@return boolean
function source:is_available()
  return process.is_running()
end

---Get trigger characters
---@return string[]
function source:get_trigger_characters()
  return { '$', '#', ' ', '"', "'" }
end

---Get keyword pattern
---@return string
function source:get_keyword_pattern()
  return [[\k\+]]
end

---Perform completion
---@param params table Completion parameters
---@param callback function Callback to invoke with results
function source:complete(params, callback)
  local cursor = params.context.cursor
  local line = params.context.cursor_line
  local col = cursor.col
  
  -- Extract word before cursor
  local before_cursor = line:sub(1, col)
  local word = before_cursor:match('[%w_]+$') or ''
  
  -- Need at least 1 character (allow single char for samples like 'd', 'e')
  if #word < 1 then
    callback({ items = {}, isIncomplete = false })
    return
  end

  if not process.is_running() then
    callback({ items = {}, isIncomplete = false })
    return
  end

  -- Send full context for smart completion: line:col:word
  -- This enables parameter-aware suggestions (samples inside sound "...", etc.)
  process.complete_smart(line, col, word, function(items)
    local cmp_items = {}
    
    for _, item in ipairs(items) do
      table.insert(cmp_items, {
        label = item.label,
        insertText = item.insertText or item.label,
        detail = item.detail,
        documentation = item.documentation and {
          kind = 'markdown',
          value = '```haskell\n' .. (item.detail or '') .. '\n```\n\n' .. (item.documentation or ''),
        } or nil,
        kind = 3, -- Function
      })
    end
    
    callback({
      items = cmp_items,
      isIncomplete = false,
    })
  end)
end

return source
