-- Extra LSP configurations for system-installed servers
-- This extends jelvim's lspconfig.lua with additional language servers
-- Managed by chezmoi dotfiles

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- This runs after jelvim's lspconfig setup
      -- Configure additional LSP servers installed via dotfiles

      -- Bash
      vim.lsp.config('bashls', {
        cmd = { 'bash-language-server', 'start' },
        filetypes = { 'sh', 'bash', 'zsh' },
        root_markers = { '.git', '.bashrc', '.zshrc' },
        settings = {
          bashIde = {
            globPattern = "*@(.sh|.inc|.bash|.command)",
            includeAllWorkspaceSymbols = true,
            shellcheckArguments = "",
          },
        },
      })

      -- YAML
      vim.lsp.config('yamlls', {
        cmd = { 'yaml-language-server', '--stdio' },
        filetypes = { 'yaml', 'yaml.docker-compose', 'yaml.gitlab' },
        root_markers = { '.git' },
        settings = {
          yaml = {
            keyOrdering = false,
            format = { enable = true },
            validate = true,
            schemaStore = {
              enable = true,
              -- url = "https://www.schemastore.org/api/json/catalog.json",
            },
            -- schemas = {
            --   ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
            --   ["https://json.schemastore.org/github-action.json"] = "/.github/actions/*/action.{yml,yaml}",
            --   ["https://json.schemastore.org/docker-compose.json"] = "docker-compose*.{yml,yaml}",
            --   ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "compose*.{yml,yaml}",
            -- },
          },
        },
      })

      -- Dockerfile
      vim.lsp.config('dockerls', {
        cmd = { 'docker-langserver', '--stdio' },
        filetypes = { 'dockerfile' },
        root_markers = { 'Dockerfile', '.git' },
      })

      -- Markdown (Marksman)
      vim.lsp.config('marksman', {
        cmd = { 'marksman', 'server' },
        filetypes = { 'markdown', 'markdown.mdx' },
        root_markers = { '.marksman.toml', '.git' },
      })

      -- Tailwind CSS
      vim.lsp.config('tailwindcss', {
        cmd = { 'tailwindcss-language-server', '--stdio' },
        filetypes = {
          'html', 'css', 'scss', 'javascript', 'javascriptreact',
          'typescript', 'typescriptreact', 'vue', 'svelte',
        },
        root_markers = {
          'tailwind.config.js', 'tailwind.config.cjs', 'tailwind.config.mjs', 'tailwind.config.ts',
          'postcss.config.js', 'postcss.config.cjs', 'postcss.config.mjs', 'postcss.config.ts',
          '.git',
        },
        settings = {
          tailwindCSS = {
            classAttributes = { "class", "className", "class:list", "classList", "ngClass" },
            lint = {
              cssConflict = "warning",
              invalidApply = "error",
              invalidScreen = "error",
              invalidVariant = "error",
              invalidConfigPath = "error",
              invalidTailwindDirective = "error",
              recommendedVariantOrder = "warning",
            },
            validate = true,
          },
        },
      })

      -- ESLint
      vim.lsp.config('eslint', {
        cmd = { 'vscode-eslint-language-server', '--stdio' },
        filetypes = {
          'javascript', 'javascriptreact', 'javascript.jsx',
          'typescript', 'typescriptreact', 'typescript.tsx',
          'vue', 'svelte', 'html',
        },
        root_markers = {
          '.eslintrc', '.eslintrc.js', '.eslintrc.cjs', '.eslintrc.yaml', '.eslintrc.yml',
          '.eslintrc.json', 'eslint.config.js', 'eslint.config.mjs', 'eslint.config.cjs',
          'package.json', '.git',
        },
        settings = {
          codeAction = {
            disableRuleComment = { enable = true, location = "separateLine" },
            showDocumentation = { enable = true },
          },
          codeActionOnSave = { enable = false, mode = "all" },
          format = false,
          onIgnoredFiles = "off",
          problems = { shortenToSingleLine = false },
          run = "onType",
          validate = "on",
          workingDirectory = { mode = "auto" },
        },
      })

      -- Ruff (Python linter/formatter - complements pyright)
      vim.lsp.config('ruff', {
        cmd = { 'ruff', 'server' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', 'setup.py', '.git' },
        settings = {
          organizeImports = true,
          fixAll = true,
        },
      })

      -- JSON (from vscode-langservers-extracted)
      vim.lsp.config('jsonls', {
        cmd = { 'vscode-json-language-server', '--stdio' },
        filetypes = { 'json', 'jsonc' },
        root_markers = { '.git' },
        init_options = {
          provideFormatter = true,
        },
        settings = {
          json = {
            validate = { enable = true },
          },
        },
      })

      -- HTML (from vscode-langservers-extracted)
      vim.lsp.config('html', {
        cmd = { 'vscode-html-language-server', '--stdio' },
        filetypes = { 'html', 'templ' },
        root_markers = { '.git' },
        init_options = {
          configurationSection = { "html", "css", "javascript" },
          embeddedLanguages = { css = true, javascript = true },
          provideFormatter = true,
        },
      })

      -- CSS (from vscode-langservers-extracted)
      vim.lsp.config('cssls', {
        cmd = { 'vscode-css-language-server', '--stdio' },
        filetypes = { 'css', 'scss', 'less' },
        root_markers = { '.git' },
        init_options = { provideFormatter = true },
        settings = {
          css = { validate = true },
          scss = { validate = true },
          less = { validate = true },
        },
      })

      -- Enable the extra LSP servers (only if binary exists)
      local extra_servers = {
        { name = 'bashls', cmd = 'bash-language-server' },
        { name = 'yamlls', cmd = 'yaml-language-server' },
        { name = 'dockerls', cmd = 'docker-langserver' },
        { name = 'marksman', cmd = 'marksman' },
        { name = 'tailwindcss', cmd = 'tailwindcss-language-server' },
        { name = 'eslint', cmd = 'vscode-eslint-language-server' },
        { name = 'ruff', cmd = 'ruff' },
        { name = 'jsonls', cmd = 'vscode-json-language-server' },
        { name = 'html', cmd = 'vscode-html-language-server' },
        { name = 'cssls', cmd = 'vscode-css-language-server' },
      }

      local servers_to_enable = {}
      for _, server in ipairs(extra_servers) do
        if vim.fn.executable(server.cmd) == 1 then
          table.insert(servers_to_enable, server.name)
        end
      end

      if #servers_to_enable > 0 then
        vim.lsp.enable(servers_to_enable)
      end

      return opts
    end,
  },
}
