---ABNT Figure type override.
---Portuguese caption format for figures.
---@module abnt.figure

return {
    kind = "float",
    schema = {
        id = "FIGURE",
        long_name = "Figura",
        description = "Figura com legenda",
        caption_format = "Figura",
        counter_group = "FIGURE",
        aliases = { "fig", "imagem", "ilustracao" },
    },
    hooks = {},
}
