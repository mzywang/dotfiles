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

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.autoindent = true
vim.opt.smartindent = true
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

vim.keymap.set("i", ",,d", function()
  return "# " .. os.date("%Y%m%d")
end, { expr = true })

local function eng_log_time()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = " - " .. os.date("%H%M") .. ": "
  vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { line })
  vim.api.nvim_win_set_cursor(0, { lnum, #line })
  vim.cmd.startinsert()
end

vim.keymap.set("i", ",,t", eng_log_time)

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
