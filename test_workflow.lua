-- Full workflow test: cursor on package name -> extract -> API lookup
print("=== Full Workflow Test ===\n")

local lookup = require('github_lookup')

-- Test 1: Gemfile workflow
print("Test 1: Gemfile - cursor on 'rails'")
vim.cmd('edit test_gemfile')
vim.api.nvim_win_set_cursor(0, {4, 5})  -- Line with 'pg'

local line = vim.api.nvim_get_current_line()
local filename = vim.fn.expand("%:t")
local word = vim.fn.expand("<cword>")

print("  Filename: " .. filename)
print("  Line: " .. line)
print("  Word under cursor: " .. word)

-- Check if handler would match
local rubygems_handler = require('gx.handlers.rubygems')
local result = rubygems_handler.handle('n', line, nil)

if result then
  print("  ✓ Handler matched: " .. result.gem_name)
  
  -- Test API lookup
  lookup.fetch_gem_repo(result.gem_name, vim.schedule_wrap(function(api_result)
    if api_result and api_result.source then
      print("  ✓ API lookup success: " .. api_result.source)
    else
      print("  ✗ API lookup failed")
    end
  end))
else
  print("  ✗ Handler did not match")
end

-- Test 2: Go module workflow
print("\nTest 2: go.mod - cursor on 'gin'")
vim.cmd('edit test_go.mod')
vim.api.nvim_win_set_cursor(0, {5, 15})  -- Line with gin

line = vim.api.nvim_get_current_line()
filename = vim.fn.expand("%:t")

print("  Filename: " .. filename)
print("  Line: " .. line)

local gomod_handler = require('gx.handlers.gomod')
result = gomod_handler.handle('n', line, nil)

if result then
  print("  ✓ Handler matched: " .. result.module_path)
  
  lookup.fetch_go_repo(result.module_path, vim.schedule_wrap(function(api_result)
    if api_result and api_result.source then
      print("  ✓ API lookup success: " .. api_result.source)
    else
      print("  ✗ API lookup failed")
    end
  end))
else
  print("  ✗ Handler did not match")
end

-- Test 3: package.json workflow
print("\nTest 3: package.json - cursor on 'express'")
vim.cmd('edit test_package.json')
vim.api.nvim_win_set_cursor(0, {3, 8})  -- Line with express

line = vim.api.nvim_get_current_line()
filename = vim.fn.expand("%:t")
word = vim.fn.expand("<cword>")

print("  Filename: " .. filename)
print("  Line: " .. line)
print("  Word under cursor: " .. word)

local npm_handler = require('gx.handlers.npm')
result = npm_handler.handle('n', line, nil)

if result then
  print("  ✓ Handler matched: " .. result.package_name)
  
  lookup.fetch_npm_repo(result.package_name, vim.schedule_wrap(function(api_result)
    if api_result and api_result.source then
      print("  ✓ API lookup success: " .. api_result.source)
    else
      print("  ✗ API lookup failed")
    end
  end))
else
  print("  ✗ Handler did not match")
end

-- Wait for async operations
vim.defer_fn(function()
  print("\n=== Workflow Tests Complete ===")
  vim.cmd('qa!')
end, 5000)
