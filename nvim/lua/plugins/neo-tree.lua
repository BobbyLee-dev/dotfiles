return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true, -- Show filtered items (hidden files)
        hide_dotfiles = false, -- Don't hide dotfiles
        hide_gitignored = false, -- Optionally, don't hide gitignored files
      },
    },
  },
}
