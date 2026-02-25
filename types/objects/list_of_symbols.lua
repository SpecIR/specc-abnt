---LIST_OF_SYMBOLS - Lista de Simbolos (ABNT)
---Per ABNT NBR 14724:2011 - optional, user-provided list

local M = {}

M.object = {
    id = "LIST_OF_SYMBOLS",
    long_name = "List of Symbols",
    description = "Lista de Simbolos - list of symbols (ABNT)",
    extends = "PRE_TEXTUAL",
    implicit_aliases = {
        "Lista de Símbolos",
        "Lista de Simbolos",
        "List of Symbols"
    },
    header_style_id = "UnnumberedHeading"
}

return M
