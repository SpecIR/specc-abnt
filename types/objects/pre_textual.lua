---PRE_TEXTUAL - Base type for pre-textual elements (ABNT)
---Per ABNT NBR 14724:2011 - unnumbered, optional in TOC

local M = {}

M.object = {
    id = "PRE_TEXTUAL",
    long_name = "Pre-textual Element",
    description = "Base type for ABNT pre-textual elements (elementos pre-textuais)",
    extends = "SECTION",
    numbered = false,
    section_type = "pretextual",
    header_style_id = "UnnumberedHeading",
    body_style_id = "Normal",
    starts_on = "next"  -- Start on next page (odd-page behavior deferred to postprocessor when twoside)
}

return M
