require("lazy").setup({
	spec = {
		{ "LazyVim/LazyVim", import = "lazyvim.plugins" },
		-- Import extras for better support
		{ import = "lazyvim.plugins.extras.lang.typescript" }, -- Vue/Svelte often need this
		{ import = "lazyvim.plugins.extras.lang.tailwind" }, -- Great for CSS/SCSS
		{ import = "lazyvim.plugins.extras.formatting.prettier" },

		-- Import your custom plugins
		{ import = "plugins" },
	},
})
