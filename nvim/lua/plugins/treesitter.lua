return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			-- Ensure these are always installed
			if type(opts.ensure_installed) == "table" then
				vim.list_extend(opts.ensure_installed, {
					"css",
					"latex",
					"scss",
					"svelte",
					"typst",
					"vue",
				})
			end
		end,
	},
}
