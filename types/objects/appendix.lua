---APPENDIX - Apendice (ABNT)
---Per ABNT NBR 14724:2011 - optional, author's supplementary material
---Uses letter numbering: APENDICE A, APENDICE B, etc.

local M = {}

M.object = {
    id = "APPENDIX",
    long_name = "Appendix",
    description = "Apendice - appendix with letter numbering (ABNT)",
    extends = "POST_TEXTUAL",
    implicit_aliases = { "Apêndice", "Apendice", "Appendix" },
    header_style_id = "AppendixHeading"
}

return M
