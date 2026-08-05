---@type vim.lsp.Config
local function is_dependency_root(path)
  return path:find("/rustlib/src/rust/library/", 1, true) ~= nil
    or path:find("/vendor/", 1, true) ~= nil
end

local function active_project_root()
  for _, client in ipairs(vim.lsp.get_clients({ name = "rust_analyzer" })) do
    local root = client.config.root_dir
    if type(root) == "string" and not is_dependency_root(root) then
      return root
    end
  end
end

return {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", ".git" },
  -- Dependency crates have their own Cargo.toml, but they are part of the
  -- active project's crate graph. Keep them on that client so navigation
  -- within dependencies and the sysroot resolves in the same workspace.
  workspace_required = true,
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    if fname == "" then
      on_dir(nil)
      return
    end

    local cargo = vim.fs.find("Cargo.toml", { path = fname, upward = true })[1]
    local cargo_root = cargo and vim.fs.dirname(cargo)
    if not cargo_root then
      on_dir(nil)
      return
    end

    local project_root = active_project_root()

    if project_root and project_root ~= cargo_root then
      on_dir(project_root)
      return
    end

    on_dir(cargo_root)
  end,
  settings = {
    ["rust_analyzer"] = {
      cargo = {
        enable = true,
      },
    },
  },
}
