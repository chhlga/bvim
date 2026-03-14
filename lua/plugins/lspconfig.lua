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
            vim.lsp.codelens.refresh({ bufnr = bufnr })
            vim.api.nvim_create_autocmd({ 'BufEnter', 'InsertLeave' }, {
              buffer = bufnr,
              callback = function() vim.lsp.codelens.refresh({ bufnr = bufnr }) end,
            })
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
