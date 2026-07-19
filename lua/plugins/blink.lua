return {
  'saghen/blink.cmp',
  dependencies = { 'rafamadriz/friendly-snippets', "fang2hou/blink-copilot", "saghen/blink.compat" },
  version = '1.*',

  opts = {
    keymap = { preset = 'default' },

    enabled = function()
      local ft = vim.bo.filetype
      return ft ~= "TelescopePrompt" and ft ~= "minifiles" and ft ~= "snacks_picker_input"
    end,

    appearance = {
      nerd_font_variant = 'mono',
      use_nvim_cmp_as_default = true,
      kind_icons = {
        Text = '󰉿',
        Method = '󰊕',
        Function = '󰊕',
        Constructor = '󰒓',
        Field = '󰜢',
        Variable = '󰆦',
        Class = '󰠱',
        Interface = '󰰔',
        Module = '󰅩',
        Property = '󰖷',
        Unit = '󰪚',
        Value = '󰦨',
        Enum = '󰦨',
        Keyword = '󰻾',
        Snippet = '󰩫',
        Color = '󰏘',
        File = '󰈔',
        Reference = '󰬲',
        Folder = '󰉋',
        EnumMember = '󰦨',
        Constant = '󰏿',
        Struct = '󰆼',
        Event = '󱐋',
        Operator = '󰪚',
        TypeParameter = '󰬛',
        Copilot = ' '
      },
    },

    completion = {
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
        window = {
          border = 'rounded',
        },
      },
      menu = {
        border = 'rounded',
        draw = {
          columns = {
            { 'kind_icon' },
            { 'label',    'label_description', gap = 1 },
            { 'kind' },
          },
        },
      },
      ghost_text = {
        enabled = false,
      },
    },

    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer', 'copilot', 'sonicpi', 'tidalhelp' },
      per_filetype = {
        tidal = { 'lsp', 'buffer', 'snippets' },
      },
      providers = { -- name of cmp source
        sonicpi = {
          name = "sonicpi",
          module = "blink.compat.source",
        },
        tidalhelp = {
          name = "tidalhelp",
          module = "blink.compat.source",
          async = true,
        },
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          score_offset = 100,
          async = true,
        },
      },
    },
  },
  opts_extend = { "sources.default" },

  config = function(_, opts)
    require('blink.cmp').setup(opts)

    local colors = {
      rosewater = '#f5e0dc',
      flamingo = '#f2cdcd',
      pink = '#f5c2e7',
      mauve = '#cba6f7',
      red = '#f38ba8',
      maroon = '#eba0ac',
      peach = '#fab387',
      yellow = '#f9e2af',
      green = '#a6e3a1',
      teal = '#94e2d5',
      sky = '#89dceb',
      sapphire = '#74c7ec',
      blue = '#89b4fa',
      lavender = '#b4befe',
      text = '#cdd6f4',
      subtext1 = '#bac2de',
      subtext0 = '#a6adc8',
      overlay2 = '#9399b2',
      overlay1 = '#7f849c',
      overlay0 = '#6c7086',
      surface2 = '#585b70',
      surface1 = '#45475a',
      surface0 = '#313244',
      base = '#1e1e2e',
      mantle = '#181825',
      crust = '#11111b',
    }

    vim.api.nvim_set_hl(0, 'BlinkCmpMenu', { bg = colors.base, fg = colors.text })
    vim.api.nvim_set_hl(0, 'BlinkCmpMenuBorder', { fg = colors.blue, bg = colors.base })
    vim.api.nvim_set_hl(0, 'BlinkCmpMenuSelection', { bg = colors.surface0, bold = true })
    vim.api.nvim_set_hl(0, 'BlinkCmpScrollBarThumb', { bg = colors.surface2 })
    vim.api.nvim_set_hl(0, 'BlinkCmpScrollBarGutter', { bg = colors.surface0 })

    vim.api.nvim_set_hl(0, 'BlinkCmpLabel', { fg = colors.text })
    vim.api.nvim_set_hl(0, 'BlinkCmpLabelDeprecated', { fg = colors.overlay0, strikethrough = true })
    vim.api.nvim_set_hl(0, 'BlinkCmpLabelDetail', { fg = colors.subtext0 })
    vim.api.nvim_set_hl(0, 'BlinkCmpLabelDescription', { fg = colors.overlay1, italic = true })

    vim.api.nvim_set_hl(0, 'BlinkCmpKindText', { fg = colors.green })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindMethod', { fg = colors.blue })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindFunction', { fg = colors.blue })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindConstructor', { fg = colors.sapphire })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindField', { fg = colors.teal })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindVariable', { fg = colors.text })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindClass', { fg = colors.yellow })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindInterface', { fg = colors.yellow })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindModule', { fg = colors.mauve })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindProperty', { fg = colors.teal })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindUnit', { fg = colors.peach })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindValue', { fg = colors.peach })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindEnum', { fg = colors.yellow })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindKeyword', { fg = colors.mauve })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindSnippet', { fg = colors.pink })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindColor', { fg = colors.red })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindFile', { fg = colors.blue })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindReference', { fg = colors.peach })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindFolder', { fg = colors.blue })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindEnumMember', { fg = colors.teal })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindConstant', { fg = colors.peach })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindStruct', { fg = colors.yellow })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindEvent', { fg = colors.red })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindOperator', { fg = colors.sky })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindTypeParameter', { fg = colors.maroon })
    vim.api.nvim_set_hl(0, 'BlinkCmpKindCopilot', { fg = colors.green })

    vim.api.nvim_set_hl(0, 'BlinkCmpDoc', { bg = colors.mantle, fg = colors.text })
    vim.api.nvim_set_hl(0, 'BlinkCmpDocBorder', { fg = colors.blue, bg = colors.mantle })
    vim.api.nvim_set_hl(0, 'BlinkCmpDocCursorLine', { bg = colors.surface0 })

    vim.api.nvim_set_hl(0, 'BlinkCmpSignatureHelp', { bg = colors.mantle, fg = colors.text })
    vim.api.nvim_set_hl(0, 'BlinkCmpSignatureHelpBorder', { fg = colors.blue, bg = colors.mantle })
    vim.api.nvim_set_hl(0, 'BlinkCmpSignatureHelpActiveParameter', { fg = colors.blue, bold = true })
  end,
}
