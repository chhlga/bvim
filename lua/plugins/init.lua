return {
  -- require("plugins.neotree"),
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    init = function()
      vim.opt.laststatus = 3
      vim.opt.splitkeep = "screen"
    end,
    opts = {
      options = {
        left = { size = 35 },
        right = { size = 60 },
      },
      left = {
        {
          title = "Neo-Tree",
          ft = "neo-tree",
        },
      },
      right = {
        {
          title = "OpenCode",
          ft = "opencode_terminal",
          open = function()
            require("opencode").toggle()
          end,
        },
      },
      bottom = {
        {
          ft = "snacks_terminal",
          size = { height = 0.3 },
          title = "snacks_terminal",
        },
      },
      animate = { enabled = false },
      wo = {
        winbar = true,
        winfixwidth = true,
        winfixheight = true,
        winhighlight = "WinBar:EdgyWinBar,Normal:EdgyNormal",
        spell = false,
        signcolumn = "no",
      },
      keys = {
        ["q"] = function(win) win:hide() end,
        ["<C-q>"] = function(win) win.view.edgebar:close() end,
      },
    },
  },
  {
    'saghen/blink.compat',
    -- use v2.* for blink.cmp v1.*
    version = '2.*',
    -- lazy.nvim will automatically load the plugin when it's required by blink.cmp
    lazy = true,
    -- make sure to set opts so that lazy.nvim calls blink.compat's setup
    opts = {},
  },
  require("plugins.blink"),

  require("plugins.catppuccin"),
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = { "lua", "vim", "vimdoc", "query" },
      })
    end,
  },

  {
    "epwalsh/pomo.nvim",
    version = "*",
    lazy = true,
    cmd = { "TimerStart", "TimerRepeat", "TimerSession" },
    dependencies = {
      "rcarriga/nvim-notify",
    },
    opts = {
      notifiers = {
        { name = "System" }
      },
      sessions = {
        default1h = {
          { name = "Work",        duration = "20m" },
          { name = "Short Break", duration = "5m" },
          { name = "Work",        duration = "20m" },
        },
        default2h = {
          { name = "Work",        duration = "20m" },
          { name = "Short Break", duration = "5m" },
          { name = "Work",        duration = "20m" },
          { name = "Long Break",  duration = "15m" },
          { name = "Work",        duration = "20m" },
          { name = "Short Break", duration = "5m" },
          { name = "Work",        duration = "20m" },
        },
        rest = {
          { name = "Long Break", duration = "30m" },
        }
      },
    },
  },

  {
    "ahmedkhalf/project.nvim",
    event = "VeryLazy",
    config = function()
      require("project_nvim").setup({
        detection_methods = { "lsp", "pattern" },
        patterns = { ".git", "Gemfile", "src/Gemfile" },
        show_hidden = true,
      })
    end,
  },

  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          ruby = { "rubocop" },
        },
        formatters = {
          rubocop = {
            command = "bundle",
            args = { "exec", "rubocop", "--autocorrect", "--stdin", "$FILENAME", "--stderr" },
            stdin = true,
            require_cwd = true,
          }
        },
      })
    end,
  },


  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    config = function()
      require('gitsigns').setup()
    end,
  },
  {
    "tpope/vim-fugitive",
    event = "VeryLazy",
  },
  {
    "sindrets/diffview.nvim",
    event = "VeryLazy",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = { layout = "diff2_horizontal" },
        merge_tool = { layout = "diff3_horizontal" },
      },
      file_panel = {
        listing_style = "tree",
        win_config = { position = "left", width = 35 },
      },
    },
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    config = function()
      require("lualine").setup({
        options = {
          theme = "catppuccin-mocha",
          section_separators = { left = "", right = "" },
          component_separators = { left = "", right = "" },
          disabled_filetypes = { "alpha", "dashboard", "AvanteInput", "Avante", "AvanteSelectedFiles", "neo-tree", "opencode_terminal" },
        },
        winbar = {
          lualine_c = {
            function()
              return require("nvim-navic").get_location()
            end,
          },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff" },
          lualine_c = {
            "filename"
          },
          lualine_x = { require("opencode").statusline, "encoding", "fileformat", "filetype" },
          lualine_y = { "location" },
          lualine_z = { "progress",
            function()
              local ok, pomo = pcall(require, "pomo")
              if not ok then
                return ""
              end

              local timer = pomo.get_first_to_finish()
              if timer == nil then
                return ""
              end

              return "󰄉 " .. tostring(timer)
            end,
          }
        },
      })
    end,
  },
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    event = "VeryLazy",
    config = function()
      require("bufferline").setup({
        options = {
          mode = "buffers",
          separator_style = "slant",
          always_show_bufferline = true,
          show_buffer_close_icons = true,
          show_close_icon = true,
          color_icons = true,
          diagnostics = "nvim_lsp",
          diagnostics_indicator = function(count, level)
            local icon = level:match("error") and " " or " "
            return " " .. icon .. count
          end,
          offsets = {
            {
              filetype = "neo-tree",
              highlight = "Directory",
              separator = true,
            },
            {
              filetype = "opencode_terminal",
              separator = true,
            }
          },
          groups = {
            items = {
              require('bufferline.groups').builtin.pinned:with({ icon = "󰐃 " })
            }
          },
        },
        highlights = {
          buffer_selected = {
            bold = true,
            italic = false,
          },
        },
      })
    end,
  },

  {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    lazy = false,
    config = function()
      require('Comment').setup({
        toggler = { line = '<leader>/' },
        opleader = {
          line = '<leader>/',
        },
      })

      local ft = require('Comment.ft')
      ft.sonicpi = '# %s'
    end,
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end,
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({
        enable_check_bracket_line = true,
        ignored_next_char = "[%w%.]",
        check_ts = true,
        fast_wrap = {
          map = '<M-e>',
          chars = { '{', '[', '(', '"', "'" },
          pattern = [=[[%'%"%>%]%)%}%,]]=],
          end_key = '$',
          keys = 'qwertyuiopzxcvbnmasdfghjkl',
          check_comma = true,
          highlight = 'Search',
          highlight_grey = 'Comment'
        },
        disable_filetype = { "TelescopePrompt", "vim" },
      })
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "VeryLazy",
    config = function()
      require("ibl").setup({
        scope = {
          enabled = true,
          show_start = false,
          show_end = false,
          injected_languages = true,
          highlight = { "Function", "Label" },
          priority = 500,
        }
      })
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      picker = {
        sources = {
          explorer = {
            layout = { layout = { position = "float" } },
          }
        }
      },
      plugins = {},
      win = {
        no_overlap = false,
        width = { min = 40, max = 0.7 },
        height = { min = 10, max = 0.75 },
        padding = { 0, 1 },
        col = -0.5,
        row = 2,
        border = "rounded",
        title = true,
        title_pos = "left",
      },
      layout = {
        width = { min = 30 },
      },
    },
  },
  {
    "rcarriga/nvim-notify",
    lazy = false,
    config = function()
      local notify = require("notify")
      notify.setup({
        stages = "slide",
        timeout = 3000,
        render = "wrapped-compact",
        background_colour = "#000000",
        max_width = 50,
        max_height = 3,
        on_open = function(win)
          vim.api.nvim_win_set_config(win, {
            focusable = false,
          })
        end,
      })
      vim.notify = notify
    end,
  },
  {
    "karb94/neoscroll.nvim",
    opts = {},
  },
  require("plugins.noice"),
  {
    "tpope/vim-sleuth",
    event = "VeryLazy",
  },
  {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
  },

  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    config = function()
      require("persistence").setup({
        dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"),
        options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals" },
        pre_save = function()
          local excluded_filetypes = {
            "neo-tree",
            "snacks_terminal",
            "opencode_terminal",
            "notify",
            "noice",
            "edgy",
          }
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local ft = vim.bo[buf].filetype
            for _, excluded_ft in ipairs(excluded_filetypes) do
              if ft == excluded_ft then
                vim.api.nvim_buf_delete(buf, { force = true })
                break
              end
            end
          end
        end,
        save_empty = false,
      })
    end,
  },
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      input = { enabled = true },
      terminal = { enabled = true },
      picker = { enabled = true },
    }
  },
  {
    "github/copilot.vim",
    cmd = "Copilot",
    event = "BufWinEnter",
    init = function()
      vim.g.copilot_no_maps = true
    end,
    config = function()
      -- Block the normal Copilot suggestions
      vim.api.nvim_create_augroup("github_copilot", { clear = true })
      vim.api.nvim_create_autocmd({ "FileType", "BufUnload" }, {
        group = "github_copilot",
        callback = function(args)
          vim.fn["copilot#On" .. args.event]()
        end,
      })
      vim.fn["copilot#OnFileType"]()
    end,
  },
  {
    "NickvanDyke/opencode.nvim",
    config = function()
      ---@type opencode.Opts
      vim.g.opencode_opts = {
        ask = {
          prompt = "Ask opencode: ",
          blink_cmp_sources = { "opencode", "buffer" },
          snacks = {
            icon = "󰚩 ",
            win = {
              backdrop = false,
              zindex = 50,
              position = "float",
              border = true,
              row = 3,
              title_pos = "center",
              height = 3,
              width = 60,
              relative = "cursor",
              wo = {
                winhighlight = "NormalFloat:SnacksInputNormal,FloatBorder:SnacksInputBorder,FloatTitle:SnacksInputTitle",
                cursorline = false,
                wrap = true,
                linebreak = true,
              },

            },
            expand = true,
          },
        },
        provider = {
          enabled = "snacks",
          snacks = {
            auto_close = true,
            win = {
              enter = false,
              border = true,
              wo = {
                winbar = "",
              },
              bo = {
                filetype = "opencode_terminal",
              },
            },
          }
        }
      }

      vim.o.autoread = true
    end,
  },
  {
    'xvzc/chezmoi.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require("chezmoi").setup {
        edit = {
          watch = false,
          force = false,
        },
        events = {
          on_open = {
            notification = {
              enable = true,
              msg = "Opened a chezmoi-managed file",
              opts = {},
            },
          },
          on_watch = {
            notification = {
              enable = true,
              msg = "This file will be automatically applied",
              opts = {},
            },
          },
          on_apply = {
            notification = {
              enable = true,
              msg = "Successfully applied",
              opts = {},
            },
          },
        },
      }
    end
  },
  {
    "chrishrb/gx.nvim",
    keys = { { "gx", "<cmd>Browse<cr>", mode = { "n", "x" } } },
    cmd = { "Browse" },
    init = function()
      vim.g.netrw_nogx = 1                      -- disable netrw gx
    end,
    dependencies = { "nvim-lua/plenary.nvim" }, -- Required for Neovim < 0.10.0
    config = true,                              -- default settings
    submodules = false,                         -- not needed, submodules are required only for tests

    -- you can specify also another config if you want
    config = function()
      require("gx").setup {
        open_browser_app = "open", -- specify your browser app; default for macOS is "open", Linux "xdg-open" and Windows "powershell.exe"
        -- open_browser_args = { "--background" },   -- specify any arguments, such as --background for macOS' "open".

        open_callback = false, -- optional callback function to be called with the selected url on open
        -- open_callback = function(url)
        --   vim.fn.setreg("+", url)                 -- for example, you can set the url to clipboard here
        -- end,

        select_prompt = true, -- shows a prompt when multiple handlers match; disable to auto-select the top one

        handlers = {
          plugin = true,       -- open plugin links in lua (e.g. packer, lazy, ..)
          github = true,       -- open github issues
          brewfile = true,     -- open Homebrew formulaes and casks
          package_json = true, -- open dependencies from package.json
          search = true,       -- search the web/selection on the web if nothing else is found
          go = true,           -- open pkg.go.dev from an import statement (uses treesitter)
          jira = {             -- custom handler to open Jira tickets (these have higher precedence than builtin handlers)
            name = "jira",     -- set name of handler
            handle = function(mode, line, _)
              local ticket = require("gx.helper").find(line, mode, "(%u+-%d+)")
              if ticket and #ticket < 20 then
                return "http://jira.company.com/browse/" .. ticket
              end
            end,
          },
          rust = {                   -- custom handler to open rust's cargo packages
            name = "rust",           -- set name of handler
            filetype = { "toml" },   -- you can also set the required filetype for this handler
            filename = "Cargo.toml", -- or the necessary filename
            handle = function(mode, line, _)
              local crate = require("gx.helper").find(line, mode, "(%w+)%s-=%s")

              if crate then
                return "https://crates.io/crates/" .. crate
              end
            end,
          },
        },
        handler_options = {
          search_engine = "google",               -- you can select between google, bing, duckduckgo, ecosia and yandex
          -- search_engine = "https://search.brave.com/search?q=",   -- or you can pass in a custom search engine
          select_for_search = false,              -- if your cursor is e.g. on a link, the pattern for the link AND for the word will always match. This disables this behaviour for default so that the link is opened without the select option for the word AND link

          git_remotes = { "upstream", "origin" }, -- list of git remotes to search for git issue linking, in priority
          -- git_remotes = function(fname)                           -- you can also pass in a function
          --   if fname:match("myproject") then
          --     return { "mygit" }
          --   end
          --   return { "upstream", "origin" }
          -- end,

          git_remote_push = false, -- use the push url for git issue linking,
          -- git_remote_push = function(fname)   -- you can also pass in a function
          --   return fname:match("myproject")
          -- end,
        },
      }
    end,
  },

  {
    'magicmonty/sonicpi.nvim',
    dependencies = {
      'kyazdani42/nvim-web-devicons',
    },
    config = function()
      require('sonicpi').setup({
        server_dir = "/Applications/Sonic Pi.app/Contents/Resources/app/server", -- It will try to find the SonicPi server
        lsp_diagnostics = true,
        single_file = true,
        mappings = {
          { 'n', '<leader>s', require('sonicpi.remote').stop,               default_mapping_opts },
          { 'i', '<M-s>',     require('sonicpi.remote').stop,               default_mapping_opts },
          { 'n', '<leader>r', require('sonicpi.remote').run_current_buffer, default_mapping_opts },
          { 'i', '<M-r>',     require('sonicpi.remote').run_current_buffer, default_mapping_opts },
        },
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "sonicpi",
        callback = function()
          local remote = require('sonicpi.remote')
          local stream = require('sonicpi.stream')
          local osc_hook = require('sonicpi.osc_hook')
          local highlighter = require('sonicpi.highlighter')

          remote.startServer()

          stream.start({ port = 8765, format = "json" })
          osc_hook.setup()
          highlighter.setup()
        end,
      })

      vim.api.nvim_create_autocmd("BufUnload", {
        pattern = "sonicpi",
        callback = function()
          local remote = require('sonicpi.remote')
          local log = require('sonicpi.log')
          local stream = require('sonicpi.stream')

          log.close_logs()
          remote.stopServer()
          stream.stop()
        end,
      })
    end,
  },
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*", -- use latest release, remove to use latest commit
    ft = "markdown",
    opts = {
      legacy_commands = false, -- this will be removed in the next major release
      workspaces = {
        {
          name = "personal",
          path = "~/_service/memory/data/basic-memory/",
        }
      },
      templates = {
        folder = "chhlga-obsidian/Resources/templates",
        date_format = "%Y-%m-%d-%a",
        time_format = "%H:%M",
      },
    },
  },
  -- {
  --   "tidalcycles/vim-tidal",
  --   dependencies = {
  --     "mbbill/undotree",
  --   },
  --   config = function()
  --     vim.api.nvim_create_autocmd("FileType", {
  --       pattern = "tidal",
  --       callback = function()
  --         vim.g.tidal_target = "tmux"
  --         vim.g.tidal_default_config = { socket_name = "default", target_pane = "music:tidal.2" }
  --         -- vim.g.tidal_no_mappings = 1
  --         vim.opt_local.shiftwidth = 2
  --         vim.opt_local.tabstop = 2
  --         vim.opt_local.expandtab = true
  --       end,
  --     })
  --   end,
  -- },
  -- tidal.nvim replaced by tidalhelp (our own plugin)
  -- {
  --   "grddavies/tidal.nvim",
  --   opts = {
  --     mappings = {
  --       send_line = { mode = { "i", "n" }, key = "<M-CR>" },
  --       send_visual = { mode = { "x" }, key = "<M-CR>" },
  --       send_node = { mode = "n", key = "<leader><CR>" },
  --       send_hush = { mode = "n", key = "<leader><Esc>" },
  --     },
  --   },
  -- },
  {
    "tpope/vim-repeat",
    event = "VeryLazy",
  },
  {
    "thgrund/tidal-makros.nvim",
    config = function()
      require("makros").setup()
    end,
  },
}
  -- {
  --   "chrishrb/gx.nvim",
  --   event = "VeryLazy",
  --   dependencies = { "nvim-lua/plenary.nvim" },
  --   config = function()
  --     require("gx").setup({
  --       open_browser_app = "open",
  --       handlers = {
  --         plugin = false,
  --         github = true,
  --         brewfile = false,
  --         package_json = false,
  --         search = false,
  --         go = false,
  --         rust = false,
  --       },
  --       handler_options = {
  --         search_engine = "google",
  --       },
  --     })
  --
  --     -- Register custom handlers for package managers
  --     local gx = require('gx')
  --     gx.handlers.rubygems = require('gx.handlers.rubygems')
  --     gx.handlers.gomod = require('gx.handlers.gomod')
  --     gx.handlers.npm = require('gx.handlers.npm')
  --   end,
  -- },
-- }
