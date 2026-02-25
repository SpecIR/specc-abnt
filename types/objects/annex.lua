---ANNEX - Anexo (ABNT)
---Per ABNT NBR 14724:2011 - optional, external supplementary material
---Uses letter numbering: ANEXO A, ANEXO B, etc.

local M = {}

M.object = {
    id = "ANNEX",
    long_name = "Annex",
    description = "Anexo - annex with letter numbering (ABNT)",
    extends = "POST_TEXTUAL",
    implicit_aliases = { "Anexo", "Annex" },
    header_style_id = "AnnexHeading"
}

return M
