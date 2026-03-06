# Fix Applied - Stack Trace Line Number Extraction

## Problem Identified

SonicPi's error messages have **NO line numbers in `data[2]`**!

**Actual format from your `:messages`:**
```lua
data[2]: "[eval] - Thread death +--> :live_loop_simple_test\n undefined method 'slep'..."
data[3]: "eval:8:in 'block (3 levels)...'"  ← LINE NUMBERS HERE!
```

Our code was only looking at `data[2]`, missing the line numbers in `data[3]`.

## Changes Made

### 1. Extract Stack Trace (`data[3]`)

**File: `lua/sonicpi/highlighter.lua`**

Now extracts both:
- `data[2]` → Error message (for live_loop name)
- `data[3]` → Stack trace (for line numbers)

### 2. Updated Pattern Matching

**New primary pattern:**
```lua
-- Pattern 1: Extract from stack trace "eval:LINE:in"
line_num = stack_trace:match('eval:(%d+):in')
```

**Example match:**
```
"eval:8:in 'block (3 levels)...'" → extracts "8"
"eval:31:in 'block (3 levels)...'" → extracts "31"
```

### 3. Updated live_loop Pattern

**New pattern matches SonicPi's format:**
```lua
-- Pattern: "+--> :live_loop_NAME"
loop_name = msg:match('[+-]+>%s*:live_loop_(%w+)')
```

**Example match:**
```
"[eval] - Thread death +--> :live_loop_drums" → extracts "drums"
```

## Test It Now

### Step 1: Reload Neovim
```bash
# Close and reopen Neovim completely
```

### Step 2: Open Test File
```vim
:e ~/.config/nvim/lua/sonicpi/examples/test_highlighting.sonicpi
```

### Step 3: Clear Messages
```vim
:messages clear
```

### Step 4: Run Code (Trigger Error)
```vim
<leader>r
```

### Step 5: Check Results

**Expected in `:messages`:**
```
[Highlighter] Using data[2]: [eval] - Thread death +--> :live_loop_simple_test...
[Highlighter] Stack trace: eval:8:in 'block (3 levels)...
[Highlighter] ✅ Found line 8, loop: simple_test
```

**Expected in buffer:**
- Line 8 highlighted with RED background (the `slep` typo line inside `:simple_test` loop)
- Line 31 highlighted for `:drums` loop error
- Line 17 highlighted for `:melody` loop error

## What Should Happen

Based on your test file structure:
- `:live_loop_simple_test` starts at line ~5, error at relative line 3 → absolute line 8
- `:live_loop_drums` starts at line ~28, error at relative line 3 → absolute line 31  
- `:live_loop_melody` starts at line ~14, error at relative line 3 → absolute line 17

All three lines with typos (`slep`, `sleap`) should turn RED for 3 seconds.

## If It Still Doesn't Work

Check `:messages` and report:
1. Does it say "✅ Found line X, loop: Y"?
   - YES → Line calculation issue
   - NO → Pattern still not matching (send me the exact stack trace text)

2. If "Found line" but no highlight appears:
   - Run manual test: `:lua require('sonicpi.highlighter').highlight_line(vim.api.nvim_get_current_buf(), 8, {duration = 10000})`
   - If manual test works → timing issue
   - If manual test fails → Neovim API issue

## Debug Commands

```vim
" Check live_loop map after running
:lua print(vim.inspect(require('sonicpi.highlighter')._live_loop_map))

" Should show something like:
" {
"   simple_test = { bufnr = 1, start_line = 5 },
"   drums = { bufnr = 1, start_line = 28 },
"   melody = { bufnr = 1, start_line = 14 }
" }
```

---

**The fix is complete. Test it and let me know if lines highlight correctly now!**
