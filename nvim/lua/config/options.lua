-- Disable Perl provider
vim.g.loaded_perl_provider = 0

-- Use OSC52 clipboard
vim.g.clipboard = {
        name = "OSC52",
        copy = {
                ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
                ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
        },
        paste = {
                ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
                ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
        },
}
