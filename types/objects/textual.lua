---TEXTUAL - Base type for textual elements (ABNT)
---Per ABNT NBR 14724:2011 - numbered chapters, in TOC

local M = {}

M.object = {
    id = "TEXTUAL",
    long_name = "Textual Element",
    description = "Base type for ABNT textual elements (elementos textuais)",
    extends = "SECTION",
    header_style_id = "Heading1",
    body_style_id = "Normal"
}

return M
