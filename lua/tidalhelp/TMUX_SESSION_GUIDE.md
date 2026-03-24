# TidalHelp External Tmux Session Guide

This guide shows how to run TidalHelp in an **external tmux session** (completely separate from your neovim session) while maintaining full bidirectional communication via Unix socket.

## Overview

With `target = 'tmux_session'`, TidalHelp control panel runs in a separate tmux session that:
- **Persists** across neovim restarts
- Can be viewed in **any terminal** (not just neovim)
- Communicates via **Unix socket** (`/tmp/tidalhelp.sock`)
- Supports all existing features: send, complete, hint, status, list, focus, adjust

## Configuration

Update your `~/.config/nvim/lua/tidalhelp/init.lua`:

```lua
require('tidalhelp').setup({
  target = 'tmux_session',           -- Use external tmux session
  tmux_session_name = 'tidalhelp',   -- Session name (default: 'tidalhelp')
  tmux_window_name = 'control',      -- Window name (default: 'control')
  socket_path = '/tmp/tidalhelp.sock',
  osc_addr = '127.0.0.1:57121',
  auto_start = true,                 -- Auto-start on .tidal files
})
```

## Target Modes Comparison

| Mode | Description | Use Case |
|------|-------------|----------|
| `'terminal'` | Neovim split | Default, simple setup |
| `'tmux'` | Split pane in **current** tmux session | tmux user, same session |
| `'tmux_session'` | **External** tmux session (NEW) | Persistent control panel, view anywhere |

## Usage

### Starting TidalHelp

**Manual start:**
```vim
:TidalStart
```

**Auto-start:**
When you open a `.tidal` file with `auto_start = true`, TidalHelp starts automatically.

