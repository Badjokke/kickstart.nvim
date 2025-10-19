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
  end,
  dependencies = { 'rcarriga/nvim-dap-ui', 'nvim-neotest/nvim-nio' },
}
