# GitHub Package Lookup - Implementation Summary

## Overview

Implemented `<leader>gu` keymap system that resolves package names to GitHub repositories using API lookups.

## Features

- **Smart Package Detection**: Automatically detects package type based on file context
- **API Integration**: Queries RubyGems, NPM, and resolves Go modules to GitHub repos
- **Interactive Picker**: Shows multiple URL options (source, homepage, docs, registry)
- **Direct Search**: Fallback to GitHub search if API lookup fails

## Keymaps

| Keymap | Description |
|--------|-------------|
| `<leader>gul` | **Lookup** - Extract package from cursor line, query API, show picker |
| `<leader>gus` | **Search** - Direct GitHub search for word under cursor |
| `<leader>guo` | **Open** - Use gx.nvim to open any URL under cursor |

## Supported Package Types

### 1. Ruby Gems (Gemfile, *.gemspec)
- **Handler**: `lua/gx/handlers/rubygems.lua`
- **API**: RubyGems.org API (`/api/v1/gems/{name}.json`)
- **Returns**: source_code_uri, homepage_uri, documentation_uri, rubygems_url

### 2. Go Modules (go.mod, *.go)
- **Handler**: `lua/gx/handlers/gomod.lua`
- **Resolution**: Module path IS the GitHub URL
- **Returns**: GitHub repo URL constructed from module path

### 3. NPM Packages (package.json)
- **Handler**: `lua/gx/handlers/npm.lua`
- **API**: `npm view {package} --json` CLI command
- **Returns**: repository.url, homepage, npm_url

## Implementation Details

### Custom Handlers

Custom handlers extend gx.nvim's handler system:

```lua
-- Handler structure
M.name = "handler_name"
function M.handle(mode, line, _)
  -- Check filename/filetype
  -- Extract package name with regex
  -- Return { name, url, metadata }
end
```

### API Integration Module

`lua/github_lookup.lua` provides three fetch functions:

- `fetch_gem_repo(gem_name, callback)` - RubyGems API with plenary.curl
- `fetch_npm_repo(package_name, callback)` - NPM CLI with vim.fn.jobstart
- `fetch_go_repo(module_path, callback)` - Direct URL construction

All functions are async and use callbacks wrapped with `vim.schedule_wrap()`.

### Snacks Picker Integration

The main `<leader>gul` keymap shows an interactive picker with all available URLs:

```lua
Snacks.picker({
  title = "GitHub Repository - {package}",
  items = {
    { text = "Source: https://github.com/...", url = "..." },
    { text = "Homepage: https://...", url = "..." },
    { text = "Docs: https://...", url = "..." },
    { text = "Registry: https://...", url = "..." },
  },
  confirm = function(picker, item)
    -- Open selected URL in browser
  end,
})
```

## Testing

### Unit Tests

Handler tests verify regex patterns and filename matching:

```bash
nvim --headless -c "luafile test_handlers.lua" +qa
```

**Results**: All 8 tests passing ✓
- RubyGems: single quotes, double quotes, non-Gemfile rejection
- Go: go.mod lines, .go import statements  
- NPM: standard packages, scoped packages (@types/*)

### E2E Tests

API integration tests verify actual network calls:

```bash
nvim --headless -c "luafile test_e2e.lua"
```

**Results**: All API integrations working ✓
- RubyGems API: rails → https://github.com/rails/rails
- NPM CLI: express → https://github.com/expressjs/express
- Go module resolution: github.com/gin-gonic/gin → https://github.com/gin-gonic/gin

### Test Files

- `test_gemfile` - Sample Gemfile with rails, pg, puma, sidekiq
- `test_go.mod` - Sample go.mod with gin, cobra, testify
- `test_package.json` - Sample package.json with express, react, axios

## Manual Testing Instructions

1. **Restart Neovim** to load the plugin and handlers

2. **Test Ruby Gems**:
   ```
   nvim ~/.config/nvim/test_gemfile
   ```
   - Put cursor on `rails` in line `gem 'rails'`
   - Press `<Space>gul`
   - Should show picker with GitHub repo URL

3. **Test Go Modules**:
   ```
   nvim ~/.config/nvim/test_go.mod
   ```
   - Put cursor on `github.com/gin-gonic/gin`
   - Press `<Space>gul`
   - Should show picker with GitHub repo URL

4. **Test NPM Packages**:
   ```
   nvim ~/.config/nvim/test_package.json
   ```
   - Put cursor on `"express"`
   - Press `<Space>gul`
   - Should show picker with GitHub repo URL

## Design Decisions

### Why Custom Handlers Instead of Built-in?

gx.nvim has built-in handlers for:
- `package_json` → npmjs.com URLs (NOT GitHub)
- `go` → pkg.go.dev URLs (NOT GitHub)

These go to **package registries**, not GitHub repos. The requirement was to find **GitHub source code**, which requires:
1. API lookups to resolve package → GitHub URL
2. Custom handlers that extract package names
3. Integration layer between handlers and APIs

### Why Not Use gx.nvim Directly?

Built-in `gx` is perfect for opening URLs already in text, but:
- Doesn't resolve package names to URLs
- Doesn't query external APIs
- Doesn't aggregate multiple URL options

Our implementation adds **package resolution** on top of gx.nvim's URL opening.

### Why Snacks Picker Instead of vim.ui.select?

- **User's existing setup**: Project already uses Snacks.nvim
- **Consistency**: Matches other pickers in keymaps.lua
- **Better UX**: Shows full URLs in picker vs truncated in select

## Files Modified/Created

### Modified
- `lua/plugins/init.lua` (lines 518-543) - Added gx.nvim config
- `lua/keymaps.lua` (after line 83) - Added `<leader>gu*` keymaps

### Created
- `lua/gx/handlers/rubygems.lua` (36 lines)
- `lua/gx/handlers/gomod.lua` (57 lines)
- `lua/gx/handlers/npm.lua` (34 lines)
- `lua/github_lookup.lua` (89 lines)
- `test_gemfile` (9 lines)
- `test_go.mod` (11 lines)
- `test_package.json` (12 lines)
- `test_handlers.lua` (145 lines) - Unit tests
- `test_e2e.lua` (53 lines) - E2E API tests
- `test_workflow.lua` (101 lines) - Workflow simulation

## Known Limitations

1. **Rate Limits**: APIs have rate limits (RubyGems, NPM registry)
   - Future: Add caching layer
   - Future: Support GitHub API tokens

2. **Network Required**: All lookups require internet
   - Future: Fallback to offline heuristics

3. **Package Types**: Currently Ruby, Go, NPM only
   - Future: Add Cargo.toml, requirements.txt, composer.json

4. **Go Handler Overlap**: Our custom Go handler coexists with built-in
   - Built-in: Goes to pkg.go.dev (via gx command)
   - Custom: Goes to GitHub (via `<leader>gul`)
   - Both are useful for different purposes

## Future Enhancements

- [ ] Add caching to avoid repeated API calls
- [ ] Support GitHub API tokens for higher rate limits
- [ ] Add more package managers (Cargo, PyPI, Packagist)
- [ ] Add offline mode with heuristic URL construction
- [ ] Add keymap to copy URL instead of opening
- [ ] Show package metadata (stars, description) in picker
