-- local Util = require("lazy.core.util")

local _M = {}

_M.root_patterns = { ".git", "lua" }

-- delay notifications till vim.notify was replaced or after 500ms
function _M.notify()
  local messages = {}
  local function temp(...)
    table.insert(messages, vim.F.pack_len(...))
  end

  local orig = vim.notify
  vim.notify = temp

  local timer = vim.uv.new_timer()
  local check = vim.uv.new_check()

  local replay = function()
    if timer ~= nil then timer:stop() end
    if check ~= nil then check:stop() end
    if vim.notify == temp then
      vim.notify = orig -- put back the original notify if we failed to get nvim-notify plugin
    end
    vim.schedule(function()
      for _, notif in ipairs(messages) do
        vim.notify(vim.F.unpack_len(notif))
      end
    end)
  end

  -- short circuit if notify plugin is replaced w/ nvim-notify
  if check ~= nil then
    check:start(function()
      if vim.notify ~= temp then
        replay()
      end
    end)
  end
  -- or if it took more than 500ms, then something probably went wrong
  if timer ~= nil then timer:start(500, 0, replay) end
end

-- function _M.init_lazy()
--   local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
--   if not vim.loop.fs_stat(lazypath) then
--     vim.fn.system({
--       "git",
--       "clone",
--       "--filter=blob:none",
--       "https://github.com/folke/lazy.nvim.git",
--       "--branch=stable", -- latest stable release
--       lazypath,
--     })
--   end
--   vim.opt.rtp:prepend(lazypath)
-- end

return _M
