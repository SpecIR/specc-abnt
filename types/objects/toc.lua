---TOC - Sumario (ABNT)
---Per ABNT NBR 14724:2011 and NBR 6027:2012 - Pre-textual element

local render_utils = require("pipeline.shared.render_utils")
local lists = require("models.abnt.shared.pretextual_lists")
local classes = require("models.abnt.shared.semantic_classes")

return {
    kind = "object",
    schema = {
        id = "TOC",
        long_name = "Sumario",
        description = "Table of Contents (Sumario) - ABNT NBR 6027:2012",
        extends = "PRE_TEXTUAL",
        implicit_aliases = { "Sumário", "Sumario", "Table of Contents", "TOC", "Contents" },
        numbered = false,
        section_type = "pretextual",
        starts_on = "next"
    },
    hooks = {
        render = function(ctx)
            local blocks = {}

            -- Page break
            render_utils.add_page_break(blocks, ctx.subject.type_schema.starts_on)

            -- Header: "SUMÁRIO" with TOCHeading style
            -- Uses TOCHeading to prevent TOC header from appearing in the TOC itself
            local title = "SUMÁRIO"
            local header_div = ctx.pandoc.Div({ctx.pandoc.Para({ctx.pandoc.Str(title)})})
            header_div.classes = {classes.TOC_HEADING}
            render_utils.add_header_blocks(blocks, { header_div })

            -- Body: Sumário (native Word auto-TOC field)
            local ooxml = lists.toc_ooxml({ depth = 3 })
            render_utils.add_blocks(blocks, { ctx.pandoc.RawBlock("openxml", ooxml) })

            return blocks
        end,
    },
}
