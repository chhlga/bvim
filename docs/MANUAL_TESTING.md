# Manual Testing Guide

## Quick Test 1: Does Manual Highlighting Work?

Open any file in Neovim and run:

```vim
:lua require('sonicpi.highlighter').highlight_line(vim.api.nvim_get_current_buf(), vim.fn.line('.'), {duration = 10000})
```

**Expected:** Current line should highlight in red for 10 seconds.

**If this works:** The highlighting mechanism is functional. Issue is with message detection/parsing.

**If this doesn't work:** There's a problem with the highlight API or ErrorMsg group.

## Quick Test 2: Check ErrorMsg Highlight

```vim
:hi ErrorMsg
```

**Expected:** Should show something like `ErrorMsg xxx term=standout ctermfg=15 ctermbg=1 guifg=White guibg=Red`

**If empty or weird:** Your colorscheme might be overriding it. Test with:

```vim
:hi ErrorMsg guifg=#ffffff guibg=#ff0000
```

Then try Test 1 again.

## Quick Test 3: Simulate an Error Message

```vim
:lua require('sonicpi.highlighter').process_log_message({data = {0, "Runtime Error: undefined method `slep' for main:Object\n[buffer 0, line 5]"}})
```

**Expected:** 
- Debug messages in `:messages`
- Line 5 should highlight (if current buffer has 5+ lines)

## Quick Test 4: Test with live_loop

1. Create a test file:

```ruby
# test.sonicpi

live_loop :drums do
  sample :bd_haus
  sleep 0.5
  slep 0.5  # Line 5 - typo here
end
```

2. Save as `test.sonicpi`

3. Run:
```vim
:lua local h = require('sonicpi.highlighter'); h.scan_live_loops(vim.api.nvim_get_current_buf()); print(vim.inspect(h._live_loop_map))
```

**Expected output:**
```lua
{
  drums = {
    bufnr = X,
    start_line = 3
  }
}
```

4. Simulate error for this live_loop:
```vim
:lua require('sonicpi.highlighter').process_log_message({data = {0, "Runtime Error in live_loop :drums, line 3"}})
```

**Expected:** Line 5 (3 + 3 - 1) should highlight.

## Quick Test 5: Check if Highlighter is Set Up

```vim
:messages
```

Look for:
```
[Highlighter] Setting up SonicPi line highlighter
[Highlighter] Setup complete
```

**If not there:**
1. Check if it's being called:
   ```vim
   :autocmd FileType sonicpi
   ```
   
2. Manually trigger:
   ```vim
   :lua require('sonicpi.highlighter').setup()
   ```

## Quick Test 6: Full Integration Test

1. Open test file:
   ```bash
   nvim ~/.config/nvim/lua/sonicpi/examples/test_highlighting.sonicpi
   ```

2. Check `:messages` for setup messages

3. Run the code: `<leader>r`

4. Watch `:messages` for:
   - `[Highlighter] Received message`
   - `[Highlighter] Message is table: ...`
   - `[Highlighter] Using data[2]: ...`
   - `[Highlighter] Parsing message: ...`
   - `[Highlighter] Found line X...`
   - `Highlighted line X in buffer Y`

5. Check if lines actually highlight

## Troubleshooting Results

### Test 1 Failed → Highlighting API Issue
- Check Neovim version: `:version` (need 0.7+)
- Check if extmarks work: `:lua vim.api.nvim_buf_set_extmark(0, vim.api.nvim_create_namespace('test'), 0, 0, {end_col=5, hl_group='Error Msg'})`

### Test 3 Failed → Message Parsing Issue
Check what the actual SonicPi error format is. It might not match our patterns.

### Test 4 Failed → live_loop Tracking Issue
The regex might not be catching your live_loop definitions.

### Test 6 Failed at "Received message" → Integration Issue
The highlighter isn't being called at all. Check:
1. Is `osc_hook.setup()` running?
2. Are errors actually going through the OSC path?
3. Is the FileType set correctly?

## Report Back

Please run these tests and report:
1. Which tests pass/fail
2. What you see in `:messages`
3. Any error messages

This will pinpoint exactly where the issue is!
