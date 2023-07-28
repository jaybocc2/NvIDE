local _M = {}

---Get and return caller info for error debugging
---@param t integer|nil stack object to grab callerinfo for default: 2 (the func that called this func)
---@return { src: string, src_path: string, caller: string, line: integer, name: string }
function _M.getcallerinfo(t)
  if not t then
    t = 2
  end
  local callerinfo = debug.getinfo(t, "nSl")
  local src_path, src = callerinfo.source:match(".*[/][.]config[/](.*[/])(.*[.]lua)$")
  local caller = src:match("(.*)[.]lua$")
  local name = "???"
  if callerinfo.name ~= nil then
    name = callerinfo.name
  end
  return {
    src = src,
    src_path = src_path,
    caller = caller,
    line = callerinfo.currentline,
    name = name,
  }
end

---vim notifications for notifying/alerting users w/ debug hints
---@param msg string
---@param level integer|nil
---@param opts table|nil
function _M.notify(msg, level, opts)
  -- get the function that called this function (3)
  local callerinfo = _M.getcallerinfo(3)

  -- if loadpkg is calling us we need to get next caller in the stack
  if callerinfo.name == "loadpkg" then
    callerinfo = _M.getcallerinfo(4)
  end

  local notify_msg = callerinfo.src_path .. callerinfo.src .. "::" .. callerinfo.line .. "::" .. callerinfo.name .. "() - " .. msg

  if level == nil then
    level = vim.log.levels.INFO
  end

  vim.notify(notify_msg, level, opts)
end

--- Safely load package and log error on failure
---@param pkg_name string the package to load
---@return table|nil the package or nil
function _M.loadpkg(pkg_name)
  local status_ok, package = pcall(require, pkg_name)
  if not status_ok then
    _M.notify("failed to load pkg - missing or not installed - " .. pkg_name, vim.log.levels.WARN)
    return nil
  end
  return package
end

--- get os type
---@return string the os type "osx|linux|other|unknown"
function _M.get_os_type()
  local homedir = os.getenv("HOME")
  local user = os.getenv("USER")
  local start_i = nil
  local end_i = nil

  if homedir == nil or user == nil then
    return "unknown"
  end

  start_i, end_i = string.find(homedir, "/home/" .. user)

  if start_i ~= nil and end_i ~= nil then
    return "linux"
  else
    start_i, end_i = string.find(homedir, "/Users/" .. user)
    if start_i ~= nil and end_i ~= nil then
      return "osx"
    else
      return "other"
    end
  end
end

---Get the full path to cache directory
---@return string
function _M.get_cache_dir()
  local cache_dir = os.getenv("NEOVIM_CACHE_DIR")
  if not cache_dir then
    return vim.fn.stdpath("cache")
  end
  return cache_dir
end

_M.setup = _M.loadpkg("nvide.libs.setup")

return _M
