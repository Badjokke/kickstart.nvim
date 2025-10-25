return {
  'mfussenegger/nvim-dap',
  keys = {
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
    },
    {
      '<F10>',
      function()
        require('dap').step_over()
      end,
    },
    {
      '<F11>',
      function()
        require('dap').step_into()
      end,
    },
    {
      '<F12>',
      function()
        require('dap').step_out()
      end,
    },
    {
      '<leader>b',
      function()
        require('dap').toggle_breakpoint()
      end,
    },
  },
  config = function()
    local dapui = require 'dapui'
    local dap = require 'dap'

    dapui.setup()
    dap.listeners.after.event_initialized['dapui_config'] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated['dapui_config'] = function()
      dapui.open()
    end
    dap.listeners.before.event_exited['dapui_config'] = function()
      dapui.open()
    end

    local code_lldb = '~/.local/share/nvim/mason/packages/codelldb'
    local extension_path = code_lldb .. '/extension'
    local adapter_path = extension_path .. 'adapter/codelldb'
    local liblldb_path = extension_path .. 'lldb/lib/liblld.so'

    dap.adapters.lldb = {
      type = 'executable',
      command = adapter_path,
      name = 'lldb',
    }
    dap.configurations.rust = {
      {
        name = 'Debug Executable',
        type = 'lldb',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to executable', vim.fn.getcwd() .. '/target/debug', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = {},
      },
    }
  end,
  dependencies = { 'rcarriga/nvim-dap-ui', 'nvim-neotest/nvim-nio' },
}
