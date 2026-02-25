---INDEX - Indice Remissivo (ABNT)
---Per ABNT NBR 6034 - optional, alphabetical index

local M = {}

M.object = {
    id = "INDEX",
    long_name = "Index",
    description = "Indice Remissivo - alphabetical index (ABNT NBR 6034)",
    extends = "POST_TEXTUAL",
    implicit_aliases = {
        "Índice",
        "Índice Remissivo",
        "Indice",
        "Indice Remissivo",
        "Index"
    },
    body_style_id = "Index"
}

return M
