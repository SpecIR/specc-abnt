---APPROVAL_PAGE - Folha de Aprovacao (ABNT)
---Per ABNT NBR 14724:2011 - Section 4.2.1.3
---The approval page where the examining board records their approval

local M = {}

M.object = {
    id = "APPROVAL_PAGE",
    long_name = "Folha de Aprovação",
    description = "Approval page (Folha de Aprovação) - ABNT NBR 14724:2011",
    extends = "PRE_TEXTUAL",
    implicit_aliases = {
        "Folha de Aprovação",
        "Folha de aprovação",
        "Folha de Aprovacao",
        "Approval Page",
        "Approval"
    },
    header_style_id = "",  -- No visible header - uses custom OOXML layout
    body_style_id = nil,
    attributes = {
        { name = "approval_date", type = "STRING" },
        { name = "examiner", type = "STRING" },
        { name = "pdf_path", type = "STRING" }
    }
}

return M
