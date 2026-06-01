---ABNT Math type override.
---Portuguese caption format for equations.
---Inherits native emit-time math rendering from default/types/floats/math.lua
---@module abnt.math

return {
    kind = "float",
    schema = {
        id = "MATH",
        long_name = "Equação",
        description = "Equação matemática",
        caption_format = "Equação",
        counter_group = "EQUATION",
        aliases = { "math", "eq", "equation", "formula", "equacao", "asciimath" },
        -- Native Pandoc math is produced by the default MATH handler during EMIT.
        needs_external_render = false,
        style_id = "MATH",
    },
    hooks = {},
}
