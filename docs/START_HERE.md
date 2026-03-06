# SonicPi Line Highlighter - Status & Testing

## Current Status

✅ **Implementation Complete** - All code is written and syntax-validated
❓ **Testing Needed** - Not highlighting in your environment yet

## What Was Built

A line highlighting system that:
1. Intercepts SonicPi error messages
2. Parses line numbers and live_loop names
3. Calculates absolute line positions
4. Highlights the error line in your source buffer

## Files Created/Modified

### Core Implementation
- `lua/sonicpi/highlighter.lua` ✅ (with extensive debug logging)
- `lua/sonicpi/osc_hook.lua` ✅ (modified to call highlighter)
- `lua/sonicpi/buffer_stream.lua` ✅ (modified to call highlighter)
- `lua/plugins/init.lua` ✅ (calls highlighter.setup())

### Documentation & Testing
- `docs/sonicpi-highlighter.md` - Complete API documentation
- `docs/DEBUGGING.md` - Step-by-step debugging guide
- `docs/MANUAL_TESTING.md` - Quick manual tests ⭐ **START HERE**
- `lua/sonicpi/examples/test_highlighting.sonicpi` - Test file with errors

## Why It's Not Working Yet

There are several possible reasons:

1. **Message Format Mismatch** - SonicPi's actual error format might differ from what we're parsing
2. **Integration Point** - Errors might not be flowing through the path we're hooking
3. **Configuration Issue** - FileType might not be set, or setup not running
4. **Silent Failure** - An error in the code that's being caught silently

## Next Steps - Start Here! 📍

### Step 1: Run Manual Tests (5 minutes)

Open Neovim and follow: **`docs/MANUAL_TESTING.md`**

This will tell us:
- Does the highlighting mechanism work? (Test 1)
- Does message parsing work? (Test 3)  
- Is the integration working? (Test 6)

### Step 2: Check Debug Messages

```vim
:messages
```

Look for `[Highlighter]` prefixed messages. These will show:
- If setup ran
- If messages are being received
- What the messages contain
- Why parsing might be failing

### Step 3: Get Actual Error Format

We need to see what SonicPi's actual error messages look like!

**Option A:** Check the log buffer
1. Open a `.sonicpi` file
2. Trigger an error (typo `slep` instead of `sleep`)
3. Look at the log buffer - what's the exact error text?

**Option B:** Use the streaming client
```bash
python3 ~/.config/nvim/lua/sonicpi/examples/client.py
```

Then trigger an error and see what the client receives.

### Step 4: Report Findings

Based on the tests, we can:
1. Fix the error message patterns to match SonicPi's actual format
2. Adjust the integration point if errors aren't flowing through osc_hook
3. Fix any configuration issues

## Quick Diagnostic

Run this single command in Neovim (in any buffer):

```vim
:lua local h = require('sonicpi.highlighter'); h.setup(); print("✓ Loaded"); h.highlight_line(vim.api.nvim_get_current_buf(), 1, {duration=5000})
```

**Expected:** Line 1 should highlight in red for 5 seconds, and you should see "✓ Loaded" printed.

**If this works:** The highlighter itself is functional. The issue is with detecting/parsing SonicPi errors.

**If this doesn't work:** There's a more fundamental issue (Neovim version, highlight group, etc.)

## Most Likely Issues

Based on similar implementations, the most common problems are:

### 1. Error Message Format
SonicPi's actual error format might be:
```
Runtime Error: [workspace_zero, buffer 0, line 5, ...]
Thread death! RuntimeError: 
  undefined method `slep' for main:Object
  /path/to/buffer:5:in `block in __spider_eval'
```

Not:
```
Runtime Error: [buffer 0, line 5]
```

**Solution:** Once we see the actual format, update the parsing patterns.

### 2. FileType Not Set
The `.sonicpi` extension might not trigger the FileType.

**Check:**
```vim
:set filetype?
```

**Should say:** `filetype=sonicpi`

**If not, add to your config:**
```lua
vim.filetype.add({
  extension = { sonicpi = 'sonicpi' }
})
```

### 3. Errors Go to vim.notify, Not Log Buffer
Looking at `log_error` in the plugin, errors go to `vim.notify()`, not the log buffer!

This means:
- `buffer_stream.lua` won't catch errors (they don't go to the buffer)
- Only `osc_hook.lua` catches them
- This is actually fine - our integration should work

## Debug Mode

The highlighter is now in "debug mode" with extensive logging. Every step logs to `:messages`:

- `[Highlighter] Received message` - Message arrived
- `[Highlighter] Message is table: {...}` - Message structure
- `[Highlighter] Using data[2]: ...` - Extracted text
- `[Highlighter] Parsing message: ...` - What we're parsing
- `[Highlighter] Found line X, loop: Y` - Parsed result
- `Highlighted line X in buffer Y` - Success!

If you see "No line number found", the parsing patterns don't match the actual message format.

## Help Me Help You

To fix this quickly, I need:

1. **Result of Test 1** from `MANUAL_TESTING.md`
   - Does manual highlighting work at all?

2. **Contents of `:messages`** after trying to trigger an error
   - Do you see `[Highlighter]` messages?
   - If yes, what do they say?

3. **Actual error message text** from SonicPi
   - What appears in the log buffer when you make an error?
   - Or what the Python client receives

With this info, I can update the parser patterns to match the real format!

## TL;DR

1. Run `docs/MANUAL_TESTING.md` Test 1 to verify highlighting works
2. Check `:messages` after triggering a SonicPi error
3. Report back what you see
4. I'll fix the patterns to match reality

The infrastructure is solid - we just need to match SonicPi's actual error format!
