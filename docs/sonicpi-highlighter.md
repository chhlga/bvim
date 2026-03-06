# SonicPi Line Highlighter

Automatically highlights source code lines in your SonicPi buffer when errors occur, with support for `live_loop` context and relative line numbers.

## Features

- 🎯 **Automatic line highlighting** - Errors in logs automatically highlight the corresponding line in your source buffer
- 🔄 **live_loop context awareness** - Correctly resolves line numbers relative to `live_loop` start positions
- ⏱️  **Auto-dismiss** - Highlights automatically clear after 3 seconds
- 🎨 **Visual feedback** - Uses Neovim's ErrorMsg highlight group for clear visibility
- 🔍 **Smart buffer detection** - Automatically finds and tracks all SonicPi buffers

## How It Works

### Line Number Resolution

SonicPi error messages contain line numbers that are **relative to the `live_loop` start line**, not absolute buffer positions. The highlighter handles this automatically:

1. **Scans your buffer** for all `live_loop` definitions
2. **Parses error messages** to extract line numbers and loop names
3. **Calculates absolute position**: `absolute_line = loop_start_line + relative_line - 1`
4. **Highlights the exact line** where the error occurred

### Example

Given this SonicPi code:

```ruby
# Line 1
# Line 2
live_loop :drums do
  # Line 4
  sample :bd_haus
  slep 1  # Typo on line 6!
end
```

If SonicPi reports: `"Error in live_loop :drums, line 3"`

The highlighter will:
- Find `:drums` starts at buffer line 3
- Calculate: 3 (start) + 3 (relative) - 1 = **line 6**
- Highlight line 6 (the line with `slep 1`)

## Supported Error Formats

The highlighter recognizes multiple SonicPi error message formats:

- `"Error in live_loop :name, line X"`
- `"Runtime Error: [buffer X, line Y]"`
- `"SyntaxError: [buffer X, line Y, ...]"`
- `"... at line X ..."`
- `"... line X ..."`

## Architecture

```
SonicPi Error/Log Message
    ↓
OSC Hook (osc_hook.lua) or Buffer Stream (buffer_stream.lua)
    ↓
Highlighter (highlighter.lua)
    ├─ Parse message for line number + live_loop name
    ├─ Scan buffer for live_loop definitions
    ├─ Calculate absolute line number
    └─ Highlight line in source buffer
```

## API Reference

### highlighter.setup()

Initialize the highlighter and set up autocmds to track `live_loop` definitions.

```lua
require('sonicpi.highlighter').setup()
```

**Auto-setup**: This is called automatically when you open a `.sonicpi` file.

### highlighter.process_log_message(msg_data)

Process a log/error message and highlight if it contains line information.

```lua
local highlighter = require('sonicpi.highlighter')

-- From OSC data
highlighter.process_log_message({
  data = {0, "Error in live_loop :drums, line 3"}
})

-- From buffer stream
highlighter.process_log_message({
  lines = {"=> Runtime Error: [buffer 0, line 5]"}
})
```

### highlighter.highlight_line(bufnr, line_num, opts)

Manually highlight a specific line.

```lua
local highlighter = require('sonicpi.highlighter')

highlighter.highlight_line(
  vim.api.nvim_get_current_buf(),
  10,  -- Line number (1-indexed)
  { duration = 5000 }  -- Optional: highlight duration in ms
)
```

**Options:**
- `duration` (number): How long to keep highlight (ms). Default: 3000. Set to 0 for permanent.

### highlighter.clear_highlight()

Manually clear the current highlight.

```lua
require('sonicpi.highlighter').clear_highlight()
```

### highlighter.scan_live_loops(bufnr)

Manually scan a buffer for `live_loop` definitions.

```lua
require('sonicpi.highlighter').scan_live_loops(vim.api.nvim_get_current_buf())
```

**Auto-scan**: This runs automatically on `BufWritePost` and `BufEnter` for `.sonicpi` files.

## Configuration

### Change Highlight Duration

Edit `/Users/chhlga/.config/nvim/lua/sonicpi/highlighter.lua`:

