---TOC - Sumario (ABNT)
---Per ABNT NBR 14724:2011 and NBR 6027:2012 - Pre-textual element

local render_utils = require("pipeline.shared.render_utils")

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
        header_style_id = "TOCHeading",
        starts_on = "next"
    },
    hooks = {
        render = function(ctx)
            local blocks = {}

            -- Page break
            render_utils.add_page_break(blocks, "next")

            -- Header: "SUMÁRIO" with TOCHeading style
            -- Uses TOCHeading to prevent TOC header from appearing in the TOC itself
            local title = "SUMÁRIO"
            local header_div = ctx.pandoc.Div({ctx.pandoc.Para({ctx.pandoc.Str(title)})})
            header_div.classes = {"toc-heading"}
            render_utils.add_header_blocks(blocks, { header_div })

            -- Body: Generate TOC OOXML
            local toc_view = require("models.abnt.types.views.toc")
            local ooxml = toc_view.generate(ctx.data, ctx.spec_id, { manual = false, depth = 3 })
            if ooxml then
                render_utils.add_blocks(blocks, { ctx.pandoc.RawBlock("openxml", ooxml) })
            end

            return blocks
        end,
    },
}
