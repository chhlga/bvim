-- OSC message interceptor for sonicpi.nvim
-- Hooks into the message flow BEFORE buffer writes

local M = {}
local stream = require('sonicpi.stream')
local highlighter = require('sonicpi.highlighter')

-- Store original functions
local _hooked = false

function M.setup()
  if _hooked then
    return
  end
  
  vim.defer_fn(function()
    local log = require('sonicpi.log')
    local osc = require('sonicpi.osc')
    
    -- Store original decode
    local original_decode = osc.decode
    
    -- Wrap the decoder
    osc.decode = function(chunk)
      -- Call original
      local data = original_decode(chunk)
      
      if not data then
        return data
      end
      
      -- Stream the decoded OSC message
      if data.address and data.address[1] then
        local msg_type = data.address[1]
        
        -- Only stream log/cue/error messages
        if msg_type == 'log' or msg_type == 'error' or 
           (msg_type == 'incoming' and data.address[2] == 'osc') then
          
          stream.broadcast({
            timestamp = os.time(),
            source = "osc",
            message_type = msg_type,
            address = data.address,
            data = data.data,
          })
          
          -- Process execution tracking from multi_message
          if msg_type == 'log' and data.address[2] == 'multi_message' then
            highlighter.process_execution_message(data)
          end
          
          -- Process error messages for line highlighting
          if msg_type == 'error' then
            highlighter.process_log_message(data)
          end
        end
      end
      
      return data
    end
    
    _hooked = true
    vim.notify("SonicPi OSC streaming hook installed", vim.log.levels.INFO)
  end, 1000)
end

return M
