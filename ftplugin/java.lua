local lombok_path = vim.fn.expand '~/.local/share/nvim/mason/packages/jdtls/lombok.jar'
local dap_path = vim.fn.expand '~/.local/share/nvim/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar'
local test_path = vim.fn.expand '~/.local/share/nvim/mason/packages/java-test/extension/server/com.microsoft.java.test.plugin-*.jar'

local function glob_list(pattern)
  local items = vim.fn.glob(pattern, true, true)
  if type(items) == 'string' then
    return items == '' and {} or { items }
  end
  return items or {}
end

local bundles = {}
vim.list_extend(bundles, glob_list(dap_path))
vim.list_extend(bundles, glob_list(test_path))
local root_dir = vim.fs.root(0, { '.git' })
if not root_dir then
  return
end
local project_dir = vim.fs.root(0, { 'mvnw', 'gradlew' })
local project_name = vim.fn.fnamemodify(root_dir, ':p:t:h')

local function get_data_dir()
  local workspace_dir = vim.fn.expand '~/development/jdtls_data'
  local data_dir = workspace_dir .. '/' .. string.gsub(vim.fn.getcwd(), '/', '_')
  return data_dir
end

local config = {
  name = 'jdtls',
  project_name = project_name,
  root_dir = root_dir,
  -- The command that starts the language server
  -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
  cmd = {
    -- 💀
    '/usr/bin/java', -- or '/path/to/java17_or_newer/bin/java'
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xmx2g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',
    '-javaagent:' .. lombok_path,
    -- 💀
    '-jar',
    vim.fn.glob '~/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar',
    -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^                                       ^^^^^^^^^^^^^^
    -- Must point to the                                                     Change this to
    -- eclipse.jdt.ls installation                                           the actual version
    -- 💀
    '-configuration',
    vim.fn.expand '~/.local/share/nvim/mason/packages/jdtls/config_mac',
    -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^        ^^^^^^
    -- Must point to the                      Change to one of `linux`, `win` or `mac`
    -- eclipse.jdt.ls installation            Depending on your system.

    -- 💀
    -- See `data directory configuration` section in the README
    '-data',
    get_data_dir(),
  },
  -- 💀
  -- This is the default if not provided, you can remove it. Or adjust as needed.
  -- One dedicated LSP server & client will be started per unique root_dir

  -- Here you can configure eclipse.jdt.ls specific settings
  -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
  -- for a list of options
  settings = {
    java = {
      compilation = {
        annotationProcessing = { enabled = true },
      },
      autobuild = { enabled = true },
      maven = { downloadSources = true },
      inlayHints = {
        parameterNames = { enabled = 'all' },
      },
      signatureHelp = { enabled = true },
      implementationsCodeLens = { enabled = true },
    },
  },
  -- Language server `initializationOptions`
  -- You need to extend the `bundles` with paths to jar files
  -- if you want to use additional eclipse.jdt.ls plugins.
  --
  -- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
  --
  -- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
  init_options = {
    bundles = bundles,
  },
}
-- This starts a new client & server,
-- or attaches to an existing client & server depending on the `root_dir`.
require('jdtls').start_or_attach(config)
