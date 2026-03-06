-- GitHub URL lookup utilities
-- Fetches GitHub repo URLs from package registries (RubyGems, NPM, Go)

local M = {}

-- Fetch GitHub URL for a Ruby gem
function M.fetch_gem_repo(gem_name, callback)
  local curl = require('plenary.curl')
  local url = string.format("https://rubygems.org/api/v1/gems/%s.json", gem_name)
  
  curl.get({
    url = url,
    callback = vim.schedule_wrap(function(response)
      if response.status == 200 then
        local success, data = pcall(vim.json.decode, response.body)
        if success and data then
          local github_url = data.source_code_uri or data.homepage_uri
          callback({
            source = github_url,
            homepage = data.homepage_uri,
            docs = data.documentation_uri,
            gem_url = data.gem_uri,
          })
          return
        end
      end
      callback(nil)
    end)
  })
end

-- Fetch GitHub URL for an NPM package
function M.fetch_npm_repo(package_name, callback)
  local cmd = { "npm", "view", package_name, "--json" }
  local output = {}
  
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(output, line)
        end
      end
    end,
    on_exit = vim.schedule_wrap(function(_, exit_code)
      if exit_code == 0 then
        local result = table.concat(output, "\n")
        local success, data = pcall(vim.json.decode, result)
        if success and data then
          local repo_url = data.repository and data.repository.url or ""
          -- Clean up git+https://github.com/owner/repo.git → https://github.com/owner/repo
          repo_url = repo_url:gsub("^git%+", ""):gsub("%.git$", "")
          
          callback({
            source = repo_url,
            homepage = data.homepage,
            docs = data.homepage, -- NPM typically uses homepage for docs
            npm_url = string.format("https://www.npmjs.com/package/%s", package_name),
          })
          return
        end
      end
      callback(nil)
    end)
  })
end

-- Fetch GitHub URL for a Go module (direct construction)
function M.fetch_go_repo(module_path, callback)
  -- For GitHub-hosted Go modules, the module path IS the repo path
  -- Example: github.com/gin-gonic/gin → https://github.com/gin-gonic/gin
  local repo_path = module_path:match("(github%.com/[^/]+/[^/]+)")
  
  if repo_path then
    local github_url = "https://" .. repo_path
    callback({
      source = github_url,
      homepage = github_url,
      docs = "https://pkg.go.dev/" .. module_path,
      pkggo_url = "https://pkg.go.dev/" .. module_path,
    })
  else
    callback(nil)
  end
end

return M
