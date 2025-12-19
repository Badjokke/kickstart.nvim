return {
  'https://github.com/tpope/vim-fugitive',

  keys = {
    {
      'GS',
      function()
        vim.fn.execute ':Gvdiffsplit!'
      end,
      mode = 'n',
      desc = 'three way split',
    },
    {
      'GM',
      function()
        vim.fn.execute(':G merge ' .. vim.fn.input 'branch name', '')
      end,
      mode = 'n',
      desc = 'merge',
    },
  },
}
