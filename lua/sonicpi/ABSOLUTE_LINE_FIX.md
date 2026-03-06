# CRITICAL FIX: Line Numbers Are Absolute!

## The Discovery

**Your initial request stated:** "line numbers in log are relative to live_loop start line"

**BUT THIS WAS WRONG!** SonicPi's `eval:LINE` numbers are **ABSOLUTE**, not relative!

## Evidence From Your Test

```
✅ Found line 8, loop: simple → Highlighted line 13 ❌
✅ Found line 31, loop: drums → No message (but tried to highlight 36) ❌
✅ Found line 17, loop: melody → Highlighted line 28 ❌
```

**The bug:** Our code was ADDING the loop start line to the already-absolute line number!

**Example:**
- File line 8: `slep 1` (inside `:simple_test` which starts at line 6)
- SonicPi reports: `eval:8` ← **Already absolute line 8!**
- Our broken code calculated: `6 + 8 - 1 = 13` ← **Wrong!**
- Correct: Just use `8` directly!

## The Fix

**File: `lua/sonicpi/highlighter.lua`**

**Before (WRONG):**
```lua
-- Line numbers in logs are relative to live_loop start
absolute_line = loop_info.start_line + parsed.line - 1
```

**After (CORRECT):**
```lua
-- Note: SonicPi's eval:LINE is ABSOLUTE, not relative to loop!
-- The line number from stack trace is already correct
absolute_line = parsed.line
```

## What This Means

The live_loop detection is still useful for:
1. **Knowing which buffer** the error occurred in (when multiple sonicpi files are open)
2. **Validating** that the error is in a known loop
3. **Future enhancements** (e.g., showing loop name in the highlight message)

But for line number calculation, we simply use the stack trace line directly!

## Test Now

```vim
" 1. Restart Neovim
" 2. Open test file
:e ~/.config/nvim/lua/sonicpi/examples/test_highlighting.sonicpi

" 3. Run code
<leader>r

" 4. Expected results:
" - Line 8 highlighted (slep in :simple_test)
" - Line 17 highlighted (slep in :melody)
" - Line 31 highlighted (sleap in :drums)
```

**All three lines should now highlight CORRECTLY at the exact error positions!**

## Apology

I apologize for the confusion. Your original request mentioned "relative to live_loop start line," which I took at face value and implemented. This was a case where the **stated requirement was incorrect**, and I should have questioned it earlier when we saw the actual error format.

The good news: We discovered the truth through **systematic debugging with real data**, and now it's fixed!

---

**Restart Neovim and test. The highlights should now appear on the CORRECT lines!**
