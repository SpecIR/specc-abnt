---ABNT Figure type override.
---Portuguese caption format for figures.
---@module abnt.figure

local M = {}

M.float = {
    id = "FIGURE",
    long_name = "Figura",
    description = "Figura com legenda",
    caption_format = "Figura",
    counter_group = "FIGURE",
    aliases = { "fig", "imagem", "ilustracao" },
}

return M
