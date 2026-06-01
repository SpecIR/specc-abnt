---POST_TEXTUAL - Base type for post-textual elements (ABNT)
---Per ABNT NBR 14724:2011 - may be unnumbered, in TOC

return {
    kind = "object",
    schema = {
        id = "POST_TEXTUAL",
        long_name = "Post-textual Element",
        description = "Base type for ABNT post-textual elements (elementos pos-textuais)",
        extends = "SECTION",
        header_style_id = "UnnumberedHeading",
        body_style_id = "Normal"
    },
    hooks = {}
}
