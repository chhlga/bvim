local wk = require("which-key")

wk.setup({})

wk.add({
  { "<leader>f",   group = "Find" },
  { "<leader>fe",  function() Snacks.picker.explorer({ layout = { preset = "default", preview = true }, auto_close = true }) end, desc = "Explorer" },
  { "<leader>ff",  function() Snacks.picker.files({ hidden = true, ignored = true }) end,                                         desc = "Find File" },
  { "<leader>fg",  function() Snacks.picker.grep({ hidden = true, ignored = true }) end,                                          desc = "Grep Text" },
  { "<leader>fr",  function() Snacks.picker.recent() end,                                                                         desc = "Recent files" },
  { "<leader>fb",  function() Snacks.picker.buffers() end,                                                                        desc = "Buffers" },
  { "<leader>fp",  function() Snacks.picker.projects() end,                                                                       desc = "Projects" },
  { "<leader>fG",  function() Snacks.picker.grep_buffers() end,                                                                   desc = "Grep buffers" },
  { "<leader>fn",  "<cmd>ene<CR>",                                                                                                desc = "New File" },

  { "<leader>b",   group = "Buffers" },
  { "<leader>bd",  "<cmd>bdelete<CR>",                                                                                            desc = "Delete buffer" },
  { "<leader>bp",  "<cmd>BufferLineTogglePin<CR>",                                                                                desc = "Toggle pin" },
  { "<leader>bf",  function() Snacks.picker.buffers() end,                                                                        desc = "Find buffer" },
  { "<leader>bb",  "<cmd>BufferLinePick<CR>",                                                                                     desc = "Pick buffer" },
  { "<leader>bD",  "<cmd>silent! %bdelete<CR>",                                                                                   desc = "Delete all" },
  { "<leader>bc",  group = "Close" },
  { "<leader>bco", "<cmd>BufferLineCloseOthers<CR>",                                                                              desc = "Close others" },
  { "<leader>bcr", "<cmd>BufferLineCloseRight<CR>",                                                                               desc = "Close right" },
  { "<leader>bcl", "<cmd>BufferLineCloseLeft<CR>",                                                                                desc = "Close left" },

  { "<leader>g",   group = "Git" },
  { "<leader>gg",  "<cmd>Git status<CR>",                                                                                         desc = "Status" },
  { "<leader>gf",  function() Snacks.picker.git_log_file() end,                                                                   desc = "File history" },
  { "<leader>gb",  group = "Branch" },
  { "<leader>gbb", function() Snacks.picker.git_branches() end,                                                                   desc = "List branches" },
  {
    "<leader>gbn",
    function()
      vim.ui.input({ prompt = 'Branch name: ' }, function(name)
        if name then vim.cmd('Git branch ' .. name) end
      end)
    end,
    desc = "New branch"
  },
  { "<leader>gl",  group = "Blame" },
  { "<leader>gll", "<cmd>Gitsigns blame_line<CR>",             desc = "Blame line" },
  { "<leader>glf", function() require('gitsigns').blame() end, desc = "Blame file" },
  { "<leader>gc",  group = "Commit" },
  { "<leader>gch", function() Snacks.picker.git_log() end,     desc = "History" },
  {
    "<leader>gcam",
    function()
      vim.cmd('Git add .')
      vim.ui.input({ prompt = 'Commit message: ' }, function(msg)
        if msg then vim.cmd(string.format('Git commit -m "%s"', msg)) end
      end)
    end,
    desc = "Add all & commit"
  },
  {
    "<leader>gcama",
    function()
      vim.cmd('Git add .')
      require("opencode").ask("@diff: make a commit for these changes", { submit = true })
    end,
    desc = "Add all & commit using llm"
  },
  { "<leader>gs",  group = "Stash" },
  { "<leader>gss", "<cmd>Git stash<CR>",     desc = "Stash" },
  { "<leader>gsp", "<cmd>Git stash pop<CR>", desc = "Pop" },
  { "<leader>gp",  group = "Push" },
  { "<leader>gpp", "<cmd>Git push<CR>",      desc = "Push" },
  { "<leader>gpl", "<cmd>Git pull<CR>",      desc = "Pull" },
  {
    "<leader>gpsup",
    function()
      local branch = vim.fn.system("git branch --show-current"):gsub("\n", "")
      vim.cmd('Git push --set-upstream origin ' .. branch)
    end,
    desc = "Push & set upstream"
  },
  { "<leader>gd",  group = "Diff" },
  { "<leader>gds", function() Snacks.picker.git_status() end, desc = "Changed files" },
  { "<leader>gdv", "<cmd>DiffviewOpen<CR>",                   desc = "Diffview" },
  { "<leader>gdh", "<cmd>DiffviewFileHistory %<CR>",          desc = "File history" },
  { "<leader>gdH", "<cmd>DiffviewFileHistory<CR>",            desc = "Branch history" },
  { "<leader>gdq", "<cmd>DiffviewClose<CR>",                  desc = "Close diffview" },

  { "<leader>gu",  group = "GitHub" },
  {
    "<leader>gul",
    function()
      local lookup = require('github_lookup')
      local word = vim.fn.expand("<cword>")
      local line = vim.fn.getline(".")
      local filename = vim.fn.expand("%:t")
      local filetype = vim.bo.filetype

      -- Determine package type and name
      local pkg_type, pkg_name

      -- Check for Gemfile
      if filename == "Gemfile" or filename:match("%.gemspec$") or filename == "gems.rb" then
        pkg_name = line:match("gem%s+['\"]([^'\"]+)['\"]")
        pkg_type = "gem"
        -- Check for go.mod or .go files
      elseif filename == "go.mod" or filetype == "go" then
        pkg_name = line:match("(github%.com/[%w%.%-_/]+)") or word
        pkg_type = "go"
        -- Check for package.json
      elseif filename == "package.json" then
        pkg_name = line:match('"(@?[%w%.%-_/@]+)"%s*:%s*"')
        pkg_type = "npm"
      else
        -- Fallback: use word under cursor
        pkg_name = word
        pkg_type = "unknown"
      end

      if not pkg_name or pkg_name == "" then
        vim.notify("No package name found under cursor", vim.log.levels.WARN)
        return
      end

      vim.notify("Looking up " .. pkg_name .. "...", vim.log.levels.INFO)

      -- Fetch repo URLs based on package type
      local fetch_fn
      if pkg_type == "gem" then
        fetch_fn = lookup.fetch_gem_repo
      elseif pkg_type == "npm" then
        fetch_fn = lookup.fetch_npm_repo
      elseif pkg_type == "go" then
        fetch_fn = lookup.fetch_go_repo
      else
        vim.notify("Unknown package type. Use <leader>gus to search GitHub directly.", vim.log.levels.WARN)
        return
      end

      fetch_fn(pkg_name, function(urls)
        if not urls or not urls.source then
          vim.notify("Could not find GitHub repo for " .. pkg_name, vim.log.levels.ERROR)
          return
        end

        -- Show Snacks picker with options
        local items = {}

        if urls.source and urls.source ~= "" then
          table.insert(items, {
            text = "📦 Source Code: " .. urls.source,
            url = urls.source,
            type = "source"
          })
        end

        if urls.homepage and urls.homepage ~= "" and urls.homepage ~= urls.source then
          table.insert(items, {
            text = "🏠 Homepage: " .. urls.homepage,
            url = urls.homepage,
            type = "homepage"
          })
        end

        if urls.docs and urls.docs ~= "" and urls.docs ~= urls.source and urls.docs ~= urls.homepage then
          table.insert(items, {
            text = "📚 Documentation: " .. urls.docs,
            url = urls.docs,
            type = "docs"
          })
        end

        if urls.gem_url then
          table.insert(items, {
            text = "💎 RubyGems: " .. urls.gem_url,
            url = urls.gem_url,
            type = "registry"
          })
        end

        if urls.npm_url then
          table.insert(items, {
            text = "📦 NPM: " .. urls.npm_url,
            url = urls.npm_url,
            type = "registry"
          })
        end

        if urls.pkggo_url then
          table.insert(items, {
            text = "🔵 pkg.go.dev: " .. urls.pkggo_url,
            url = urls.pkggo_url,
            type = "registry"
          })
        end

        if #items == 0 then
          vim.notify("No URLs found for " .. pkg_name, vim.log.levels.WARN)
          return
        end

        -- Show picker
        Snacks.picker({
          title = "GitHub Lookup: " .. pkg_name,
          items = items,
          format = "text",
          layout = { preset = "default" },
          confirm = function(picker, item)
            picker:close()
            if item and item.url then
              vim.fn.system({ "open", item.url })
            end
          end,
        })
      end)
    end,
    desc = "Lookup package on GitHub"
  },
  {
    "<leader>gus",
    function()
      local word = vim.fn.expand("<cword>")
      if word and word ~= "" then
        local search_url = string.format("https://github.com/search?q=%s&type=repositories", word)
        vim.fn.system({ "open", search_url })
      else
        vim.notify("No word under cursor", vim.log.levels.WARN)
      end
    end,
    desc = "Search GitHub for word"
  },
  {
    "<leader>guo",
    function()
      local gx = require('gx')
      gx.open()
    end,
    desc = "Open URL with gx (any URL)"
  },

  { "<leader>c",  group = "Code" },
  { "<leader>ca", desc = "Code action" },
  { "<leader>cr", desc = "Rename symbol" },
  { "<leader>cf", desc = "Format" },
  { "<leader>cl", desc = "Run codelens" },
  { "<leader>cL", desc = "Refresh codelens" },
  { "<leader>ch", desc = "Toggle inlay hints" },
  { "<leader>co", desc = "Organize imports" },
  {
    "<leader>cd",
    function()
      local row = vim.api.nvim_win_get_cursor(0)[1]
      vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, { "binding.irb" })
    end,
    desc = "Insert binding.irb"
  },
  { "<leader>cs",  group = "Symbols" },
  { "<leader>csd", desc = "Document symbols" },
  { "<leader>csw", desc = "Workspace symbols" },

  { "<leader>l",   group = "Diagnostics" },
  { "<leader>ld",  desc = "Line diagnostic" },
  { "<leader>lb",  desc = "Buffer diagnostics" },
  { "<leader>lw",  desc = "Workspace diagnostics" },

  { "<leader>a",   group = "AI" },
  {
    "<leader>aa",
    function()
      require("opencode.provider").start()
      vim.defer_fn(function()
        require("opencode").ask("@this: ", { submit = true })
      end, 500)
    end,
    desc = "Ask about this",
    mode = { "n", "v" }
  },
  { "<leader>ae",  function() require("opencode").select() end,                          desc = "Select action" },
  { "<leader>at",  function() require("opencode").toggle() end,                          desc = "Toggle panel" },
  { "<leader>ao",  group = "Navigation" },
  { "<leader>aou", function() require("opencode").command("session.half.page.up") end,   desc = "Half page up" },
  { "<leader>aod", function() require("opencode").command("session.half.page.down") end, desc = "Half page down" },
  {
    "<leader>acs",
    function()
      if not vim.g._copilot_panel_picker_fn_defined then
        vim.g._copilot_panel_picker_fn_defined = true
        vim.api.nvim_exec2(
          [[
function! CopilotPanelItems(position, bufnr) abort
  try
    let params = { 'textDocument': { 'uri': a:bufnr }, 'position': a:position }
    let res = copilot#Request('textDocument/copilotPanelCompletion', params).Await()
    if type(res) == v:t_dict
      return get(res, 'items', [])
    endif
    return res
  catch
    return []
  endtry
endfunction
        ]],
          {}
        )
      end

      local bufnr = vim.api.nvim_get_current_buf()
      local was_insert = vim.fn.mode():match("^[iR]") ~= nil
      local position
      if was_insert then
        vim.cmd.stopinsert()
        position = vim.fn["copilot#util#AppendPosition"]()
      else
        position = {
          line = vim.fn.line(".") - 1,
          character = vim.fn["copilot#util#UTF16Width"](vim.fn.getline(".")),
        }
      end

      local original_line = vim.api.nvim_buf_get_lines(bufnr, position.line, position.line + 1, false)[1] or ""

      ---@type table[]
      local items = vim.fn.CopilotPanelItems(position, bufnr)
      if type(items) ~= "table" or vim.tbl_isempty(items) then
        vim.notify("Copilot: no suggestions", vim.log.levels.INFO, { title = "Copilot" })
        return
      end

      local function split_lines(s)
        return vim.split(s:gsub("\r\n", "\n"), "\n", { plain = true })
      end

      local function byte_idx(line, utf16_char)
        local idx = vim.fn["copilot#util#UTF16ToByteIdx"](line, utf16_char)
        if type(idx) ~= "number" or idx < 0 then
          return #line
        end
        return idx
      end

      local picker_items = {} ---@type snacks.picker.Item[]
      for i, item in ipairs(items) do
        if type(item) == "table" and type(item.insertText) == "string" and type(item.range) == "table" then
          local lines = split_lines(item.insertText)

          local start_line = item.range.start.line
          local start_char = item.range.start.character
          local end_line = item.range["end"].line
          local end_char = item.range["end"].character

          local old_first = vim.api.nvim_buf_get_lines(bufnr, start_line, start_line + 1, false)[1] or ""
          local old_last = vim.api.nvim_buf_get_lines(bufnr, end_line, end_line + 1, false)[1] or ""
          local start_byte = byte_idx(old_first, start_char)
          local end_byte = byte_idx(old_last, end_char)

          lines[1] = old_first:sub(1, start_byte) .. lines[1]
          lines[#lines] = lines[#lines] .. old_last:sub(end_byte + 1)

          local title = (lines[1]:gsub("^%s+", ""):gsub("%s+$", ""))
          if #title > 90 then
            title = title:sub(1, 90) .. "…"
          end

          picker_items[#picker_items + 1] = {
            idx = i,
            text = title == "" and ("Suggestion " .. i) or title,
            preview = {
              text = table.concat(lines, "\n"),
              ft = vim.bo[bufnr].filetype,
              loc = false,
            },
            _copilot = {
              item = item,
              bufnr = bufnr,
              line = original_line,
              was_insert = was_insert,
            },
          }
        end
      end

      if vim.tbl_isempty(picker_items) then
        vim.notify("Copilot: no suggestions", vim.log.levels.INFO, { title = "Copilot" })
        return
      end

      Snacks.picker({
        title = "Copilot",
        prompt = " ",
        items = picker_items,
        format = "text",
        preview = "preview",
        layout = { preset = "vscode" },
        win = {
          input = {
            keys = {
              ["<Esc>"] = { "close", mode = { "n", "i" } },
            },
          },
        },
        confirm = function(picker, selection)
          picker:close()
          if not selection or type(selection._copilot) ~= "table" then
            return
          end

          local meta = selection._copilot
          local buf = meta.bufnr
          local copilot_item = meta.item
          if not vim.api.nvim_buf_is_valid(buf) then
            vim.notify("Copilot: buffer is gone", vim.log.levels.ERROR, { title = "Copilot" })
            return
          end

          local lnum = copilot_item.range.start.line
          local current_line = vim.api.nvim_buf_get_lines(buf, lnum, lnum + 1, false)[1] or ""
          if current_line ~= meta.line then
            vim.notify("Copilot: buffer changed since synthesizing completion", vim.log.levels.WARN,
              { title = "Copilot" })
            return
          end

          local function apply()
            local insert_lines = split_lines(copilot_item.insertText)

            local s_line = copilot_item.range.start.line
            local s_char = copilot_item.range.start.character
            local e_line = copilot_item.range["end"].line
            local e_char = copilot_item.range["end"].character

            local first = vim.api.nvim_buf_get_lines(buf, s_line, s_line + 1, false)[1] or ""
            local last = vim.api.nvim_buf_get_lines(buf, e_line, e_line + 1, false)[1] or ""
            local s_byte = byte_idx(first, s_char)
            local e_byte = byte_idx(last, e_char)

            insert_lines[1] = first:sub(1, s_byte) .. insert_lines[1]
            insert_lines[#insert_lines] = insert_lines[#insert_lines] .. last:sub(e_byte + 1)

            vim.api.nvim_buf_set_lines(buf, s_line, e_line + 1, false, insert_lines)

            vim.api.nvim_set_current_buf(buf)
            vim.api.nvim_win_set_cursor(0, { s_line + #insert_lines, 0 })
            if meta.was_insert then
              vim.cmd.startinsert({ bang = true })
            else
              vim.cmd.normal({ args = { "$" }, bang = true })
            end
          end

          vim.schedule(apply)

          if type(copilot_item.command) == "table" then
            pcall(vim.fn["copilot#Request"], "workspace/executeCommand", copilot_item.command)
          end
        end,
      })
    end,
    desc = "Copilot suggestions"
  },

  { "<leader>e",   group = "Explorer" },
  { "<leader>ee",  function() Snacks.picker.explorer({ hidden = true, ignored = true }) end, desc = "Explorer" },
  -- { "<leader>ee",  "<cmd>Neotree reveal last left<CR>",             desc = "Toggle Explorer" },
  { "<leader>ef",  "<cmd>Neotree focus filesystem left reveal<CR>",                          desc = "Focus Files" },
  { "<leader>eb",  "<cmd>Neotree focus buffers left<CR>",                                    desc = "Focus Buffers" },
  { "<leader>eg",  "<cmd>Neotree focus git_status left<CR>",                                 desc = "Focus Git" },
  { "<leader>es",  "<cmd>Neotree focus document_symbols left<CR>",                           desc = "Focus Symbols" },
  { "<leader>en",  "<C-w>w",                                                                 desc = "Cycle windows" },
  { "<leader>et",  function() Snacks.terminal() end,                                         desc = "Toggle Terminal" },

  { "<leader>q",   group = "Session" },
  { "<leader>qq",  "<cmd>qa!<CR>",                                                           desc = "Quit without saving" },
  { "<leader>qwq", "<cmd>wa<CR><cmd>qa<CR>",                                                 desc = "Save all and quit" },

  { "<leader>t",   group = "Timer" },
  { "<leader>ts",  group = "Session" },
  { "<leader>ts2", "<cmd>TimerSession default2h<CR>",                                        desc = "2h focus" },
  { "<leader>ts1", "<cmd>TimerSession default1h<CR>",                                        desc = "1h focus" },
  { "<leader>tsr", "<cmd>TimerSession rest<CR>",                                             desc = "Rest" },
  { "<leader>tt",  group = "Timer" },
  { "<leader>tts", "<cmd>TimerStop<CR>",                                                     desc = "Stop" },
  { "<leader>ttp", "<cmd>TimerPause<CR>",                                                    desc = "Pause" },
  { "<leader>ttr", "<cmd>TimerResume<CR>",                                                   desc = "Resume" },
  {
    "<leader>ttc",
    function()
      vim.ui.input({ prompt = 'Minutes: ' }, function(m)
        if m then vim.cmd('TimerStart ' .. m) end
      end)
    end,
    desc = "Custom"
  },

  { "<leader>p",   group = "Pickers" },
  -- Files
  { "<leader>pf",  function() Snacks.picker.files() end,                                                     desc = "Files" },
  { "<leader>pr",  function() Snacks.picker.recent() end,                                                    desc = "Recent files" },
  { "<leader>ps",  function() Snacks.picker.smart() end,                                                     desc = "Smart find" },
  { "<leader>pb",  function() Snacks.picker.buffers() end,                                                   desc = "Buffers" },
  { "<leader>pp",  function() Snacks.picker.projects() end,                                                  desc = "Projects" },
  { "<leader>pe",  function() Snacks.picker.explorer({ layout = { layout = { preset = "explorer" } } }) end, desc = "Explorer" },
  { "<leader>pz",  function() Snacks.picker.zoxide() end,                                                    desc = "Zoxide dirs" },
  -- Search
  { "<leader>pg",  function() Snacks.picker.grep() end,                                                      desc = "Grep" },
  { "<leader>pG",  function() Snacks.picker.grep_buffers() end,                                              desc = "Grep buffers" },
  { "<leader>pw",  function() Snacks.picker.grep_word() end,                                                 desc = "Grep word",      mode = { "n", "x" } },
  { "<leader>pl",  function() Snacks.picker.lines() end,                                                     desc = "Buffer lines" },
  -- Git
  { "<leader>pv",  group = "Git" },
  { "<leader>pvs", function() Snacks.picker.git_status() end,                                                desc = "Status" },
  { "<leader>pvb", function() Snacks.picker.git_branches() end,                                              desc = "Branches" },
  { "<leader>pvl", function() Snacks.picker.git_log() end,                                                   desc = "Log" },
  { "<leader>pvf", function() Snacks.picker.git_log_file() end,                                              desc = "File log" },
  { "<leader>pvS", function() Snacks.picker.git_stash() end,                                                 desc = "Stash" },
  { "<leader>pvd", function() Snacks.picker.git_diff() end,                                                  desc = "Diff" },
  -- Neovim
  { "<leader>pn",  group = "Neovim" },
  { "<leader>pnc", function() Snacks.picker.commands() end,                                                  desc = "Commands" },
  { "<leader>pnh", function() Snacks.picker.command_history() end,                                           desc = "Command history" },
  { "<leader>pns", function() Snacks.picker.search_history() end,                                            desc = "Search history" },
  { "<leader>pnk", function() Snacks.picker.keymaps() end,                                                   desc = "Keymaps" },
  { "<leader>pna", function() Snacks.picker.autocmds() end,                                                  desc = "Autocmds" },
  { "<leader>pnH", function() Snacks.picker.highlights() end,                                                desc = "Highlights" },
  { "<leader>pnC", function() Snacks.picker.colorschemes() end,                                              desc = "Colorschemes" },
  { "<leader>pno", function() Snacks.picker.options() end,                                                   desc = "Options" },
  -- Help
  { "<leader>ph",  group = "Help" },
  { "<leader>phh", function() Snacks.picker.help() end,                                                      desc = "Help tags" },
  { "<leader>phm", function() Snacks.picker.man() end,                                                       desc = "Man pages" },
  -- Navigation
  { "<leader>pm",  function() Snacks.picker.marks() end,                                                     desc = "Marks" },
  { "<leader>p'",  function() Snacks.picker.registers() end,                                                 desc = "Registers" },
  { "<leader>pj",  function() Snacks.picker.jumps() end,                                                     desc = "Jumps" },
  { "<leader>pq",  function() Snacks.picker.qflist() end,                                                    desc = "Quickfix" },
  { "<leader>pL",  function() Snacks.picker.loclist() end,                                                   desc = "Location list" },
  -- Misc
  { "<leader>pu",  function() Snacks.picker.undo() end,                                                      desc = "Undo history" },
  { "<leader>pi",  function() Snacks.picker.icons() end,                                                     desc = "Icons" },
  { "<leader>pS",  function() Snacks.picker.spelling() end,                                                  desc = "Spelling" },
  { "<leader>pN",  function() Snacks.picker.notifications() end,                                             desc = "Notifications" },
  { "<leader>pY",  function() Snacks.picker.lazy() end,                                                      desc = "Lazy plugins" },
  { "<leader>p.",  function() Snacks.picker.resume() end,                                                    desc = "Resume last" },

  { "<leader>u",   group = "UI" },
  { "<leader>uw",  desc = "Toggle line wrap" },


  {"<leader>rr", desc = "Insert return statement" },
})

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "OptionSet" }, {
  group = vim.api.nvim_create_augroup("WhichKeyDiffOnly", { clear = true }),
  pattern = { "*", "diff" }, -- OptionSet needs "diff"
  callback = function(ev)
    -- window-local option
    if vim.wo.diff then
      wk.add({
        { "<leader>d",   group = "Diff" },
        { "<leader>dgt", "<cmd>diffget 2<CR>", desc = "Get from left" },
        { "<leader>dgo", "<cmd>diffget 3<CR>", desc = "Get from right" },
        { "<leader>dpt", "<cmd>diffput 2<CR>", desc = "Put to main" },
      })
    else
      -- optional: remove the mapping from this buffer when not in diff
      pcall(wk.unregister, "<leader>d", { buffer = ev.buf })
    end
  end,
})


vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('LspKeymaps', { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then return end

    local bufnr = ev.buf
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { desc = desc })
    end

    map("n", "gd", function() Snacks.picker.lsp_definitions() end, "Go to definition")
    map("n", "gr", function() Snacks.picker.lsp_references() end, "References")
    map("n", "gi", function() Snacks.picker.lsp_implementations() end, "Implementations")
    map("n", "gy", function() Snacks.picker.lsp_type_definitions() end, "Type definition")
    map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
    map("n", "gci", function() Snacks.picker.lsp_incoming_calls() end, "Incoming calls")
    map("n", "gco", function() Snacks.picker.lsp_outgoing_calls() end, "Outgoing calls")

    map("n", "K", function()
      vim.lsp.buf.hover({ border = "rounded", max_width = 80 })
    end, "Hover")
    map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature help")

    map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("v", "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
    map("n", "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, "Format")
    map("n", "<leader>cl", vim.lsp.codelens.run, "Run codelens")
    map("n", "<leader>cL", vim.lsp.codelens.refresh, "Refresh codelens")
    map("n", "<leader>ch", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
    end, "Toggle inlay hints")
    map("n", "<leader>csd", function() Snacks.picker.lsp_symbols() end, "Document symbols")
    map("n", "<leader>csw", function() Snacks.picker.lsp_workspace_symbols() end, "Workspace symbols")

    map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
    map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
    map("n", "<leader>ld", vim.diagnostic.open_float, "Line diagnostics")
    map("n", "<leader>lb", function() Snacks.picker.diagnostics_buffer() end, "Buffer diagnostics")
    map("n", "<leader>lw", function() Snacks.picker.diagnostics() end, "Workspace diagnostics")

    if client.name == 'ts_ls' or client.name == 'svelte' or client.name == 'vue_ls' then
      vim.api.nvim_buf_create_user_command(bufnr, 'LspSourceAction', function()
        vim.lsp.buf.code_action({ context = { only = { 'source' } } })
      end, { desc = "Source actions (organize imports, etc.)" })
      map("n", "<leader>co", "<cmd>LspSourceAction<CR>", "Organize imports")
    end
  end,
})

-- Clipboard keymaps (explicit system clipboard access)
vim.keymap.set('n', 'ytc', '"+y', { desc = "Yank to clipboard" })
vim.keymap.set('v', 'ytc', '"+y', { desc = "Yank to clipboard" })
vim.keymap.set('n', 'pfc', '"+p', { desc = "Paste from clipboard" })
vim.keymap.set('v', 'pfc', '"+p', { desc = "Paste from clipboard" })

-- Toggle wrap mode
vim.keymap.set('n', '<leader>uw', function()
  vim.wo.wrap = not vim.wo.wrap
  local status = vim.wo.wrap and 'enabled' or 'disabled'
  vim.notify('Wrap ' .. status, vim.log.levels.INFO)
end, { desc = 'Toggle line wrap' })

vim.keymap.set('n', '<leader>rr', function()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row + 1, false, { "return" })
end, { desc = "Insert return statement" })
