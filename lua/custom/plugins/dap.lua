return {
  'mfussenegger/nvim-dap',
  dependencies = { 'rcarriga/nvim-dap-ui', 'nvim-neotest/nvim-nio' },
  keys = {
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
    },
    {
      '<F9>',
      function()
        require('dap').close()
        require('dapui').close()
      end,
    },
    {
      '<F8>',
      function()
        require('dap').step_over()
      end,
    },
    {
      '<F7>',
      function()
        require('dap').step_into()
      end,
    },
    {
      '<F6>',
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

    local code_lldb_adapter_path = vim.fn.expand '~/.local/share/nvim/mason/packages/codelldb/extension/adapter/codelldb'
    local go_adapter_path = vim.fn.expand '/opt/homebrew/bin/dlv'
    local python_adapter = vim.fn.expand '~/.local/share/nvim/mason/packages/debugpy/debugpy-adapter'

    dap.adapters.python = function(cb, config)
      if config.request == 'attach' then
        cb {
          type = 'server',
          port = (config.connection or config).port,
          host = (config.connection or config).host,
          options = {
            source_filetype = 'python',
          },
        }
      else
        cb {
          type = 'executable',
          command = python_adapter,
          options = {
            source_filetype = 'python',
          },
        }
      end
    end

    dap.adapters.go = function(callback, config)
      if config.request == 'attach' and config.mode == 'remote' and config.host then
        callback {
          type = 'server',
          host = config.host,
          port = config.port,
        }
        return
      end

      local dap_port = 38666
      local addr = '127.0.0.1'
      local stdout = vim.uv.new_pipe(false)
      local stderr = vim.uv.new_pipe(false)
      handler, _ = vim.uv.spawn(go_adapter_path, {
        detached = true,
        args = { 'dap', '-l', addr .. ':' .. dap_port },
        stdio = { nil, stdout, stderr },
      }, function(code)
        print('exit code', code)
        handler:close()
        stdout:close()
        stderr:close()
        if code ~= 0 then
          print('dlv exited with code', code)
        end
      end)

      stdout:read_start(function(err, data)
        if data then
          vim.schedule(function()
            print('[stdout] ', data)
          end)
        end
      end)
      stderr:read_start(function(err, data)
        if data then
          vim.schedule(function()
            print('[stderr] ', data)
          end)
        end
      end)
      vim.defer_fn(function()
        callback { type = 'server', host = addr, port = dap_port }
      end, 1000)
    end

    dap.adapters.lldb = {
      type = 'executable',
      command = code_lldb_adapter_path,
      name = 'lldb',
    }

    dap.configurations.go = {
      {
        type = 'go',
        name = 'Launch Go module',
        request = 'launch',
        program = '${workspaceFolder}',
        console = 'integratedTerminal',
      },
      {
        type = 'go',
        name = 'Launch Go file',
        request = 'launch',
        program = '${file}',
        console = 'integratedTerminal',
      },
    }
    dap.configurations.rust = {
      {
        name = 'Debug Executable',
        type = 'lldb',
        request = 'launch',
        console = 'integratedTerminal',
        program = function()
          return vim.fn.input('Executable name', '/target/debug/' .. vim.fn.getcwd())
        end,
      },
    }
    dap.configurations.python = {
      {
        name = 'Launch file',
        type = 'python',
        request = 'launch',
        program = '${file}',
        console = 'integratedTerminal',
      },
      {
        type = 'python',
        request = 'launch',
        name = 'Launch file with arguments',
        program = '${file}',
        args = function()
          local args_string = vim.fn.input 'Arguments: '
          return vim.split(args_string, ' +')
        end,
        console = 'integratedTerminal',
      },
    }
  end,
}
