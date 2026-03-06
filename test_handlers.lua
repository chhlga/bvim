-- Test script for GitHub lookup handlers
-- Run with: nvim --headless -c "luafile test_handlers.lua" -c "qa!"

local function test_rubygems_handler()
  print("\n=== Testing RubyGems Handler ===")
  local handler = require('gx.handlers.rubygems')
  
  -- Set buffer name to Gemfile for tests
  vim.api.nvim_buf_set_name(0, "Gemfile")
  -- Test 1: Gemfile with single quotes
  local line1 = "gem 'rails', '~> 7.0'"
  local result1 = handler.handle('n', line1, nil)
  if result1 then
    print("✓ Test 1 passed: " .. result1.name .. " -> " .. result1.url)
  else
    print("✗ Test 1 failed: Could not extract 'rails' from: " .. line1)
  end
  
  -- Test 2: Gemfile with double quotes
  local line2 = 'gem "pg", "~> 1.5"'
  local result2 = handler.handle('n', line2, nil)
  if result2 then
    print("✓ Test 2 passed: " .. result2.name .. " -> " .. result2.url)
  else
    print("✗ Test 2 failed: Could not extract 'pg' from: " .. line2)
  end
  
  -- Test 3: Should not match non-Gemfile
  vim.api.nvim_buf_set_name(0, "test.rb")
  local result3 = handler.handle('n', line1, nil)
  if not result3 then
    print("✓ Test 3 passed: Correctly ignored non-Gemfile")
  else
    print("✗ Test 3 failed: Should not match in .rb file")
  end
end

local function test_gomod_handler()
  print("\n=== Testing Go Module Handler ===")
  local handler = require('gx.handlers.gomod')
  
  -- Test 1: go.mod require line
  vim.api.nvim_buf_set_name(0, "go.mod")
  local line1 = "\tgithub.com/gin-gonic/gin v1.9.1"
  local result1 = handler.handle('n', line1, nil)
  if result1 then
    print("✓ Test 1 passed: " .. result1.name .. " -> " .. result1.url)
  else
    print("✗ Test 1 failed: Could not extract from: " .. line1)
  end
  
  -- Test 2: .go import statement
  vim.api.nvim_buf_set_name(0, "main.go")
  vim.bo.filetype = "go"
  local line2 = '\t"github.com/spf13/cobra"'
  local result2 = handler.handle('n', line2, nil)
  if result2 then
    print("✓ Test 2 passed: " .. result2.name .. " -> " .. result2.url)
  else
    print("✗ Test 2 failed: Could not extract from: " .. line2)
  end
end

local function test_npm_handler()
  print("\n=== Testing NPM Handler ===")
  local handler = require('gx.handlers.npm')
  
  -- Test 1: package.json dependency
  vim.api.nvim_buf_set_name(0, "package.json")
  local line1 = '    "express": "^4.18.2",'
  local result1 = handler.handle('n', line1, nil)
  if result1 then
    print("✓ Test 1 passed: " .. result1.name .. " -> " .. result1.url)
  else
    print("✗ Test 1 failed: Could not extract 'express' from: " .. line1)
  end
  
  -- Test 2: package.json with @scope
  local line2 = '    "@types/node": "^20.0.0",'
  local result2 = handler.handle('n', line2, nil)
  if result2 then
    print("✓ Test 2 passed: " .. result2.name .. " -> " .. result2.url)
  else
    print("✗ Test 2 failed: Could not extract '@types/node' from: " .. line2)
  end
end

local function test_api_integration()
  print("\n=== Testing API Integration ===")
  local lookup = require('github_lookup')
  
  -- Test RubyGems API
  print("Testing RubyGems API (rails)...")
  lookup.fetch_gem_repo('rails', function(result)
    if result and result.source then
      print("✓ RubyGems API works: " .. result.source)
    else
      print("✗ RubyGems API failed")
    end
  end)
  
  -- Test NPM CLI
  print("Testing NPM CLI (express)...")
  lookup.fetch_npm_repo('express', function(result)
    if result and result.source then
      print("✓ NPM CLI works: " .. result.source)
    else
      print("✗ NPM CLI failed")
    end
  end)
  
  -- Test Go module resolution
  print("Testing Go module resolution...")
  local go_result = lookup.fetch_go_repo('github.com/gin-gonic/gin', function(result)
    if result and result.source then
      print("✓ Go module resolution works: " .. result.source)
    else
      print("✗ Go module resolution failed")
    end
  end)
end

-- Run all tests
print("Starting handler tests...")
print("=====================================")

local success, err = pcall(function()
  test_rubygems_handler()
  test_gomod_handler()
  test_npm_handler()
  
  -- Give async calls time to complete
  vim.defer_fn(function()
    test_api_integration()
    
    -- Wait for API calls to complete before exiting
    vim.defer_fn(function()
      print("\n=====================================")
      print("Tests complete!")
    end, 3000)
  end, 100)
end)

if not success then
  print("ERROR: " .. tostring(err))
end
