---AGRADECIMENTOS (ABNT)
---Per ABNT NBR 14724:2011 - optional element
---
---Uses semantic markers converted by format-specific filters.

local render_utils = require("pipeline.shared.render_utils")

return {
    kind = "object",
    schema = {
        id = "AGRADECIMENTOS",
        long_name = "Agradecimentos",
        description = "Agradecimentos - acknowledgments page (ABNT)",
        extends = "PRE_TEXTUAL",
        implicit_aliases = { "Agradecimentos", "Acknowledgments", "Acknowledgements" },
        numbered = false,
        section_type = "pretextual",
        header_style_id = "UnnumberedHeading",
        starts_on = "next"  -- Start on next page (odd-page behavior deferred to postprocessor when twoside)
    },
    hooks = {
        render = function(ctx)
            local obj = ctx.subject.object
            local blocks = {}

            -- Page break
            render_utils.add_page_break(blocks, ctx.subject.type_schema.starts_on)

            -- Header
            local title = obj and obj.title_text or "Agradecimentos"
            local header_div = ctx.pandoc.Div({ctx.pandoc.Para({ctx.pandoc.Str(title:upper())})})
            header_div.classes = {"unnumbered-heading"}
            render_utils.add_header_blocks(blocks, { header_div })

            -- Body: pass through original blocks (skip headers)
            local body_blocks = {}
            for _, block in ipairs(ctx.subject.element or {}) do
                if block.t ~= "Header" then
                    table.insert(body_blocks, block)
                end
            end
            render_utils.add_blocks(blocks, body_blocks)

            return blocks
        end,
    },
}
