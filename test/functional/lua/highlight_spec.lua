local helpers = require('test.functional.helpers')(after_each)
local exec_lua = helpers.exec_lua
local eq = helpers.eq
local neq = helpers.neq
local eval = helpers.eval
local command = helpers.command
local clear = helpers.clear
local api = helpers.api

describe('vim.highlight.on_yank', function()
  before_each(function()
    clear()
  end)

  it('does not show errors even if buffer is wiped before timeout', function()
    command('new')
    exec_lua([[
      vim.highlight.on_yank({timeout = 10, on_macro = true, event = {operator = "y", regtype = "v"}})
      vim.cmd('bwipeout!')
    ]])
    vim.uv.sleep(10)
    helpers.feed('<cr>') -- avoid hang if error message exists
    eq('', eval('v:errmsg'))
  end)

  it('does not close timer twice', function()
    exec_lua([[
      vim.highlight.on_yank({timeout = 10, on_macro = true, event = {operator = "y"}})
      vim.uv.sleep(10)
      vim.schedule(function()
        vim.highlight.on_yank({timeout = 0, on_macro = true, event = {operator = "y"}})
      end)
    ]])
    eq('', eval('v:errmsg'))
  end)

  it('does not show in another window', function()
    command('vsplit')
    exec_lua([[
      vim.api.nvim_buf_set_mark(0,"[",1,1,{})
      vim.api.nvim_buf_set_mark(0,"]",1,1,{})
      vim.highlight.on_yank({timeout = math.huge, on_macro = true, event = {operator = "y"}})
    ]])
    neq({}, api.nvim_win_get_ns(0))
    command('wincmd w')
    eq({}, api.nvim_win_get_ns(0))
  end)

  it('removes old highlight if new one is created before old one times out', function()
    command('vnew')
    exec_lua([[
      vim.api.nvim_buf_set_mark(0,"[",1,1,{})
      vim.api.nvim_buf_set_mark(0,"]",1,1,{})
      vim.highlight.on_yank({timeout = math.huge, on_macro = true, event = {operator = "y"}})
    ]])
    neq({}, api.nvim_win_get_ns(0))
    command('wincmd w')
    exec_lua([[
      vim.api.nvim_buf_set_mark(0,"[",1,1,{})
      vim.api.nvim_buf_set_mark(0,"]",1,1,{})
      vim.highlight.on_yank({timeout = math.huge, on_macro = true, event = {operator = "y"}})
    ]])
    command('wincmd w')
    eq({}, api.nvim_win_get_ns(0))
  end)
end)
