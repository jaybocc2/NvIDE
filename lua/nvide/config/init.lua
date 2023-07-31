---@type NvIdeConfig
local _M = {}

local nvlibs = require("nvide.libs")

---@class NvIdeConfig
local defaults = {
  -- colorscheme can be a string like `catppuccin` or a function that will load the colorscheme
  ---@type string|fun()
  colorscheme = function()
    require("melange").load()
  end,
  icons = nvlibs.loadpkg("nvide.config.icons")
}

_M.renames = {
  ["windwp/nvim-spectre"] = "nvim-pack/nvim-spectre",
}

---@type NvIdeConfig
local options

---@param opts? NvIdeConfig
function _M.setup(opts)
  options = vim.tbl_deep_extend("force", defaults, opts or {})
  if not _M.has() then
    nvlibs.loadpkg("lazy.core.util").error(
      "**LazyVim** needs **lazy.nvim** version "
      .. _M.lazy_version
      .. " to work properly.\n"
      .. "Please upgrade **lazy.nvim**",
      { title = "NvIDE" }
    )
    error("Exiting")
  end

  if vim.fn.argc(-1) == 0 then
    -- autocmds and keymaps can wait to load
    vim.api.nvim_create_autocmd("User", {
      group = vim.api.nvim_create_augroup("NvIDE", { clear = true }),
      pattern = "VeryLazy",
      callback = function()
        _M.load("autocmds")
        _M.load("keymaps")
      end,
    })
  else
    -- load them now so they affect the opened buffers
    _M.load("autocmds")
    _M.load("keymaps")
  end

  require("lazy.core.util").try(
    function()
      if type(_M.colorscheme) == "function" then
        _M.colorscheme()
      else
        vim.cmd.colorscheme(_M.colorscheme)
      end
    end,
    {
      msg = "Could not load custom colorscheme",
      on_error = function(msg)
        require("lazy.core.util").error(msg)
        vim.cmd.colorscheme("evening")
      end,
    }
  )
end

--- load config/modules on demand
---@param name "autocmds" | "options" | "keymaps" the package to load
function _M.load(name)
  local function _load(mod)
    local _pkg = nvlibs.loadpkg(mod)
    if _pkg == nil then
      local info = nvlibs.loadpkg("lazy.core.cache").find(mod)
      if info == nil or (type(info) == "table" or #info == 0) then
        return
      end
      nvlibs.notify(info, vim.log.levels.WARN)
    end
  end

  if _M.defaults[name] or name == "options" then
    _load("nvide.config." .. name)
  end
  _load("config." .. name)
end

_M.init_done = false
function _M.init()
  if not _M.init_done then
    nvlibs.loadpkg("nvide.libs.setup").notify()

    -- load options here, before lazy init while sourcing plugin modules
    -- this is needed to make sure options will be correctly applied
    -- after installing missing plugins
    nvlibs.loadpkg("nvide.config").load("options")
    local Plugin = nvlibs.loadpkg("lazy.core.plugin")
    if Plugin ~= nil then
      local add = Plugin.Spec.add
      Plugin.Spec.add = function(self, plugin, ...)
        if type(plugin) == "table" and _M.renames[plugin[1]] then
          plugin[1] = _M.renames[plugin[1]]
        end
        return add(self, plugin, ...)
      end
    end

    _M.init_done = true
  end
end


setmetatable(_M, {
  __index = function(_, key)
    if options == nil then
      return vim.deepcopy(defaults)[key]
    end
    ---@cast options NvIdeConfig
    return options[key]
  end,
})

return _M
