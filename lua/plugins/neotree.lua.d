return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("neo-tree").setup({
      close_if_last_window = true,
      enable_git_status = true,
      enable_diagnostics = true,
      open_files_do_not_replace_types = { "terminal", "trouble", "qf", "edgy" },
      sources = { "filesystem", "buffers", "git_status", "document_symbols" },
      event_handlers = {
        {
          event = "file_renamed",
          handler = function(args)
            print(args.source, " renamed to ", args.destination)
            Snacks.rename.on_rename_file(args.source, args.destination)
          end
        },
        {
          event = "file_moved",
          handler = function(args)
            print(args.source, " moved to ", args.destination)
            Snacks.rename.on_rename_file(args.source, args.destination)
          end
        },

      },
      source_selector = {
        winbar = true,
        content_layout = "center",
        sources = {
          { source = "filesystem", display_name = " F" },
          { source = "buffers", display_name = " B" },
          { source = "git_status", display_name = " D" },
          { source = "document_symbols", display_name = " S" },
          { source = "marks", display_name = " M" },
        },
      },
      popup_border_style = "rounded",
      default_component_configs = {
        container = {
          enable_character_fade = true,
        },
      },
      window = {
        mappings = {
          ["F"] = function() vim.cmd("Neotree focus filesystem left") end,
          ["B"] = function() vim.cmd("Neotree focus buffers left") end,
          ["D"] = function() vim.cmd("Neotree focus git_status left") end,
          ["S"] = function() vim.cmd("Neotree focus document_symbols left") end,
          ["M"] = function() vim.cmd("Neotree focus marks left") end,
        },
        popup = {
          size = { width = "80%", height = "60%" },
          position = "50%",
        },
      },
      preview = {
        popup_border_style = "rounded",
        min_width = 80,
        min_height = 20,
      },
      ["marks"] = {
        window = {
          mappings = {
            ["<cr>"] = "open",
            ["o"] = "open",
            ["s"] = "open_split",
            ["v"] = "open_vsplit",
            ["d"] = "delete_mark",
            ["r"] = "refresh",
          },
        },
      },
    })
  end,
}
