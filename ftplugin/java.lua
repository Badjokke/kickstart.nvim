local jdtls = require 'jdtls'

-- Paths -----------------------------------------------------------------

local lombok_path = vim.fn.expand '~/.local/share/nvim/mason/share/jdtls/lombok.jar'

-- vim.fn.glob(..., true, true) returns a Lua list directly and resolves the
-- wildcard, instead of the expand()+glob() double-step the old config used.
local dap_main_class_jar = vim.fn.glob('~/.local/share/nvim/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar', true, true)
local test_jars = vim.fn.glob('~/.local/share/nvim/mason/packages/java-test/extension/server/*.jar', true, true)

-- NOTE on the original config: it had
--   vim.list_extend(bundles, vim.fn.split(test_path, '\n', false))
-- sitting as a bare array entry *inside* the `config = { ... }` table
-- constructor. It happened to still work (Lua evaluates it and mutates
-- `bundles` in place before `init_options.bundles = bundles` runs), but it's
-- a side-effecting statement, not table data -- easy to trip over later.
-- Building `bundles` fully before `config` avoids that trap.
local bundles = {}
vim.list_extend(bundles, dap_main_class_jar)
vim.list_extend(bundles, test_jars)

local root_markers = { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' }
local root_dir = require('jdtls.setup').find_root(root_markers)
local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')
local workspace_dir = vim.fn.expand('~/development/jdtls_data/' .. project_name)

-- Capabilities ------------------------------------------------------------

local capabilities = require('blink.cmp').get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities())

local config = {
  name = 'jdtls',
  project_name = project_name,
  root_dir = root_dir,
  capabilities = capabilities,

  -- The command that starts the language server
  cmd = {
    -- 💀
    '/usr/lib/jvm/java-21-openjdk-amd64/bin/java', -- or '/path/to/java17_or_newer/bin/java'
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
    vim.fn.expand '~/.local/share/nvim/mason/packages/jdtls/config_linux',
    -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^        ^^^^^^
    -- Must point to the                      Change to one of `linux`, `win` or `mac`
    -- eclipse.jdt.ls installation            Depending on your system.
    -- 💀
    -- See `data directory configuration` section in the README
    '-data',
    workspace_dir,
  },

  -- eclipse.jdt.ls specific settings
  -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
  settings = {
    java = {
      compilation = {
        annotationProcessing = { enabled = true },
      },
      signatureHelp = { enabled = true },
    },
  },

  -- Language server `initializationOptions` -- extend `bundles` with more
  -- jar paths if you add other eclipse.jdt.ls plugins.
  -- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
  init_options = {
    bundles = bundles,
  },

  -- Wires jdtls-specific commands and DAP once the client actually attaches
  -- to this buffer -- new vs. the original, which had none of this.
  on_attach = function(_, bufnr)
    local opts = { buffer = bufnr, silent = true }

    vim.keymap.set('n', 'gro', jdtls.organize_imports, vim.tbl_extend('force', opts, { desc = 'Java: Organize Imports' }))
    vim.keymap.set('n', 'gre', jdtls.extract_variable, vim.tbl_extend('force', opts, { desc = 'Java: Extract Variable' }))
    vim.keymap.set('v', 'grm', function()
      jdtls.extract_method(true)
    end, vim.tbl_extend('force', opts, { desc = 'Java: Extract Method' }))
    vim.keymap.set('n', '<leader>tc', jdtls.test_class, vim.tbl_extend('force', opts, { desc = 'Java: Test Class' }))
    vim.keymap.set('n', '<leader>tm', jdtls.test_nearest_method, vim.tbl_extend('force', opts, { desc = 'Java: Test Nearest Method' }))

    -- Hooks jdtls into the nvim-dap setup from dap.lua: adds the Java debug
    -- adapter and auto-generates run configs for classes with a main method.
    jdtls.setup_dap { hotcodereplace = 'auto' }
    require('jdtls.dap').setup_dap_main_class_configs()
  end,
}

-- This starts a new client & server, or attaches to an existing one,
-- depending on `root_dir`. One dedicated client/server per unique root_dir.
jdtls.start_or_attach(config)
