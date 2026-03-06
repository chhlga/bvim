-- TCP/Unix Socket streaming server for SonicPi log messages
-- Broadcasts OSC messages to connected clients in real-time

local M = {}
local uv = vim.loop

-- State
M.server = nil
M.clients = {}
M.config = {
  enabled = false,
  port = 0,  -- 0 = auto-assign available port
  unix_socket = nil,
  format = "json",  -- "json" or "raw"
}

---Start TCP server
---@param opts table|nil Configuration options
---@return table|nil server Server handle or nil on error
function M.start(opts)
  opts = opts or {}
  M.config.port = opts.port or 0
  M.config.format = opts.format or "json"
  
  if M.server then
    vim.notify("SonicPi stream server already running", vim.log.levels.WARN)
    return M.server
  end
  
  M.server = uv.new_tcp()
  if not M.server then
    vim.notify("Failed to create TCP server", vim.log.levels.ERROR)
    return nil
  end
  
  local bind_success = M.server:bind("127.0.0.1", M.config.port)
  if not bind_success then
    vim.notify("Failed to bind TCP server", vim.log.levels.ERROR)
    M.server:close()
    M.server = nil
    return nil
  end
  
  local listen_success = M.server:listen(128, function(err)
    if err then
      vim.notify("Server listen error: " .. err, vim.log.levels.ERROR)
      return
    end
    
    M._accept_client()
  end)
  
  if not listen_success then
    vim.notify("Failed to listen on TCP server", vim.log.levels.ERROR)
    M.server:close()
    M.server = nil
    return nil
  end
  
  -- Get actual bound port
  local addr = M.server:getsockname()
  if addr then
    vim.notify(
      string.format("SonicPi stream server listening on %s:%d", addr.ip, addr.port),
      vim.log.levels.INFO
    )
    M.config.port = addr.port
  end
  
  return M.server
end

---Start Unix domain socket server
---@param socket_path string|nil Path to socket file
---@return table|nil server Server handle or nil on error
function M.start_unix(socket_path)
  socket_path = socket_path or "/tmp/sonicpi-stream.sock"
  M.config.unix_socket = socket_path
  
  if M.server then
    vim.notify("SonicPi stream server already running", vim.log.levels.WARN)
    return M.server
  end
  
  -- Remove old socket if exists
  uv.fs_unlink(socket_path)
  
  M.server = uv.new_pipe(false)
  if not M.server then
    vim.notify("Failed to create Unix socket server", vim.log.levels.ERROR)
    return nil
  end
  
  local bind_success = M.server:bind(socket_path)
  if not bind_success then
    vim.notify("Failed to bind Unix socket", vim.log.levels.ERROR)
    M.server:close()
    M.server = nil
    return nil
  end
  
  local listen_success = M.server:listen(128, function(err)
    if err then
      vim.notify("Server listen error: " .. err, vim.log.levels.ERROR)
      return
    end
    
    M._accept_client()
  end)
  
  if not listen_success then
    vim.notify("Failed to listen on Unix socket", vim.log.levels.ERROR)
    M.server:close()
    M.server = nil
    return nil
  end
  
  vim.notify(
    string.format("SonicPi stream server listening on %s", socket_path),
    vim.log.levels.INFO
  )
  
  return M.server
end

---Accept new client connection
---@private
function M._accept_client()
  local client
  
  if M.config.unix_socket then
    client = uv.new_pipe(false)
  else
    client = uv.new_tcp()
  end
  
  if not client then
    vim.notify("Failed to create client handle", vim.log.levels.ERROR)
    return
  end
  
  M.server:accept(client)
  
  local client_id = tostring(client)
  M.clients[client_id] = {
    handle = client,
    connected = true,
  }
  
  -- Handle client reads (keepalive/disconnect detection)
  client:read_start(function(err, chunk)
    if err or not chunk then
      -- Client disconnected
      M._remove_client(client_id)
    end
  end)
  
  local addr_info = ""
  if not M.config.unix_socket then
    local addr = client:getpeername()
    if addr then
      addr_info = string.format(" from %s:%d", addr.ip, addr.port)
    end
  end
  
  vim.notify(
    string.format("SonicPi stream client connected%s", addr_info),
    vim.log.levels.INFO
  )
end

---Remove and cleanup client
---@param client_id string Client identifier
---@private
function M._remove_client(client_id)
  local client = M.clients[client_id]
  if not client then return end
  
  if client.handle and not client.handle:is_closing() then
    client.handle:close()
  end
  
  M.clients[client_id] = nil
end

---Broadcast message to all connected clients
---@param data table OSC message data
function M.broadcast(data)
  if not data then return end
  
  local message
  if M.config.format == "json" then
    -- JSON Lines format (one JSON object per line)
    local success, encoded = pcall(vim.json.encode, data)
    if not success then
      vim.notify("Failed to encode message as JSON", vim.log.levels.ERROR)
      return
    end
    message = encoded .. "\n"
  else
    -- Raw format (simple string representation)
    message = vim.inspect(data) .. "\n"
  end
  
  local disconnected = {}
  
  for client_id, client in pairs(M.clients) do
    if client.handle and not client.handle:is_closing() then
      client.handle:write(message, function(err)
        if err then
          -- Client write failed, mark for removal
          table.insert(disconnected, client_id)
        end
      end)
    else
      table.insert(disconnected, client_id)
    end
  end
  
  -- Cleanup disconnected clients
  for _, client_id in ipairs(disconnected) do
    M._remove_client(client_id)
  end
end

---Stop streaming server and disconnect all clients
function M.stop()
  -- Close all clients
  for client_id, client in pairs(M.clients) do
    if client.handle and not client.handle:is_closing() then
      client.handle:close()
    end
  end
  M.clients = {}
  
  -- Close server
  if M.server and not M.server:is_closing() then
    M.server:close()
  end
  M.server = nil
  
  vim.notify("SonicPi stream server stopped", vim.log.levels.INFO)
end

---Get server status
---@return table Status information
function M.status()
  return {
    running = M.server ~= nil,
    port = M.config.port,
    unix_socket = M.config.unix_socket,
    clients = vim.tbl_count(M.clients),
    format = M.config.format,
  }
end

return M
