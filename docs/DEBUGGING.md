# Debugging SonicPi Line Highlighter

## Step 1: Enable Debug Logging

The highlighter now has comprehensive debug logging. To see the logs:

```vim
" In Neovim, set log level to show DEBUG messages
:set verbose=1

" Or watch messages in real-time
:messages
```

## Step 2: Test if Highlighter is Loaded

Open a `.sonicpi` file and check for these messages:

```
[Highlighter] Setting up SonicPi line highlighter
[Highlighter] Setup complete
```

**If you DON'T see these messages:**
- The highlighter isn't being loaded
- Check `:lua =require('sonicpi.highlighter')` - should not error
- Check if FileType autocmd is running: `:autocmd FileType sonicpi`

## Step 3: Trigger an Error

1. Open the test file:
   ```bash
   nvim ~/.config/nvim/lua/sonicpi/examples/test_highlighting.sonicpi
   ```

2. Run it: `<leader>r`

3. Watch for highlighter debug messages in `:messages`:
   ```
   [Highlighter] Received message
   [Highlighter] Message is table: {...}
   [Highlighter] Using data[2]: ... (or) Using lines: ...
   [Highlighter] Parsing message: ...
   [Highlighter] Found line X, loop: drums (or none)
   Highlighted line X in buffer Y
   ```

## Step 4: Check What Messages Are Being Sent

### From OSC Hook:
```vim
:lua vim.g.debug_osc = true
```

Then watch for OSC error messages. The structure should be:
```lua
{
  address = {"error"},
  data = {
    0,  -- Style
    "Error message here..."  -- The actual error text
  }
}
```

### From Buffer Stream:
```vim
:lua vim.g.debug_buffer = true
```

Watch for buffer updates with error messages.

## Step 5: Manual Test

Try manually highlighting a line to ensure the mechanism works:

```vim
:lua require('sonicpi.highlighter').highlight_line(vim.api.nvim_get_current_buf(), 5, {duration = 10000})
```

**Expected result:** Line 5 should highlight in red for 10 seconds.

**If this DOESN'T work:**
- Check ErrorMsg highlight: `:hi ErrorMsg`
- Check namespace: `:lua =vim.api.nvim_get_namespaces()`
- Should show `sonicpi_line_highlight`

## Step 6: Check Live Loop Tracking

```vim
:lua =require('sonicpi.highlighter')._live_loop_map
```

**Expected output** (if you have live_loops in your buffer):
```lua
{
  drums = { bufnr = 1, start_line = 3 },
  melody = { bufnr = 1, start_line = 10 }
}
```

**If empty:**
- The buffer scan isn't working
- Check filetype: `:set filetype?` should show `sonicpi`
- Manually scan: `:lua require('sonicpi.highlighter').scan_live_loops(vim.api.nvim_get_current_buf())`

## Step 7: Check Actual SonicPi Error Format

The key issue might be that we don't know what the actual error messages look like!

1. Create an error in SonicPi (use the typo `slep` instead of `sleep`)
2. Check what appears in the log buffer
3. If using the streaming, check what the external client receives

### Test Script for External Client:

```python
#!/usr/bin/env python3
import socket, json

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect(("127.0.0.1", 8765))

print("Listening for messages...")
buffer = ""
while True:
    data = sock.recv(4096).decode('utf-8')
    if not data: break
    
    buffer += data
    while '\n' in buffer:
        line, buffer = buffer.split('\n', 1)
        if line.strip():
            msg = json.loads(line)
            if msg.get('message_type') == 'error':
                print("\n=== ERROR MESSAGE ===")
                print("Full structure:", json.dumps(msg, indent=2))
                print("data[2]:", msg.get('data', [None, None, None])[2] if len(msg.get('data', [])) > 2 else "N/A")
                print("====================\n")
```

Save this as `/tmp/debug_sonicpi.py` and run:
```bash
python3 /tmp/debug_sonicpi.py
```

Then trigger an error in SonicPi and see what the actual error structure looks like.

## Common Issues

### Issue 1: Highlighter Not Called

**Symptoms:** No debug messages at all when errors occur

**Check:**
1. Is `osc_hook.setup()` being called? Add to `osc_hook.lua`:
   ```lua
   vim.notify("[OSC Hook] Processing message type: " .. msg_type, vim.log.levels.DEBUG)
   ```

2. Is the error path being taken?
   ```lua
   if msg_type == 'error' then
     vim.notify("[OSC Hook] Calling highlighter", vim.log.levels.INFO)
     highlighter.process_log_message(data)
   end
   ```

### Issue 2: Wrong Message Format

**Symptoms:** "No message text extracted" warning

**Solution:** The error message might not be in `data[2]`. Check structure:
```vim
:lua vim.print(require('sonicpi.log'))
```

Look at how `log_error` function extracts the message.

### Issue 3: Pattern Doesn't Match

**Symptoms:** "No line number found in message"

**Test error patterns:**
```lua
local msg = "Your actual error message here"
local line_num = msg:match('line%s+(%d+)')
print("Found line:", line_num)
```

Common SonicPi error formats to try:
- `"Runtime Error: undefined method 'slep' for main:Object, line: 5"`
- `"Error in live_loop :drums at line 3"`
- `"[buffer 0, line 5, col 3] Syntax error"`

### Issue 4: FileType Not Set

**Symptoms:** No autocmds run, no scanning

**Check:**
```vim
:set filetype?
```

Should say `filetype=sonicpi`. If not, the file extension might not be recognized.

**Fix:** Add to your config:
```lua
vim.filetype.add({
  extension = {
    sonicpi = 'sonicpi'
  }
})
```

## Quick Diagnostic Command

Run this in Neovim after opening a `.sonicpi` file:

```vim
:lua local h = require('sonicpi.highlighter'); print("Setup: OK"); print("Live loops:", vim.inspect(h._live_loop_map)); print("Namespace:", h._namespace); h.highlight_line(vim.api.nvim_get_current_buf(), 1, {duration = 5000})
```

**Expected:** Should print info and highlight line 1 for 5 seconds.

## Next Steps

Based on the debug output, we can:
1. Fix the message parsing patterns
2. Adjust where we hook into the error flow
3. Handle the actual SonicPi error format correctly

**Please run through these steps and report back:**
1. What messages do you see in `:messages`?
2. Does manual highlighting work (Step 5)?
3. What does the error message structure look like (Step 7)?

This will tell us exactly where the issue is!
