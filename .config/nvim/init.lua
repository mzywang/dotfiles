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

local eng_log_autosave = vim.api.nvim_create_augroup("EngLogAutoSave", { clear = true })

local function save_eng_log_if_modified()
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
  if name == "eng_log.txt" and vim.bo.modified then
    pcall(vim.cmd, "silent! write")
  end
end

vim.api.nvim_create_autocmd("BufLeave", {
  group = eng_log_autosave,
  pattern = "eng_log.txt",
  callback = function()
    if vim.bo.modified then
      pcall(vim.cmd, "silent! write")
    end
  end,
})

vim.api.nvim_create_autocmd("FocusLost", {
  group = eng_log_autosave,
  pattern = "*",
  callback = save_eng_log_if_modified,
})

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
