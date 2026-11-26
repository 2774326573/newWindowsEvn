-- Optional Neovim bridge to the repository-managed Yazi executable.
-- Installed only with the explicit --with-yazi-nvim option.
return {
  {
    "mikavilpas/yazi.nvim",
    version = false,
    cmd = { "Yazi", "Yazi cwd", "Yazi toggle" },
    dependencies = {
      { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
      {
        "<leader>fy",
        "<cmd>Yazi<cr>",
        mode = { "n", "v" },
        desc = "Yazi：当前文件位置打开",
      },
      {
        "<leader>fY",
        "<cmd>Yazi cwd<cr>",
        desc = "Yazi：当前工作目录打开",
      },
    },
    opts = {
      -- Keep Neo-tree and the existing shell command unchanged.
      open_for_directories = false,
      open_multiple_tabs = false,
      change_neovim_cwd_on_close = false,
      floating_window_scaling_factor = 0.9,
      yazi_floating_window_border = "rounded",
      yazi_floating_window_winblend = 0,
    },
  },
}
