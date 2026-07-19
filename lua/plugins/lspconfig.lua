return {
  {
    "SmiteshP/nvim-navic",
    lazy = true,
    config = function()
      require("nvim-navic").setup({ highlight = true })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "SmiteshP/nvim-navic",
      "saghen/blink.cmp",
    },
    config = function()
      -- Build maximum capabilities by merging native + blink.cmp
      local capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        require('blink.cmp').get_lsp_capabilities()
      )

      -- Enable all textDocument capabilities
      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      }
      capabilities.textDocument.completion.completionItem = {
        documentationFormat = { "markdown", "plaintext" },
        snippetSupport = true,
        preselectSupport = true,
        insertReplaceSupport = true,
        labelDetailsSupport = true,
        deprecatedSupport = true,
        commitCharactersSupport = true,
        tagSupport = { valueSet = { 1 } },
        resolveSupport = {
          properties = {
            "documentation",
            "detail",
            "additionalTextEdits",
          },
        },
      }
      capabilities.textDocument.semanticTokens = {
        dynamicRegistration = false,
        tokenTypes = {
          "namespace", "type", "class", "enum", "interface", "struct",
          "typeParameter", "parameter", "variable", "property", "enumMember",
          "event", "function", "method", "macro", "keyword", "modifier",
          "comment", "string", "number", "regexp", "operator", "decorator",
        },
        tokenModifiers = {
          "declaration", "definition", "readonly", "static", "deprecated",
          "abstract", "async", "modification", "documentation", "defaultLibrary",
        },
        formats = { "relative" },
        requests = {
          range = true,
          full = { delta = true },
        },
        multilineTokenSupport = true,
        overlappingTokenSupport = true,
      }
      capabilities.textDocument.inlayHint = {
        dynamicRegistration = true,
        resolveSupport = {
          properties = { "tooltip", "textEdits", "label.tooltip", "label.location", "label.command" },
        },
      }
      capabilities.textDocument.codeLens = { dynamicRegistration = false }
      capabilities.textDocument.codeAction = {
        dynamicRegistration = true,
        codeActionLiteralSupport = {
          codeActionKind = {
            valueSet = {
              "", "quickfix", "refactor", "refactor.extract", "refactor.inline",
              "refactor.rewrite", "source", "source.organizeImports", "source.fixAll",
            },
          },
        },
        resolveSupport = { properties = { "edit" } },
        dataSupport = true,
        isPreferredSupport = true,
        disabledSupport = true,
      }
      capabilities.textDocument.callHierarchy = { dynamicRegistration = true }
      capabilities.textDocument.typeHierarchy = { dynamicRegistration = true }
      capabilities.textDocument.documentLink = { dynamicRegistration = true, tooltipSupport = true }
      capabilities.workspace = capabilities.workspace or {}
      capabilities.workspace.didChangeWatchedFiles = { dynamicRegistration = true }
      capabilities.workspace.workspaceFolders = true
      capabilities.workspace.configuration = true

      -- Global diagnostic configuration
      vim.diagnostic.config({
        virtual_text = false,
        float = {
          source = "always",
          border = "rounded",
          header = "",
          prefix = "",
          focusable = false,
          style = "minimal",
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      vim.lsp.config('*', {
        capabilities = capabilities,
        root_markers = { '.git' },
      })

      vim.lsp.handlers['textDocument/codeLens'] = vim.lsp.codelens.on_codelens

      vim.lsp.config('solargraph', {
        cmd = { 'solargraph', 'stdio' },
        filetypes = { 'sonicpi' },
        root_markers = { 'Gemfile', '.ruby-version', '.git' },
        settings = {
          solargraph = {
            diagnostics = true,
            folding = true,
            completion = true,
            symbols = true,
            definitions = true,
            references = true,
            rename = true,
            hover = true,
            formatting = true,
          },
        },
      })

      vim.lsp.config('ruby_lsp', {
        cmd = { "ruby-lsp" },
        filetypes = { 'ruby', 'eruby' },
        root_markers = { 'Gemfile', '.ruby-version', '.git' },
        init_options = {
          formatter = 'standard',
          linters = { 'standard' },
          enabledFeatures = {
            "codeActions",
            "codeLens",
            "completion",
            "definition",
            "diagnostics",
            "documentHighlights",
            "documentLink",
            "documentSymbols",
            "foldingRanges",
            "formatting",
            "hover",
            "inlayHint",
            "onTypeFormatting",
            "selectionRanges",
            "semanticHighlighting",
            "signatureHelp",
            "typeHierarchy",
            "workspaceSymbol",
          },
        },
      })

      vim.lsp.config('lua_ls', {
        cmd = { 'lua-language-server' },
        filetypes = { 'lua' },
        root_markers = { '.luarc.json', '.luarc.jsonc', '.luacheckrc', '.stylua.toml', 'stylua.toml', 'selene.toml', 'selene.yml', '.git' },
        settings = {
          Lua = {
            runtime = { version = 'LuaJIT' },
            workspace = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file("", true),
            },
            completion = {
              callSnippet = 'Replace',
              displayContext = 5,
              keywordSnippet = 'Replace',
            },
            diagnostics = {
              globals = { 'vim', 'Snacks' },
              neededFileStatus = { ['codestyle-check'] = 'Any' },
            },
            hint = {
              enable = true,
              arrayIndex = 'Enable',
              await = true,
              paramName = 'All',
              paramType = true,
              semicolon = 'SameLine',
              setType = true,
            },
            codeLens = { enable = true },
            semantic = { enable = true },
            format = { enable = true },
            telemetry = { enable = false },
          },
        },
      })

      vim.lsp.config('gopls', {
        cmd = { 'gopls' },
        filetypes = { 'go', 'gomod', 'gowork', 'gotmpl', 'tmpl' },
        root_markers = { 'go.work', 'go.mod', '.git' },
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
              shadow = true,
              nilness = true,
              unusedwrite = true,
              useany = true,
              unusedvariable = true,
            },
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
            codelenses = {
              gc_details = true,
              generate = true,
              regenerate_cgo = true,
              run_govulncheck = true,
              test = true,
              tidy = true,
              upgrade_dependency = true,
              vendor = true,
            },
            semanticTokens = true,
            staticcheck = true,
            gofumpt = true,
            usePlaceholders = true,
            completeUnimported = true,
            directoryFilters = { "-.git", "-.vscode", "-.idea", "-node_modules" },
          },
        },
      })

      vim.lsp.config('ts_ls', {
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = { 'javascript', 'javascriptreact', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx' },
        root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
        init_options = { hostInfo = 'neovim' },
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = 'all',
              includeInlayParameterNameHintsWhenArgumentMatchesName = true,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayVariableTypeHintsWhenTypeMatchesName = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
            suggest = { completeFunctionCalls = true },
            updateImportsOnFileMove = { enabled = 'always' },
          },
          javascript = {
            inlayHints = {
              includeInlayParameterNameHints = 'all',
              includeInlayParameterNameHintsWhenArgumentMatchesName = true,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayVariableTypeHintsWhenTypeMatchesName = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
            suggest = { completeFunctionCalls = true },
            updateImportsOnFileMove = { enabled = 'always' },
          },
          completions = { completeFunctionCalls = true },
        },
      })

      vim.lsp.config('svelte', {
        cmd = { "svelteserver", "--stdio" },
        filetypes = { "svelte" },
        root_markers = { 'svelte.config.js', 'svelte.config.cjs', 'svelte.config.mjs', 'package.json', '.git' },
        settings = {
          svelte = {
            plugin = {
              svelte = {
                compilerWarnings = {},
                format = { enable = true },
              },
            },
            ['enable-ts-plugin'] = true,
          },
          typescript = {
            inlayHints = {
              parameterNames = { enabled = 'all' },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              enumMemberValues = { enabled = true },
            },
          },
        },
      })

      vim.lsp.config('vue_ls', {
        cmd = { 'vue-language-server', '--stdio' },
        filetypes = { 'vue' },
        root_markers = { 'vue.config.js', 'vue.config.ts', 'nuxt.config.js', 'nuxt.config.ts', 'package.json', '.git' },
        init_options = {
          typescript = { tsdk = '' },
          vue = { hybridMode = false },
        },
        settings = {
          vue = {
            inlayHints = {
              inlineHandlerLeading = true,
              missingProps = true,
              optionsWrapper = true,
              vBindShorthand = true,
            },
            complete = {
              casing = { status = true, props = 'autoCamel', tags = 'autoPascal' },
            },
          },
        },
        on_new_config = function(new_config, new_root_dir)
          local lib_path = vim.fs.find('node_modules/typescript/lib', { path = new_root_dir, upward = true })[1]
          if lib_path then
            new_config.init_options.typescript.tsdk = lib_path
          end
        end,
      })

      vim.lsp.config('pyright', {
        cmd = { 'pyright-langserver', '--stdio' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', 'pyrightconfig.json', '.git' },
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = 'openFilesOnly',
              typeCheckingMode = 'standard',
              autoImportCompletions = true,
              inlayHints = {
                variableTypes = true,
                functionReturnTypes = true,
                callArgumentNames = true,
                pytestParameters = true,
              },
            },
          },
        },
      })
      vim.lsp.config('rubocop', {
        cmd = { 'rubocop', '--lsp' },
        filetypes = { 'ruby', 'eruby' },
        root_markers = { '.rubocop.yml', 'Gemfile', '.git' },
      })

      local tidalhelp_candidates = {
        vim.fn.expand('~/work/tidalhelp/.worktrees/lsp-server/bin/tidalhelp'),
        vim.fn.expand('~/work/tidalhelp/bin/tidalhelp'),
      }
      local tidalhelp_cmd = 'tidalhelp'
      for _, candidate in ipairs(tidalhelp_candidates) do
        if vim.fn.executable(candidate) == 1 then
          tidalhelp_cmd = candidate
          break
        end
      end

      vim.lsp.config('tidalhelp_lsp', {
        cmd = { tidalhelp_cmd, '--lsp' },
        filetypes = { 'tidal' },
        root_markers = { '.git' },
      })

      vim.lsp.enable({
        'ruby_lsp',
        'solargraph',
        'lua_ls',
        'gopls',
        'ts_ls',
        'svelte',
        'vue_ls',
        'pyright',
        'rubocop',
        'tidalhelp_lsp',
      })

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('LspAutoFeatures', { clear = true }),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if not client then return end

          require('sonicpi').lsp_on_init(client, { server_dir = "/Applications/Sonic Pi.app/Contents/Resources/app/server"})

          local bufnr = ev.buf
          vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'

          if client:supports_method('textDocument/inlayHint') then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
          end

          if client:supports_method('textDocument/codeLens') then
            local function refresh_codelens(buf)
              vim.lsp.codelens.refresh({ bufnr = buf })
              vim.defer_fn(function()
                local ok, lenses = pcall(vim.lsp.codelens.get, buf)
                if not ok or not lenses or #lenses == 0 then return end
                for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
                  if c:supports_method('textDocument/codeLens') then
                    pcall(vim.lsp.codelens.display, lenses, buf, c.id)
                  end
                end
              end, 120)
            end

            local function run_tidal_eval_lens(buf)
              local unicode_fraction = {
                ['⅛'] = 1 / 8, ['¼'] = 1 / 4, ['⅜'] = 3 / 8, ['½'] = 1 / 2,
                ['⅝'] = 5 / 8, ['¾'] = 3 / 4, ['⅞'] = 7 / 8,
                ['⅓'] = 1 / 3, ['⅔'] = 2 / 3,
                ['⅕'] = 1 / 5, ['⅖'] = 2 / 5, ['⅗'] = 3 / 5, ['⅘'] = 4 / 5,
                ['⅙'] = 1 / 6, ['⅚'] = 5 / 6,
              }

              local function parse_time_token(tok)
                if type(tok) ~= 'string' then return nil end
                tok = vim.trim(tok)
                if tok == '' then return nil end
                if unicode_fraction[tok] then
                  return unicode_fraction[tok]
                end
                local n, d = tok:match('^(%-?%d+)%/(%-?%d+)$')
                if n and d and tonumber(d) and tonumber(d) ~= 0 then
                  return tonumber(n) / tonumber(d)
                end
                return tonumber(tok)
              end

              local function parse_event_row(row)
                if type(row) ~= 'string' then return nil end
                local start_s, end_s, payload = row:match('^%(([^>]+)>([^)]+)%)%|(.+)$')
                if not start_s or not end_s or not payload then return nil end
                local start_v = parse_time_token(start_s)
                local end_v = parse_time_token(end_s)
                if not start_v or not end_v then return nil end

                local label = payload:match('n:%s*[^%(]*%(([^%)]+)%)')
                if not label then
                  label = payload:match('s:%s*"([^"]+)"')
                end
                if not label then
                  label = payload:match('^%s*([^,]+)')
                end
                label = label or 'event'
                return { start = start_v, ['end'] = end_v, label = label }
              end

              local function parse_event_payload(payload)
                if type(payload) ~= 'table' then return {} end
                local raw = payload.events
                if type(raw) ~= 'table' then return {} end

                local events = {}
                for _, ev in ipairs(raw) do
                  if type(ev) == 'table' then
                    local s = tonumber(ev.start)
                    local e = tonumber(ev['end'])
                    local v = ev.value
                    if s and e and v then
                      events[#events + 1] = {
                        start = s,
                        ['end'] = e,
                        label = tostring(v),
                      }
                    end
                  end
                end
                return events
              end

              local function extract_cycle_note_groups(expr)
                if type(expr) ~= 'string' or expr == '' then return nil end
                local quoted = expr:match('n%s*"([^"]+)"')
                if not quoted then return nil end
                if not (quoted:sub(1, 1) == '<' and quoted:sub(-1) == '>') then return nil end

                local inner = quoted:sub(2, -2)
                local groups = {}
                local buf = {}
                local depth_sq = 0

                for i = 1, #inner do
                  local ch = inner:sub(i, i)
                  if ch == '[' then depth_sq = depth_sq + 1 end
                  if ch == ']' and depth_sq > 0 then depth_sq = depth_sq - 1 end

                  if ch == ' ' and depth_sq == 0 then
                    local seg = table.concat(buf)
                    if seg ~= '' then groups[#groups + 1] = seg end
                    buf = {}
                  else
                    buf[#buf + 1] = ch
                  end
                end

                local seg = table.concat(buf)
                if seg ~= '' then groups[#groups + 1] = seg end
                if #groups == 0 then return nil end

                local out = {}
                for _, g in ipairs(groups) do
                  if not g:find(',') then
                    goto continue_group
                  end

                  local notes = {}
                  for n in g:gmatch('[a-gA-G][b#]?%d') do
                    notes[#notes + 1] = n:lower()
                  end
                  if #notes > 0 then
                    out[#out + 1] = notes
                  end
                  ::continue_group::
                end
                if #out == 0 then return nil end
                return out
              end

              local function build_visual_lines(events, track_label, cycles, expr)
                if #events == 0 then return nil end

                table.sort(events, function(a, b)
                  return (a.start or 0) < (b.start or 0)
                end)

                local total_cycles = tonumber(cycles) or 1
                if total_cycles < 1 then total_cycles = 1 end
                local steps_per_cycle = 16
                local src_groups = extract_cycle_note_groups(expr)
                if src_groups and #src_groups > total_cycles then
                  total_cycles = #src_groups
                end

                local function normalize_note_name(n)
                  if type(n) ~= 'string' then return nil end
                  local l, acc, oct = n:match('^([a-gA-G])([b#]?)(%-?%d+)$')
                  if not l then return nil end
                  return string.upper(l) .. acc, tonumber(oct)
                end

                local function pitch_class(name)
                  local map = {
                    C = 0, ['C#'] = 1, Db = 1,
                    D = 2, ['D#'] = 3, Eb = 3,
                    E = 4,
                    F = 5, ['F#'] = 6, Gb = 6,
                    G = 7, ['G#'] = 8, Ab = 8,
                    A = 9, ['A#'] = 10, Bb = 10,
                    B = 11,
                  }
                  return map[name]
                end

                local function detect_chord_name(notes)
                  if type(notes) ~= 'table' or #notes < 3 then return nil end

                  local first_name, first_oct = normalize_note_name(notes[1])
                  local first_pc = first_name and pitch_class(first_name) or nil

                  local pcs = {}
                  local uniq = {}
                  for _, n in ipairs(notes) do
                    local nn = normalize_note_name(n)
                    local pc = nn and pitch_class(nn)
                    if pc ~= nil and not uniq[pc] then
                      uniq[pc] = true
                      pcs[#pcs + 1] = pc
                    end
                  end
                  if #pcs < 3 then return nil end

                  local templates4 = {
                    { iv = { 0, 3, 6, 10 }, suffix = 'm7b5' },
                    { iv = { 0, 3, 6, 9 }, suffix = 'dim7' },
                    { iv = { 0, 3, 7, 10 }, suffix = 'm7' },
                    { iv = { 0, 4, 7, 11 }, suffix = 'maj7' },
                    { iv = { 0, 4, 7, 10 }, suffix = '7' },
                  }

                  local templates3 = {
                    { iv = { 0, 4, 7 }, suffix = 'maj' },
                    { iv = { 0, 3, 7 }, suffix = 'm' },
                    { iv = { 0, 3, 6 }, suffix = 'dim' },
                    { iv = { 0, 4, 8 }, suffix = 'aug' },
                    { iv = { 0, 2, 7 }, suffix = 'sus2' },
                    { iv = { 0, 5, 7 }, suffix = 'sus4' },
                  }

                  local names = { 'C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B' }

                  local function match_for_root(root_pc)
                    local set = {}
                    for _, p in ipairs(pcs) do
                      set[(p - root_pc) % 12] = true
                    end

                    local function match_list(list)
                      for _, t in ipairs(list) do
                        local ok = true
                        for _, iv in ipairs(t.iv) do
                          if not set[iv] then ok = false break end
                        end
                        if ok then return t.suffix end
                      end
                      return nil
                    end

                    if #pcs >= 4 then
                      local s4 = match_list(templates4)
                      if s4 then return s4 end
                    end

                    return match_list(templates3)
                  end

                  if first_pc ~= nil then
                    local sfx = match_for_root(first_pc)
                    if sfx then
                      if first_oct ~= nil then
                        return names[first_pc + 1] .. tostring(first_oct) .. sfx
                      end
                      return names[first_pc + 1] .. sfx
                    end
                  end

                  for root_pc = 0, 11 do
                    local sfx = match_for_root(root_pc)
                    if sfx then
                      return names[root_pc + 1] .. sfx
                    end
                  end

                  return nil
                end

                local function short_label(lbl)
                  lbl = tostring(lbl or 'ev')
                  if #lbl <= 4 then return lbl end
                  return lbl:sub(1, 4)
                end

                local function dots_for_gap(gap)
                  local n = math.max(0, math.floor(gap * steps_per_cycle + 0.5))
                  if n == 0 then return '' end
                  return string.rep('·', n)
                end

                local function bars_for_duration(dur)
                  local n = math.max(1, math.floor(dur * steps_per_cycle + 0.5))
                  return string.rep('▪', n)
                end

                local cycle_lines = {}
                for c = 0, total_cycles - 1 do
                  if src_groups and #src_groups > 0 then
                    local notes = src_groups[(c % #src_groups) + 1]
                    local chord = '[' .. table.concat(notes, ' + ') .. ']'
                    local chord_name = detect_chord_name(notes)
                    local line = chord
                    if chord_name then
                      line = line .. ' => ' .. chord_name
                    end
                    line = line .. '▪'
                    cycle_lines[#cycle_lines + 1] = ('timeline c%d: %s'):format(c + 1, line)
                    goto continue_cycle
                  end

                  local cycle_start = c
                  local cycle_end = c + 1
                  local cursor = cycle_start
                  local parts = {}

                  for _, ev in ipairs(events) do
                    local s = ev.start or 0
                    local e = ev['end'] or s
                    if e <= cycle_start or s >= cycle_end then
                      goto continue
                    end

                    local seg_start = math.max(s, cycle_start)
                    local seg_end = math.min(e, cycle_end)
                    if seg_end <= seg_start then
                      goto continue
                    end

                    if seg_start > cursor then
                      parts[#parts + 1] = dots_for_gap(seg_start - cursor)
                    end

                    parts[#parts + 1] = short_label(ev.label) .. bars_for_duration(seg_end - seg_start)
                    cursor = math.max(cursor, seg_end)

                    ::continue::
                  end

                  if cursor < cycle_end then
                    parts[#parts + 1] = dots_for_gap(cycle_end - cursor)
                  end

                  local line = table.concat(parts)
                  if line == '' then line = '·' end
                  cycle_lines[#cycle_lines + 1] = ('timeline c%d: %s'):format(c + 1, line)
                  ::continue_cycle::
                end

                local labels = {}
                if src_groups and #src_groups > 0 then
                  for _, grp in ipairs(src_groups) do
                    for _, n in ipairs(grp) do labels[short_label(n)] = true end
                  end
                else
                  for _, ev in ipairs(events) do labels[short_label(ev.label)] = true end
                end
                local label_list = {}
                for k, _ in pairs(labels) do label_list[#label_list + 1] = k end
                table.sort(label_list)

                local content = { '● ' .. track_label }
                for _, line in ipairs(cycle_lines) do content[#content + 1] = line end
                if src_groups and #src_groups > 0 then
                  content[#content + 1] = 'keys: [a + b + c] chord notes play together, ▪ active chord'
                else
                  content[#content + 1] = 'keys: · rest, ▪ sustain'
                end
                content[#content + 1] = 'events: ' .. table.concat(label_list, ', ')

                local max_len = 0
                for _, line in ipairs(content) do
                  max_len = math.max(max_len, vim.fn.strdisplaywidth(line))
                end

                local top = '╭' .. string.rep('─', max_len + 2) .. '╮'
                local bot = '╰' .. string.rep('─', max_len + 2) .. '╯'
                local boxed = { top }
                for _, line in ipairs(content) do
                  local pad = string.rep(' ', max_len - vim.fn.strdisplaywidth(line))
                  table.insert(boxed, '│ ' .. line .. pad .. ' │')
                end
                table.insert(boxed, bot)
                return boxed
              end

              local function format_eval_message(payload, track_label)
                if type(payload) ~= 'table' then
                  return { tostring(payload) }, vim.log.levels.INFO
                end

                if payload.error then
                  local parts = { 'Evaluation failed' }
                  if payload.detail and payload.detail ~= '' then
                    table.insert(parts, payload.detail)
                  end
                  if payload.expr and payload.expr ~= '' then
                    table.insert(parts, 'expr: ' .. payload.expr)
                  end
                  return parts, vim.log.levels.ERROR
                end

                local expr = payload.expr or ''
                local rows = payload.result
                local lines = {}
                local events = parse_event_payload(payload)
                local cycles = payload.cycles
                local insights = type(payload.insights) == 'table' and payload.insights or {}

                local function trim(s)
                  return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', ''))
                end

                local function parse_signature(sig)
                  local raw = trim(sig)
                  if raw == '' then
                    return {}, ''
                  end
                  local rhs = raw:match('::%s*(.+)$') or raw
                  local parts = vim.split(rhs, '->', { plain = true })
                  local cleaned = {}
                  for _, p in ipairs(parts) do
                    local t = trim(p)
                    if t ~= '' then
                      table.insert(cleaned, t)
                    end
                  end
                  if #cleaned <= 1 then
                    return cleaned, ''
                  end
                  local returns = cleaned[#cleaned]
                  table.remove(cleaned, #cleaned)
                  return cleaned, returns
                end

                local function split_top_level_args(arg_text)
                  local s = tostring(arg_text or '')
                  local out = {}
                  local cur = {}
                  local in_string = false
                  local escape = false
                  local depth_paren = 0
                  local depth_square = 0
                  local depth_brace = 0

                  local function flush()
                    if #cur == 0 then return end
                    local token = trim(table.concat(cur))
                    if token ~= '' then
                      table.insert(out, token)
                    end
                    cur = {}
                  end

                  for i = 1, #s do
                    local ch = s:sub(i, i)
                    if in_string then
                      table.insert(cur, ch)
                      if escape then
                        escape = false
                      elseif ch == '\\' then
                        escape = true
                      elseif ch == '"' then
                        in_string = false
                      end
                    else
                      if ch == '"' then
                        in_string = true
                        table.insert(cur, ch)
                      elseif ch == '(' then
                        depth_paren = depth_paren + 1
                        table.insert(cur, ch)
                      elseif ch == ')' then
                        depth_paren = math.max(0, depth_paren - 1)
                        table.insert(cur, ch)
                      elseif ch == '[' then
                        depth_square = depth_square + 1
                        table.insert(cur, ch)
                      elseif ch == ']' then
                        depth_square = math.max(0, depth_square - 1)
                        table.insert(cur, ch)
                      elseif ch == '{' then
                        depth_brace = depth_brace + 1
                        table.insert(cur, ch)
                      elseif ch == '}' then
                        depth_brace = math.max(0, depth_brace - 1)
                        table.insert(cur, ch)
                      elseif (ch == ' ' or ch == '\t') and depth_paren == 0 and depth_square == 0 and depth_brace == 0 then
                        flush()
                      else
                        table.insert(cur, ch)
                      end
                    end
                  end

                  flush()
                  return out
                end

                local function arg_labels_for(fn)
                  local labels = {
                    echo = { 'repeats', 'delay', 'feedback' },
                    note = { 'notes/pitches' },
                    sustain = { 'duration' },
                    attack = { 'time' },
                    release = { 'time' },
                    lpf = { 'cutoff' },
                    resonance = { 'Q / resonance' },
                  }
                  return labels[fn]
                end

                local function compact_type_name(t)
                  local x = trim(t)
                  x = x:gsub('^Pattern%s+', 'P:')
                  x = x:gsub('^ControlPattern$', 'Ctrl')
                  x = x:gsub('^Pattern%s*', 'P:')
                  x = x:gsub('^P:Integer$', 'P:Int')
                  x = x:gsub('^P:Rational$', 'P:Rat')
                  x = x:gsub('^P:Double$', 'P:Dbl')
                  x = x:gsub('^P:String$', 'P:Str')
                  return x
                end

                local function compact_annotations(fn, arg_tokens, params, arg_labels)
                  if #arg_tokens == 0 or #params == 0 then
                    return ''
                  end
                  local out = {}
                  local count = math.min(#arg_tokens, #params)
                  for idx = 1, count do
                    local arg = trim(arg_tokens[idx])
                    local typ = compact_type_name(params[idx])
                    local label = ''
                    if type(arg_labels) == 'table' and arg_labels[idx] then
                      label = ' ' .. arg_labels[idx]
                    end
                    table.insert(out, string.format('%s:%s%s', arg, typ, label))
                  end
                  if #arg_tokens > count then
                    for idx = count + 1, #arg_tokens do
                      table.insert(out, trim(arg_tokens[idx]) .. ':extra')
                    end
                  end
                  return table.concat(out, ', ')
                end

                local function strip_outer_parens(s)
                  local t = trim(s)
                  while #t >= 2 and t:sub(1, 1) == '(' and t:sub(#t, #t) == ')' do
                    local depth = 0
                    local in_string = false
                    local escape = false
                    local ok = true
                    for i = 1, #t do
                      local ch = t:sub(i, i)
                      if in_string then
                        if escape then
                          escape = false
                        elseif ch == '\\' then
                          escape = true
                        elseif ch == '"' then
                          in_string = false
                        end
                      else
                        if ch == '"' then
                          in_string = true
                        elseif ch == '(' then
                          depth = depth + 1
                        elseif ch == ')' then
                          depth = depth - 1
                          if depth == 0 and i < #t then
                            ok = false
                            break
                          end
                        end
                      end
                    end
                    if not ok or depth ~= 0 then break end
                    t = trim(t:sub(2, #t - 1))
                  end
                  return t
                end

                local function split_top_level_by_dollar(s)
                  local out = {}
                  local cur = {}
                  local in_string = false
                  local escape = false
                  local depth_paren, depth_square, depth_brace = 0, 0, 0

                  local function flush()
                    local tok = trim(table.concat(cur))
                    if tok ~= '' then table.insert(out, tok) end
                    cur = {}
                  end

                  for i = 1, #s do
                    local ch = s:sub(i, i)
                    if in_string then
                      table.insert(cur, ch)
                      if escape then
                        escape = false
                      elseif ch == '\\' then
                        escape = true
                      elseif ch == '"' then
                        in_string = false
                      end
                    else
                      if ch == '"' then
                        in_string = true
                        table.insert(cur, ch)
                      elseif ch == '(' then
                        depth_paren = depth_paren + 1
                        table.insert(cur, ch)
                      elseif ch == ')' then
                        depth_paren = math.max(0, depth_paren - 1)
                        table.insert(cur, ch)
                      elseif ch == '[' then
                        depth_square = depth_square + 1
                        table.insert(cur, ch)
                      elseif ch == ']' then
                        depth_square = math.max(0, depth_square - 1)
                        table.insert(cur, ch)
                      elseif ch == '{' then
                        depth_brace = depth_brace + 1
                        table.insert(cur, ch)
                      elseif ch == '}' then
                        depth_brace = math.max(0, depth_brace - 1)
                        table.insert(cur, ch)
                      elseif ch == '$' and depth_paren == 0 and depth_square == 0 and depth_brace == 0 then
                        flush()
                      else
                        table.insert(cur, ch)
                      end
                    end
                  end

                  flush()
                  return out
                end

                local function parse_nested_call(segment)
                  local tokens = split_top_level_args(segment)
                  if #tokens == 0 then return nil end
                  local fn = tokens[1]
                  local argv = {}
                  for i = 2, #tokens do table.insert(argv, tokens[i]) end

                  local role_labels = {
                    slow = { 'cycles' },
                    fast = { 'cycles' },
                    range = { 'min', 'max', 'shape' },
                  }
                  local labels = role_labels[fn]

                  local rendered = {}
                  for i, a in ipairs(argv) do
                    if type(labels) == 'table' and labels[i] then
                      table.insert(rendered, labels[i] .. '=' .. a)
                    else
                      table.insert(rendered, a)
                    end
                  end

                  local pretty = fn
                  if #rendered > 0 then
                    pretty = fn .. '(' .. table.concat(rendered, ', ') .. ')'
                  end
                  return { fn = fn, args = argv, pretty = pretty }
                end

                local function explain_nested_expression(args, parent_fn)
                  local inner = strip_outer_parens(args)
                  if inner == '' or not inner:find('$', 1, true) then
                    return nil
                  end
                  local parts = split_top_level_by_dollar(inner)
                  if #parts < 2 then
                    return nil
                  end

                  local calls = {}
                  for _, part in ipairs(parts) do
                    local c = parse_nested_call(part)
                    if c then table.insert(calls, c) end
                  end
                  if #calls == 0 then return nil end

                  local lines = { '  flow:' }

                  local step = 1
                  for i = #calls, 1, -1 do
                    local c = calls[i]
                    local detail = ''
                    if c.fn == 'range' and #c.args >= 3 then
                      detail = 'maps source ' .. c.args[3] .. ' into [' .. c.args[1] .. ', ' .. c.args[2] .. ']'
                    elseif c.fn == 'slow' and #c.args >= 1 then
                      detail = 'slows incoming modulation by factor ' .. c.args[1]
                    elseif c.fn == 'fast' and #c.args >= 1 then
                      detail = 'speeds incoming modulation by factor ' .. c.args[1]
                    elseif c.fn == 'saw' or c.fn == 'sine' or c.fn == 'tri' or c.fn == 'square' then
                      detail = 'base modulation waveform'
                    else
                      detail = 'transforms incoming modulation pattern'
                    end
                    table.insert(lines, string.format('    %d) %s → %s', step, c.pretty, detail))
                    step = step + 1
                  end

                  if parent_fn and parent_fn ~= '' then
                    table.insert(lines, '    result: feeds ' .. parent_fn .. ' parameter')
                  else
                    table.insert(lines, '    result: feeds outer expression parameter')
                  end

                  return lines
                end

                local function append_insights(target)
                  if #insights == 0 then
                    return
                  end
                  table.insert(target, 'Insights:')
                  local max_insights = #insights
                  for i = 1, max_insights do
                    local it = insights[i]
                    if type(it) == 'table' then
                      local fn = tostring(it['function'] or '')
                      local args = tostring(it.args or '')
                      local sig = tostring(it.signature or '')
                      local summary = tostring(it.summary or '')
                      local op = tostring(it.operator or '')
                      local params, returns = parse_signature(sig)
                      local arg_tokens = split_top_level_args(args)
                      local arg_labels = arg_labels_for(fn)

                      local prefix = (op ~= '' and (op .. ' ') or '') .. fn
                      local annotated = compact_annotations(fn, arg_tokens, params, arg_labels)
                      local line = '• ' .. prefix
                      if annotated ~= '' then
                        line = line .. '(' .. annotated .. ')'
                      elseif args ~= '' then
                        line = line .. ' ' .. args
                      end
                      if returns ~= '' then
                        line = line .. ' → ' .. compact_type_name(returns)
                      end
                      table.insert(target, line)

                      if fn == 'note' and args:find('<', 1, true) then
                        table.insert(target, '  pattern: <> alternates over cycle; [] groups notes together')
                      elseif summary ~= '' then
                        local compact = summary:gsub('%s+', ' ')
                        if #compact > 96 then compact = compact:sub(1, 96) .. '…' end
                        table.insert(target, '  ' .. compact)
                      end

                      local nested = explain_nested_expression(args, fn)
                      if type(nested) == 'table' then
                        for _, ln in ipairs(nested) do
                          table.insert(target, ln)
                        end
                      end
                    end
                  end
                end

                if expr ~= '' then
                  table.insert(lines, 'expr: ' .. expr)
                end

                append_insights(lines)

                if #events == 0 and type(rows) == 'table' and #rows > 0 then
                  for i = 1, #rows do
                    local row = tostring(rows[i])
                    local ev = parse_event_row(row)
                    if ev then table.insert(events, ev) end
                  end

                  if #events == 0 then
                    for i = 1, #rows do
                      table.insert(lines, '• ' .. tostring(rows[i]))
                    end
                  end
                elseif #events == 0 then
                  table.insert(lines, 'No event lines returned')
                end

                if #events > 0 then
                  local visual = build_visual_lines(events, track_label or 'd?', cycles, expr)
                  if visual then
                    local out = {}
                    for _, l in ipairs(visual) do table.insert(out, l) end
                    table.insert(out, '')
                    append_insights(out)
                    table.insert(out, '')
                    table.insert(out, 'expr: ' .. (expr ~= '' and expr or '<none>'))
                    return out, vim.log.levels.INFO
                  end
                end

                return lines, vim.log.levels.INFO
              end

              local function show_eval_preview(lines)
                if type(lines) ~= 'table' or #lines == 0 then
                  vim.notify('No evaluate output', vim.log.levels.INFO)
                  return
                end

                local normalized = {}
                for _, item in ipairs(lines) do
                  local text = tostring(item or '')
                  local parts = vim.split(text, '\n', { plain = true })
                  if #parts == 0 then
                    table.insert(normalized, '')
                  else
                    for _, part in ipairs(parts) do
                      table.insert(normalized, part)
                    end
                  end
                end
                lines = normalized

                local buf_preview = vim.api.nvim_create_buf(false, true)
                vim.bo[buf_preview].bufhidden = 'wipe'
                vim.bo[buf_preview].filetype = 'markdown'

                vim.api.nvim_buf_set_lines(buf_preview, 0, -1, false, lines)

                local max_len = 0
                for _, line in ipairs(lines) do
                  local l = vim.fn.strdisplaywidth(line)
                  if l > max_len then max_len = l end
                end

                local width = math.min(math.max(max_len + 4, 60), math.floor(vim.o.columns * 0.9))
                local height = math.min(math.max(#lines + 2, 8), math.floor(vim.o.lines * 0.7))
                local row = math.floor((vim.o.lines - height) / 2 - 1)
                local col = math.floor((vim.o.columns - width) / 2)

                local win = vim.api.nvim_open_win(buf_preview, true, {
                  relative = 'editor',
                  width = width,
                  height = height,
                  row = math.max(row, 0),
                  col = math.max(col, 0),
                  style = 'minimal',
                  border = 'rounded',
                  title = ' Tidal Evaluate ',
                  title_pos = 'center',
                })

                vim.wo[win].wrap = true
                vim.wo[win].cursorline = false

                vim.keymap.set('n', 'q', function()
                  if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_close(win, true)
                  end
                end, { buffer = buf_preview, silent = true })

                vim.keymap.set('n', '<Esc>', function()
                  if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_close(win, true)
                  end
                end, { buffer = buf_preview, silent = true })
              end

              local function echo_eval_history(lines, level)
                if type(lines) ~= 'table' or #lines == 0 then
                  return
                end
                local hl = 'None'
                if level == vim.log.levels.ERROR then
                  hl = 'ErrorMsg'
                elseif level == vim.log.levels.WARN then
                  hl = 'WarningMsg'
                end
                for _, line in ipairs(lines) do
                  local text = tostring(line or '')
                  local parts = vim.split(text, '\n', { plain = true })
                  if #parts == 0 then
                    vim.api.nvim_echo({ { '', hl } }, true, {})
                  else
                    for _, part in ipairs(parts) do
                      vim.api.nvim_echo({ { part, hl } }, true, {})
                    end
                  end
                end
              end

              local params = { textDocument = vim.lsp.util.make_text_document_params(buf) }
              local responses = vim.lsp.buf_request_sync(buf, 'textDocument/codeLens', params, 2000) or {}
              local row = vim.api.nvim_win_get_cursor(0)[1] - 1
              local chosen = nil
              local fallback = nil
              local bestDistance = math.huge

              for _, resp in pairs(responses) do
                local result = resp and resp.result or {}
                for _, lens in ipairs(result) do
                  local rng = lens.range or {}
                  local start = (rng.start or {}).line
                  local ending = (rng['end'] or {}).line
                  if start ~= nil and ending ~= nil and lens.command and lens.command.command == 'tidalhelp.evaluateBlock' then
                    if row >= start and row <= ending then
                      chosen = lens.command
                      break
                    end

                    local distance = math.abs(row - start)
                    if distance < bestDistance then
                      bestDistance = distance
                      fallback = lens.command
                    end
                  end
                end
                if chosen then break end
              end

              if not chosen and fallback then
                chosen = fallback
              end

              if not chosen then
                vim.notify('No evaluate lens on this line', vim.log.levels.INFO)
                return
              end

              local track_label = 'd?'
              if type(chosen.arguments) == 'table' and type(chosen.arguments[1]) == 'table' then
                local tr = chosen.arguments[1].track
                if tr ~= nil then
                  track_label = 'd' .. tostring(tr)
                end
              end

              local exec = vim.lsp.buf_request_sync(buf, 'workspace/executeCommand', {
                command = chosen.command,
                arguments = chosen.arguments,
              }, 4000) or {}

              local result = nil
              for _, resp in pairs(exec) do
                if resp and resp.result then
                  result = resp.result
                  break
                end
              end

              if result == nil then
                vim.notify('No result from evaluate command', vim.log.levels.WARN)
                echo_eval_history({ 'Tidal Evaluate: No result from evaluate command' }, vim.log.levels.WARN)
                return
              end

              local lines, level = format_eval_message(result, track_label)
              echo_eval_history(lines, level)
              if level == vim.log.levels.ERROR then
                vim.notify(table.concat(lines, '\n'), level, { title = 'Tidal Evaluate' })
              else
                show_eval_preview(lines)
              end
            end

            refresh_codelens(bufnr)
            vim.api.nvim_create_autocmd({ 'BufEnter', 'InsertLeave' }, {
              buffer = bufnr,
              callback = function() refresh_codelens(bufnr) end,
            })

            vim.keymap.set('n', '<leader>lr', function()
              run_tidal_eval_lens(bufnr)
            end, { buffer = bufnr, desc = 'LSP: Run code lens' })

            vim.keymap.set('n', '<leader>cl', function()
              run_tidal_eval_lens(bufnr)
            end, { buffer = bufnr, desc = 'Tidal: Evaluate lens at line' })

            vim.keymap.set('n', '<leader>lR', function()
              refresh_codelens(bufnr)
            end, { buffer = bufnr, desc = 'LSP: Refresh code lens' })

            vim.keymap.set('n', '<leader>le', function()
              run_tidal_eval_lens(bufnr)
            end, { buffer = bufnr, desc = 'LSP: Eval lens at line' })
          end

          vim.api.nvim_create_autocmd("CursorHold", {
            buffer = bufnr,
            callback = function()
              local timer = vim.loop.new_timer()
              timer:start(1000, 0, vim.schedule_wrap(function()
                if vim.api.nvim_get_current_buf() == bufnr then
                  vim.diagnostic.open_float(nil, {
                    focusable = false,
                    close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
                    source = 'always',
                    scope = 'cursor',
                  })
                end
                timer:close()
              end))
            end,
          })
        end,
      })
    end,
  }
}
