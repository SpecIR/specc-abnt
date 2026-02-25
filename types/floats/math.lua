---ABNT Math type override.
---Portuguese caption format for equations.
---Inherits external_render from default/types/floats/math.lua
---@module abnt.math

local M = {}

M.float = {
    id = "MATH",
    long_name = "Equação",
    description = "Equação matemática",
    caption_format = "Equação",
    counter_group = "EQUATION",
    aliases = { "math", "eq", "equation", "formula", "equacao", "asciimath" },
    needs_external_render = true,  -- Processed by external_render_handler
}

return M
