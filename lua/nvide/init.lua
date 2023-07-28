local _M = {}

---@param opts? NvIdeConfig
function _M.setup(opts)
  require("nvide.config").setup(opts)
end

return _M
