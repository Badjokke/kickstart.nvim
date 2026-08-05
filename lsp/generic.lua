local function lsp_on_attach(ev)
	local client = vim.lsp.get_client_by_id(ev.data.client_id)
	if not client then
		return
	end

	local bufnr = ev.buf
	local opts = { noremap = true, silent = true, buffer = bufnr }

	vim.keymap.set("n", "gd", function()
		require("fzf-lua").lsp_definitions({ jump_1 = true })
	end, opts)
        vim.keymap.set("n", "gi", function()
		require("fzf-lua").lsp_implementations()
	end, opts)
	vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

	vim.keymap.set("n", "gS", function()
		vim.cmd("vsplit")
		vim.lsp.buf.definition()
	end, opts)

	vim.keymap.set("n", "gra", vim.lsp.buf.code_action, opts)
	vim.keymap.set("n", "rn", vim.lsp.buf.rename, opts)

	vim.keymap.set("n", "<leader>e", function()
		vim.diagnostic.open_float({ scope = "line" })
	end, opts)
	vim.keymap.set("n", "<leader>d", function()
		vim.diagnostic.open_float({ scope = "cursor" })
	end, opts)
	vim.keymap.set("n", "<leader>nd", function()
		vim.diagnostic.jump({ count = 1 })
	end, opts)

	vim.keymap.set("n", "<leader>pd", function()
		vim.diagnostic.jump({ count = -1 })
	end, opts)

	vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
	vim.keymap.set("n", "gr", function()
		require("fzf-lua").lsp_references()
	end, opts)
	vim.keymap.set("n", "<leader>gt", function()
		require("fzf-lua").lsp_typedefs()
	end, opts)
	vim.keymap.set("n", "<leader>gs", function()
		require("fzf-lua").lsp_document_symbols()
	end, opts)
	vim.keymap.set("n", "<leader>gw", function()
		require("fzf-lua").lsp_workspace_symbols()
	end, opts)
	if client:supports_method("textDocument/codeAction", bufnr) then
		vim.keymap.set("n", "gro", function()
			vim.lsp.buf.code_action({
				context = { only = { "source.organizeImports" }, diagnostics = {} },
				apply = true,
				bufnr = bufnr,
			})
			vim.defer_fn(function()
				vim.lsp.buf.format({ bufnr = bufnr })
			end, 50)
		end, opts)
	end
end

vim.api.nvim_create_autocmd("LspAttach", { group = augroup, callback = lsp_on_attach })

vim.keymap.set("n", "<leader>q", function()
	vim.diagnostic.setloclist({ open = true })
end, { desc = "Open diagnostic list" })
vim.keymap.set("n", "<leader>dl", vim.diagnostic.open_float, { desc = "Show line diagnostics" })
