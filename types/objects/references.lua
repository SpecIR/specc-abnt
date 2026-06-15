---REFERENCES - Referencias (ABNT)
---Per ABNT NBR 6023:2018 - mandatory, bibliography

local render_utils = require("pipeline.shared.render_utils")
local classes = require("models.abnt.shared.semantic_classes")

return {
    kind = "object",
    schema = {
        id = "REFERENCES",
        long_name = "References",
        description = "Referencias - bibliography section (ABNT NBR 6023:2018)",
        extends = "POST_TEXTUAL",
        is_required = true,
        implicit_aliases = { "Referências", "Referencias", "References", "Bibliography" },
        starts_on = "next"
    },
    hooks = {
        render = function(ctx)
            local blocks = {}

            -- Page break
            render_utils.add_page_break(blocks, ctx.subject.type_schema.starts_on)

            -- Header
            local title = "REFERENCIAS"
            local header_div = ctx.pandoc.Div({ctx.pandoc.Para({ctx.pandoc.Str(title)})})
            header_div.classes = {classes.UNNUMBERED_HEADING}
            render_utils.add_header_blocks(blocks, { header_div })

            -- Body: refs div placeholder for citeproc
            local refs_div = ctx.pandoc.Div({})
            refs_div.identifier = "refs"
            refs_div.classes = {"references", "csl-bib-body"}
            render_utils.add_blocks(blocks, { refs_div })

            return blocks
        end,
    },
}
