vim.g.mapleader = " "
vim.pack.add {
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/rcarriga/nvim-dap-ui',
  'https://github.com/nvim-neotest/nvim-nio',
}

local dap = require 'dap'
local dapui = require 'dapui'


vim.keymap.set('n', '<F5>', function()
  dap.continue()
end, { desc = 'Debug: Continue' })

vim.keymap.set('n', '<F9>', function()
  dap.close()
  dapui.close()
end, { desc = 'Debug: Close' })

vim.keymap.set('n', '<F8>', function()
  dap.step_over()
end, { desc = 'Debug: Step Over' })

vim.keymap.set('n', '<F7>', function()
  dap.step_into()
end, { desc = 'Debug: Step Into' })

vim.keymap.set('n', '<F6>', function()
  dap.step_out()
end, { desc = 'Debug: Step Out' })

vim.keymap.set('n', '<leader>b', function()
  dap.toggle_breakpoint()
end, { desc = 'Debug: Toggle Breakpoint' })

vim.keymap.set({ 'n', 'v' }, '<leader>i', function()
  dapui.eval()
  dapui.eval()
end, { desc = 'Debug: Evaluate expression (hover)' })

vim.keymap.set('n', '<leader>e', function()
  dapui.eval(vim.fn.input 'Expression: ', nil)
end, { desc = 'Debug: Evaluate expression (prompt)' })

dapui.setup {
  icons = { expanded = '▾', collapsed = '▸', current_frame = '▸' },
  controls = {
    enabled = true,
    element = 'repl',
    icons = {
      pause = '⏸',
      play = '▶',
      step_into = '⏎',
      step_over = '⏭',
      step_out = '⏮',
      step_back = '⏪',
      run_last = '▶▶',
      terminate = '⏹',
      disconnect = '⏏',
    },
  },
  layouts = {
    {
      -- left dock: variables on top (biggest), then watches, call stack,
      -- breakpoints -- mirrors IntelliJ's "Threads & Variables" panel
      elements = {
        { id = 'scopes', size = 0.45 },
        { id = 'watches', size = 0.20 },
        { id = 'stacks', size = 0.20 },
        { id = 'breakpoints', size = 0.15 },
      },
      size = 50,
      position = 'left',
    },
    {
      -- bottom dock: repl (with the controls toolbar attached) + console
      elements = {
        { id = 'repl', size = 0.5 },
        { id = 'console', size = 0.5 },
      },
      size = 12,
      position = 'bottom',
    },
  },

  floating = {
    max_height = 0.9,
    max_width = 0.5,
    border = 'rounded',
    mappings = { close = { 'q', '<Esc>' } },
  },

  render = {
    max_type_length = nil,
    max_value_lines = 100,
  },

  mappings = {
    expand = { 'zo'},
    open = 'o',
    remove = 'd',
    edit = 'e',
    repl = 'r',
    toggle = 't',
  },
}


dap.listeners.after.event_initialized['dapui_config'] = function()
  dapui.open()
end


local code_lldb_adapter_path = vim.fn.expand '~/.local/share/nvim/mason/packages/codelldb/extension/adapter/codelldb'
local go_adapter_path = vim.fn.expand '~/.local/share/nvim/mason/bin/dlv'
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
  local handler, _ = vim.uv.spawn(go_adapter_path, {
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

-- Configurations ---------------------------------------------------------

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
      return vim.fn.input('Executable name: ', vim.fn.getcwd())
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



-- Breakpoint / stopped-line signs -- colored dots like IntelliJ's gutter marks
vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
vim.fn.sign_define('DapBreakpointRejected', { text = '○', texthl = 'DapBreakpointRejected', linehl = '', numhl = '' })
vim.fn.sign_define('DapLogPoint', { text = '◆', texthl = 'DapLogPoint', linehl = '', numhl = '' })
vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'DapStopped', linehl = 'DapStoppedLine', numhl = '' })

vim.api.nvim_set_hl(0, 'DapBreakpoint', { fg = '#e51400' })
vim.api.nvim_set_hl(0, 'DapBreakpointCondition', { fg = '#e5a400' })
vim.api.nvim_set_hl(0, 'DapBreakpointRejected', { fg = '#888888' })
vim.api.nvim_set_hl(0, 'DapLogPoint', { fg = '#61afef' })
vim.api.nvim_set_hl(0, 'DapStopped', { fg = '#98c379' })
vim.api.nvim_set_hl(0, 'DapStoppedLine', { bg = '#31353f' })
