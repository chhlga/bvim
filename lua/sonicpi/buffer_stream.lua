-- Stream integration for sonicpi.nvim
-- Attaches to log buffers and streams their updates via TCP

local M = {
  _attached_buffers = {}  -- Track which buffers we've attached to
}
local stream = require('sonicpi.stream')
local highlighter = require('sonicpi.highlighter')

-- Attach streaming to sonicpi log buffer
function M.attach_to_log_buffer()
  vim.defer_fn(function()
    local log = require('sonicpi.log')
    
    if not log.log or not log.log.buffer then
      vim.notify("SonicPi log buffer not ready", vim.log.levels.WARN)
      return
    end
    
    local bufnr = log.log.buffer
    
    if not vim.api.nvim_buf_is_valid(bufnr) then
      vim.notify("SonicPi log buffer invalid", vim.log.levels.WARN)
      return
    end
    
    -- Skip if already attached
    if M._attached_buffers[bufnr] then
      vim.notify("SonicPi log buffer already attached", vim.log.levels.INFO)
      return
    end
    
    -- Attach to buffer line updates
    local attached = vim.api.nvim_buf_attach(bufnr, false, {
      on_lines = function(_, buf, _, firstline, _, new_lastline)
        -- Get the new lines that were added
        local lines = vim.api.nvim_buf_get_lines(buf, firstline, new_lastline, false)
        
        vim.notify(string.format("Buffer update: %d lines from %d", #lines, firstline), vim.log.levels.DEBUG)
        
        if #lines > 0 then
          local msg_data = {
            timestamp = os.time(),
            source = "buffer",
            buffer_type = "log",
            lines = lines,
            firstline = firstline,
          }
          
          -- Stream the buffer update
          stream.broadcast(msg_data)
          
          -- Process for line highlighting
          highlighter.process_log_message(msg_data)
        end
        
        return false  -- Don't detach
      end,
      on_detach = function()
        M._attached_buffers[bufnr] = nil
        vim.notify("SonicPi log buffer detached", vim.log.levels.INFO)
      end,
    })
    
    if attached then
      M._attached_buffers[bufnr] = true
      vim.notify(string.format("SonicPi log streaming attached to buffer %d", bufnr), vim.log.levels.INFO)
    else
      vim.notify("Failed to attach to SonicPi log buffer", vim.log.levels.ERROR)
    end
  end, 2000)  -- Wait 2 seconds for buffers to be created
end

-- Attach to cue buffer as well
function M.attach_to_cue_buffer()
  vim.defer_fn(function()
    local log = require('sonicpi.log')
    
    if not log.cue or not log.cue.buffer then
      return
    end
    
    local bufnr = log.cue.buffer
    
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    
    if M._attached_buffers[bufnr] then
      return
    end
    
    local attached = vim.api.nvim_buf_attach(bufnr, false, {
      on_lines = function(_, buf, _, firstline, _, new_lastline)
        local lines = vim.api.nvim_buf_get_lines(buf, firstline, new_lastline, false)
        
        if #lines > 0 then
          stream.broadcast({
            timestamp = os.time(),
            source = "buffer",
            buffer_type = "cue",
            lines = lines,
            firstline = firstline,
          })
        end
        
        return false
      end,
      on_detach = function()
        M._attached_buffers[bufnr] = nil
      end,
    })
    
    if attached then
      M._attached_buffers[bufnr] = true
      vim.notify(string.format("SonicPi cue streaming attached to buffer %d", bufnr), vim.log.levels.INFO)
    end
  end, 2000)
end

function M.setup()
  M.attach_to_log_buffer()
  M.attach_to_cue_buffer()
end

return M