```lua
-- Around line 105
local duration = opts.duration or 5000  -- Change from 3000 to 5000 (5 seconds)
```

### Change Highlight Color

The highlighter uses the `ErrorMsg` highlight group. Customize it in your colorscheme:

```lua
vim.api.nvim_set_hl(0, 'ErrorMsg', {
  bg = '#ff0000',
  fg = '#ffffff',
  bold = true
})
```

Or create a custom highlight group:

```lua
-- In highlighter.lua, change 'ErrorMsg' to 'SonicPiError'
vim.api.nvim_buf_add_highlight(
  bufnr,
  M._namespace,
  'SonicPiError',  -- Custom group
  line_idx,
  0,
  -1
)

-- In your init.lua
vim.api.nvim_set_hl(0, 'SonicPiError', {
  bg = '#3d0000',
  fg = '#ff6b6b'
})
```

### Disable Auto-Highlighting

Comment out the setup in `/Users/chhlga/.config/nvim/lua/plugins/init.lua`:

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "sonicpi",
  callback = function()
    -- ...
    -- highlighter.setup()  -- Comment this out
  end,
})
```

## Troubleshooting

### Lines Not Highlighting

**Check if highlighter is loaded:**
```vim
:lua =require('sonicpi.highlighter')
```

**Check for live_loop definitions:**
```vim
:lua =require('sonicpi.highlighter')._live_loop_map
```

Should show: `{ drums = { bufnr = X, start_line = Y }, ... }`

### Wrong Line Highlighted

**Possible causes:**
1. Buffer not saved after editing - live_loop positions outdated
2. Multiple buffers with same live_loop name
3. Error message format not recognized

**Debug:**
```vim
" Enable debug messages
:set verbose=9
" Watch for "Highlighted line X in buffer Y" notifications
```

### Highlight Doesn't Clear

**Manually clear:**
```vim
:lua require('sonicpi.highlighter').clear_highlight()
```

**Clear all highlights in buffer:**
```vim
:lua vim.api.nvim_buf_clear_namespace(0, vim.api.nvim_create_namespace('sonicpi_line_highlight'), 0, -1)
```

## Advanced Usage

### Custom Error Patterns

Add custom error patterns by editing the `parse_error_message` function in `highlighter.lua`:

```lua
-- Around line 15
local function parse_error_message(msg)
  -- ... existing patterns ...
  
  -- Add your custom pattern
  if not line_num then
    line_num = msg:match('your_custom_pattern_(%d+)')
  end
  
  return {
    line = line_num and tonumber(line_num),
    live_loop = loop_name
  }
end
```

### Integration with External Clients

The highlighter works alongside the TCP streaming server. External clients see the same error messages:

```python
# Python client
import socket, json

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect(("127.0.0.1", 8765))

for line in sock.makefile():
    msg = json.loads(line)
    if msg.get('message_type') == 'error':
        print(f"Error detected: {msg['data']}")
        # Line already highlighted in Neovim!
```

### Persistent Highlights

To keep highlights until manually cleared:

```lua
require('sonicpi.highlighter').highlight_line(
  bufnr,
  line_num,
  { duration = 0 }  -- Never auto-clear
)
```

## Implementation Details

### File Structure

```
lua/sonicpi/
├── highlighter.lua       # NEW - Line highlighting logic
├── osc_hook.lua         # MODIFIED - Calls highlighter on errors
├── buffer_stream.lua    # MODIFIED - Calls highlighter on log updates
├── stream.lua           # Unchanged
└── examples/
    └── README.md
```

### Dependencies

- **Neovim 0.7+** (for `nvim_buf_add_highlight` and extmarks)
- **sonicpi.nvim plugin** (for OSC message handling)
- **Existing stream/osc_hook modules**

### Performance

- **Overhead**: Negligible (~1ms per error message)
- **Memory**: ~1KB per buffer (stores live_loop positions)
- **Scanning**: Runs only on buffer save/enter (not on every edit)

## License

MIT (same as parent configuration)
