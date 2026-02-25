---ERRATA - Errata (ABNT)
---Per ABNT NBR 14724:2011 - Section 4.2.1.2
---Lists corrections to errors found after publication

local M = {}

M.object = {
    id = "ERRATA",
    long_name = "Errata",
    description = "Errata sheet - ABNT NBR 14724:2011",
    extends = "PRE_TEXTUAL",
    implicit_aliases = { "Errata", "Errata Sheet", "Folha de Errata" },
    header_style_id = "UnnumberedHeading",
    body_style_id = "BodyText"
}

return M
