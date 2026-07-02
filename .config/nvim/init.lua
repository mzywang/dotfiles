local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true

vim.cmd("syntax on")
vim.cmd("filetype plugin indent on")
vim.cmd.colorscheme("habamax")

vim.api.nvim_create_user_command("CopyRelPath", function()
  vim.fn.setreg("+", vim.fn.expand("%"))
end, {})

vim.api.nvim_create_user_command("CopyPwd", function()
  vim.fn.setreg("+", vim.fn.getcwd())
  print("copied cwd")
end, {})

require("lazy").setup({
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
    },
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = {
        char = "│",
        tab_char = "│",
      },
      scope = {
        enabled = true,
      },
    },
  },
})
