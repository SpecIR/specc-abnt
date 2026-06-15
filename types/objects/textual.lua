---TEXTUAL - Base type for textual elements (ABNT)
---Per ABNT NBR 14724:2011 - numbered chapters, in TOC

return {
    kind = "object",
    schema = {
        id = "TEXTUAL",
        long_name = "Textual Element",
        description = "Base type for ABNT textual elements (elementos textuais)",
        extends = "SECTION",
    },
    hooks = {}
}
