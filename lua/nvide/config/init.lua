local _M = {}

local nvlibs = require("nvide.libs")

---@class NvIdeConfig
local defaults = {
  icons = nvlibs.loadpkg("nvide.config.icons")
}

_M.renames = {
  ["windwp/nvim-spectre"] = "nvim-pack/nvim-spectre",
}

--- load config/modules on demand
---@param name "autocmd" | "options" | "keymap" the package to load
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

return _M
