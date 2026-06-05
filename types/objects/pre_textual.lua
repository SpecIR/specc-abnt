---PRE_TEXTUAL - Base type for pre-textual elements (ABNT)
---Per ABNT NBR 14724:2011 - unnumbered, optional in TOC

return {
    kind = "object",
    schema = {
        id = "PRE_TEXTUAL",
        long_name = "Pre-textual Element",
        description = "Base type for ABNT pre-textual elements (elementos pre-textuais)",
        extends = "SECTION",
        numbered = false,
        section_type = "pretextual",
        starts_on = "next"  -- Start on next page (odd-page behavior deferred to postprocessor when twoside)
    },
    hooks = {}
}
