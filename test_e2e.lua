-- End-to-end test for GitHub lookup functionality
-- This tests the actual keymap logic without the Snacks picker

print("=== E2E Test: GitHub Lookup ===\n")

-- Load the github_lookup module
local lookup = require('github_lookup')

-- Test 1: RubyGems API (rails gem)
print("Test 1: Fetching rails gem repository...")
lookup.fetch_gem_repo('rails', vim.schedule_wrap(function(result)
  if result and result.source then
    print("✓ SUCCESS: rails -> " .. result.source)
    if result.homepage then
      print("  Homepage: " .. result.homepage)
    end
    if result.docs then
      print("  Docs: " .. result.docs)
    end
  else
    print("✗ FAILED: Could not fetch rails gem info")
  end
end))

-- Test 2: Go module (gin)
print("\nTest 2: Resolving gin Go module...")
lookup.fetch_go_repo('github.com/gin-gonic/gin', vim.schedule_wrap(function(result)
  if result and result.source then
    print("✓ SUCCESS: gin -> " .. result.source)
  else
    print("✗ FAILED: Could not resolve gin module")
  end
end))

-- Test 3: NPM package (express)
print("\nTest 3: Fetching express NPM package...")
lookup.fetch_npm_repo('express', vim.schedule_wrap(function(result)
  if result and result.source then
    print("✓ SUCCESS: express -> " .. result.source)
    if result.homepage then
      print("  Homepage: " .. result.homepage)
    end
  else
    print("✗ FAILED: Could not fetch express package info")
  end
end))

-- Give async operations time to complete
vim.defer_fn(function()
  print("\n=== Tests Complete ===")
  vim.cmd('qa!')
end, 5000)
