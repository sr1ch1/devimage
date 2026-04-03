local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- 1. Bootstrap: Klonen von lazy.nvim, falls es fehlt
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

-- 2. Den Pfad zum Runtime-Pfad hinzufügen
vim.opt.rtp:prepend(lazypath)

-- 3. LazyVim Setup (Hier liegt dein Fehler: Du musst lazy laden, BEVOR du setup aufrufst)
require("lazy").setup({
  spec = {
    -- Das eigentliche LazyVim Framework
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    
    -- Deine gewünschten Extras (LSP & Tools für Vue, Svelte, etc.)
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.tailwind" },
    { import = "lazyvim.plugins.extras.formatting.prettier" },

    -- Hier werden deine eigenen Plugins aus lua/plugins/*.lua geladen
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false, 
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = true },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
