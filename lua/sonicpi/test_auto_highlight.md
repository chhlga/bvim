# Testing Automatic Error Highlighting

## What Changed

Added **super-visible debug logging** to track error messages through the system:

1. **OSC Hook** (`osc_hook.lua`) - Shows when error messages arrive from SonicPi
2. **Highlighter** (`highlighter.lua`) - Shows when processing starts and what's parsed

All debug messages now use `vim.log.levels.ERROR` (red) or `.WARN` (yellow) so they're impossible to miss.

## Testing Steps

### Step 1: Restart Neovim
```bash
# Close and reopen Neovim
# OR reload with:
:lua package.loaded['sonicpi.osc_hook'] = nil
:lua package.loaded['sonicpi.highlighter'] = nil
:lua require('sonicpi.osc_hook').setup()
:lua require('sonicpi.highlighter').setup()
```

### Step 2: Open Test File
```vim
:e ~/.config/nvim/lua/sonicpi/examples/test_highlighting.sonicpi
```

### Step 3: Clear Messages
```vim
:messages clear
```

### Step 4: Run and Trigger Error
Press `<leader>r` to run the buffer (should error on `slep`)

### Step 5: Check Messages
```vim
:messages
```

## What You Should See

### If OSC Hook is Working:
```
[OSC Hook] ⚠️  ERROR MESSAGE DETECTED
[OSC Hook] Error data: { 1, "Runtime Error: ...", ... }
[OSC Hook] Calling highlighter.process_log_message
```

### If Highlighter is Processing:
```
[Highlighter] 🔴 PROCESS_LOG_MESSAGE CALLED!
[Highlighter] Message is table: { "data", "address", ... }
[Highlighter] Using data[2]: Runtime Error: undefined method...
[Highlighter] Parsing message: Runtime Error: undefined method...
[Highlighter] ✅ Found line 5, loop: drums
```

### If Line Gets Highlighted:
```
[Highlighter] Highlighting line 12 (loop :drums start=10, relative=5)
```

## Troubleshooting Results

### Case 1: No Messages at All
**Problem**: OSC hook not installed or errors not going through OSC
**Action**: Check if `osc_hook.setup()` was called:
```vim
:lua print(require('sonicpi.osc_hook')._hooked)
```
Should return `true`

### Case 2: OSC Hook Messages BUT No Highlighter Messages
**Problem**: `highlighter.process_log_message()` not being called
**Action**: The OSC hook isn't passing data to highlighter - check line 57 in osc_hook.lua

### Case 3: Highlighter Called BUT "No line number found"
**Problem**: Error message format doesn't match our patterns
**Action**: **CRITICAL - Report the exact error text from messages!**
This tells us what pattern to add.

### Case 4: Line Found BUT No Highlight
**Problem**: Highlight API issue
**Action**: Run manual test:
```vim
:lua require('sonicpi.highlighter').highlight_line(vim.api.nvim_get_current_buf(), 5, {duration = 10000})
```

### Case 5: Everything Works Except Wrong Line
**Problem**: Line number calculation incorrect
**Action**: Check if live_loop scan worked:
```vim
:lua print(vim.inspect(require('sonicpi.highlighter')._live_loop_map))
```

## Quick Diagnosis Commands

```vim
" 1. Check if hook is installed
:lua print(require('sonicpi.osc_hook')._hooked)

" 2. Check if highlighter is set up
:lua print(require('sonicpi.highlighter')._namespace)

" 3. Check live_loop map
:lua print(vim.inspect(require('sonicpi.highlighter')._live_loop_map))

" 4. Test manual highlight
:lua require('sonicpi.highlighter').highlight_line(vim.api.nvim_get_current_buf(), vim.fn.line('.'), {duration = 10000})

" 5. Test manual processing
:lua require('sonicpi.highlighter').process_log_message({data = {0, "Runtime Error: line 5"}})

" 6. View all messages
:messages
```

## Next Steps Based on Results

**After running the test, report back:**

1. **What messages you saw** (copy-paste from `:messages`)
2. **Which case above matches your situation** (1-5)
3. **Did the line highlight appear?** (yes/no)

This will tell us exactly where the chain is breaking!
