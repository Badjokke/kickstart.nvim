-- npm install -g pyright  (or via mason)
local root_files = {
  "pyproject.toml",
  "setup.py",
  "setup.cfg",
  "requirements.txt",
  "Pipfile",
  "pyrightconfig.json",
  ".git",
}

---@type vim.lsp.Config
return {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  -- Do not start a separate client for Python files outside a detected project.
  single_file_support = false,
  root_markers = root_files,
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    if fname == "" then
      on_dir(nil)
      return
    end
    local root = vim.fs.find(root_files, { path = fname, upward = true })[1]
    on_dir(root and vim.fs.dirname(root))
  end,
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly", -- or "workspace" to check the whole project, slower
        typeCheckingMode = "basic", -- "off" | "basic" | "standard" | "strict"
      },
    },
  },
}
