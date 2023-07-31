require("nvide.config").init()

return {
  { "folke/lazy.nvim", version = "*" },
  { "jaybocc2/NvIDE", branch= "init", priority = 10000, lazy = false, config = true, cond = true, version = "*" },
}
