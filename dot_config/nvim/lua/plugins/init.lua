return {
  {
    "stevearc/conform.nvim",
    event = 'BufWritePre', 
    opts = {
      formatters_by_ft = {
        python = { "black" }, 
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
      vim.lsp.config.pyright = {
        cmd = { "pyright-langserver", "--stdio" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
      }
      vim.lsp.enable("pyright")
    end,
  },
}
