---CATALOG_SHEET - Ficha Catalografica (ABNT)
---Per ABNT NBR 14724:2011 - Section 4.2.1.1.2
---Contains bibliographic data for library cataloging

local M = {}

M.object = {
    id = "CATALOG_SHEET",
    long_name = "Ficha Catalográfica",
    description = "Cataloging sheet (Ficha Catalográfica) - ABNT NBR 14724:2011",
    extends = "PRE_TEXTUAL",
    implicit_aliases = {
        "Ficha Catalográfica",
        "Ficha catalográfica",
        "Ficha Catalográfica",
        "Catalog Sheet",
        "Cataloging Sheet"
    },
    header_style_id = "",  -- No visible header
    body_style_id = nil,
    attributes = {
        { name = "pdf_path", type = "STRING" }
    }
}

return M
