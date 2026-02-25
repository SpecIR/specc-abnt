---ABNT PlantUML type override.
---Portuguese caption format, shares counter with FIGURE.
---@module abnt.plantuml

local M = {}

M.float = {
    id = "PLANTUML",
    long_name = "Diagrama",
    description = "Diagrama UML gerado via PlantUML",
    caption_format = "Figura",    -- Displays as "Figura" (shared with FIGURE)
    counter_group = "FIGURE",     -- Shares numbering with FIGURE
    aliases = { "puml", "uml", "diagrama" },
    needs_external_render = true,
}

return M