**What happens:**
1. Creates tmux session `tidalhelp` (if doesn't exist)
2. Launches `tidalhelp --headless --socket /tmp/tidalhelp.sock`
3. Neovim connects via Unix socket
4. Session persists even after neovim exits

### Viewing the Control Panel

**Option 1: Switch to session (tmux users)**
```vim
:TidalShowPanel
```
This runs `tmux switch-client -t tidalhelp` to switch your tmux client to the TidalHelp session.

**Option 2: Attach in split pane**
```vim
:TidalAttachPanel
```
This creates a split pane showing the TidalHelp session (you can interact with both neovim and control panel).

**Option 3: External terminal**
```bash
# In any terminal
tmux attach -t tidalhelp:control
```

**Option 4: New terminal window**
```bash
# Open new terminal and run:
tmux attach -t tidalhelp
```

### Sending Code

All existing keybindings work exactly the same:

**Normal mode:**
- `Alt+Enter` - Evaluate line/block at cursor
- `K` - Show hint for word under cursor
- `Leader+Esc` - Hush (stop all)
- `Alt+Backspace` - Silence pattern under cursor (d1, d2, etc.)

**Insert mode:**
- `Alt+Enter` - Evaluate line/block
- `Ctrl+H` - Hush

**Visual mode:**
- `Alt+Enter` - Evaluate selection

### Stopping TidalHelp

**Stop the session:**
```vim
:TidalStop
```

This kills the entire tmux session.

**Note:** When you exit neovim, the tmux session **persists** (unlike `target = 'terminal'` or `'tmux'`). This is intentional - the control panel stays running.

## Commands

| Command | Description |
|---------|-------------|
| `:TidalStart` | Create/connect to external tmux session |
| `:TidalStop` | Kill the external tmux session |
| `:TidalShowPanel` | Switch to TidalHelp tmux session (tmux users) |
| `:TidalAttachPanel` | Attach TidalHelp session in split pane |
| `:TidalSend` | Send current line/block |
| `:TidalHush` | Stop all patterns |
| `:TidalHint` | Show hint for word under cursor |
| `:TidalStatus` | Show TidalHelp status |
| `:TidalFocus` | Focus TidalHelp window/pane |

## Session Persistence

**Behavior with `target = 'tmux_session'`:**

1. **First `:TidalStart`:**
   - Creates tmux session `tidalhelp`
   - Launches tidalhelp process
   - Neovim connects via socket

2. **Close neovim:**
   - Tmux session **stays running**
   - Socket remains active
   - Control panel keeps showing live feedback

3. **Reopen neovim:**
   - `:TidalStart` detects existing session
   - Reconnects to same socket
   - All state preserved

4. **Explicit stop:**
   - `:TidalStop` kills the session
   - Socket removed
   - Control panel gone

## Workflow Example

**Setup:**
```vim
" In ~/.config/nvim/lua/tidalhelp/init.lua
require('tidalhelp').setup({
  target = 'tmux_session',
  auto_start = true,
})
```

**Daily usage:**
1. Open neovim on a `.tidal` file → TidalHelp starts in background
2. Code in neovim, send with `Alt+Enter`
3. View control panel: `:TidalAttachPanel` or switch terminal to `tmux attach -t tidalhelp`
4. Close neovim → session persists
5. Reopen neovim → reconnects to same session
6. End of day: `:TidalStop` to clean up

## Advantages

✅ **Persistent** - Survives neovim restarts
✅ **Flexible viewing** - Attach from any terminal
✅ **Clean separation** - Editor and control panel independent
✅ **No window clutter** - Control panel not in neovim window
✅ **Same features** - All socket communication works identically

## Troubleshooting

**"Failed to create tmux session"**
- Not in tmux? Use `target = 'terminal'` instead
- Session name conflict? Change `tmux_session_name`

**"Socket connection failed"**
- Is TidalHelp running? Check `tmux ls` for session
- Socket path: `ls -la /tmp/tidalhelp.sock`
- Restart: `:TidalStop` then `:TidalStart`

**"Session already exists" warning**
- Normal! Means session is running
- Neovim will connect to existing session
- To force restart: `:TidalStop` first

**Control panel not visible**
- Use `:TidalShowPanel` or `:TidalAttachPanel`
- Or attach manually: `tmux attach -t tidalhelp`

## Socket Communication Details

**How it works:**
1. TidalHelp headless mode creates Unix socket at `/tmp/tidalhelp.sock`
2. Neovim plugin connects via `vim.loop.new_pipe()` 
3. Commands sent as text: `send file.tidal:10`, `complete sou`, `hint sound`
4. Responses as JSON: `{"type":"completions","items":[...]}`

**Supported commands:**
- `send <file>:<line>` - Evaluate code at line
- `send <file>:<start>-<end>` - Evaluate range
- `complete <prefix>` - Get completions
- `complete <line>:<col>:<word>` - Smart context-aware completions
- `hint <word>` - Get function documentation
- `status` - Get active patterns status
- `list sound|scale|chord|note` - Get available items
- `focus <pattern_id>` - Focus pattern in control panel
- `adjust <pattern_id> <control> <value>` - Adjust slider/toggle

**No changes needed** - Socket communication is identical across all target modes.

## Migration from Other Modes

**From `target = 'terminal'`:**
```lua
-- Before
target = 'terminal',

-- After
target = 'tmux_session',  -- Add this
tmux_session_name = 'tidalhelp',  -- Optional: customize session name
```

**From `target = 'tmux'`:**
```lua
-- Before (split in current session)
target = 'tmux',

-- After (external session)
target = 'tmux_session',
```

**Behavior changes:**
- Control panel no longer visible in neovim window
- Use `:TidalShowPanel` or `:TidalAttachPanel` to view
- Session persists after neovim exit
- Must explicitly `:TidalStop` to kill session

## Advanced: Multiple Projects

Run different sessions for different projects:

```lua
-- Project A
require('tidalhelp').setup({
  target = 'tmux_session',
  tmux_session_name = 'tidalhelp-projectA',
  socket_path = '/tmp/tidalhelp-projectA.sock',
})
```

```lua
-- Project B
require('tidalhelp').setup({
  target = 'tmux_session',
  tmux_session_name = 'tidalhelp-projectB',
  socket_path = '/tmp/tidalhelp-projectB.sock',
})
```

Each project gets its own isolated session.

## See Also

- **Main README**: `/Users/chhlga/work/tidalhelp/README.md`
- **Headless Mode Docs**: `/Users/chhlga/work/tidalhelp/docs/HEADLESS.md`
- **Neovim Plugin**: `/Users/chhlga/.config/nvim/lua/tidalhelp/`
