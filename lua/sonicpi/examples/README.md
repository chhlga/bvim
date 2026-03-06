# SonicPi Examples

Example clients and test files for SonicPi streaming and line highlighting features.

## Files

- **client.py** - Python TCP client for receiving log streams
- **client.js** - Node.js TCP client for receiving log streams
- **test_highlighting.sonicpi** - Test file demonstrating automatic line highlighting
- **README.md** - This file

## Quick Test: Line Highlighting

1. **Open the test file:**
   ```bash
   nvim test_highlighting.sonicpi
   ```

2. **Run the code:** Press `<leader>r` in Neovim

3. **Watch the magic:**
   - Errors appear in the log buffer
   - Lines with typos highlight automatically in the source buffer
   - Highlights use the ErrorMsg color (red background)
   - Auto-clear after 3 seconds

See [sonicpi-highlighter.md](../../../docs/sonicpi-highlighter.md) for full documentation.

## Prerequisites

Example clients to connect to the SonicPi TCP streaming server and receive real-time log messages.

## Prerequisites

1. Open a `.sonicpi` file in Neovim (triggers FileType autocmd)
2. The streaming server automatically starts on port **8765**
3. Run one of the example clients below

## Python Client

```bash
python3 client.py
```

**Requirements**: Python 3.6+ (no external dependencies)

## Node.js Client

```bash
node client.js
# or make it executable and run directly:
./client.js
```

**Requirements**: Node.js 12+ (no external dependencies)

## Message Format

Messages are sent as **JSON Lines** (one JSON object per line):

```json
{
  "timestamp": 1709731200,
  "address": ["log"],
  "address_raw": "/log",
  "data": [0, "=> Sample playing..."]
}
```

### Fields

- `timestamp`: Unix timestamp when message was received
- `address`: OSC address parts as array (e.g., `["log"]`, `["incoming", "osc"]`)
- `address_raw`: Full OSC address string (e.g., `"/log"`, `"/incoming/osc"`)
- `data`: OSC message data (format varies by message type)

## Custom Clients

You can build your own client in any language. The protocol is simple:

1. **Connect** to TCP socket at `127.0.0.1:8765`
2. **Read** data as newline-delimited JSON
3. **Parse** each line as a JSON object
4. **Process** the `address_raw` and `data` fields

### Example in Rust

```rust
use std::io::{BufRead, BufReader};
use std::net::TcpStream;

fn main() -> std::io::Result<()> {
    let stream = TcpStream::connect("127.0.0.1:8765")?;
    let reader = BufReader::new(stream);
    
    for line in reader.lines() {
        let line = line?;
        if let Ok(msg) = serde_json::from_str::<serde_json::Value>(&line) {
            println!("{}", msg);
        }
    }
    
    Ok(())
}
```

### Example in Go

```go
package main

import (
    "bufio"
    "encoding/json"
    "fmt"
    "net"
)

func main() {
    conn, err := net.Dial("tcp", "127.0.0.1:8765")
    if err != nil {
        panic(err)
    }
    defer conn.Close()
    
    scanner := bufio.NewScanner(conn)
    for scanner.Scan() {
        var msg map[string]interface{}
        if err := json.Unmarshal(scanner.Bytes(), &msg); err == nil {
            fmt.Println(msg)
        }
    }
}
```

## Troubleshooting

### Connection Refused

- Make sure Neovim is running
- Open a `.sonicpi` file to trigger the server
- Check that no other process is using port 8765

### No Messages Received

- Start the SonicPi daemon (`:SonicPiStartDaemon` in Neovim)
- Run some SonicPi code (`<leader>r` to run buffer)
- Check that the log window is receiving messages

### Change Port

Edit `/Users/chhlga/.config/nvim/lua/plugins/init.lua` line 631:

```lua
stream.start({ port = 9999, format = "json" })  -- Custom port
```

## Unix Socket (Alternative)

For lower latency on the same machine, use Unix sockets:

```lua
stream.start_unix("/tmp/sonicpi-stream.sock")
```

Then connect using Unix socket in Python:

```python
import socket
sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.connect("/tmp/sonicpi-stream.sock")
```
