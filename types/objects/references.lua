---REFERENCES - Referencias (ABNT)
---Per ABNT NBR 6023:2018 - mandatory, bibliography

local render_utils = require("pipeline.shared.render_utils")

return {
    kind = "object",
    schema = {
        id = "REFERENCES",
        long_name = "References",
        description = "Referencias - bibliography section (ABNT NBR 6023:2018)",
        extends = "POST_TEXTUAL",
        is_required = true,
        implicit_aliases = { "Referências", "Referencias", "References", "Bibliography" },
        header_style_id = "UnnumberedHeading",
        body_style_id = "Reference",
        starts_on = "next"
    },
    hooks = {
        render = function(ctx)
            local obj = ctx.subject.object
            local blocks = {}

            -- Page break
            render_utils.add_page_break(blocks, "next")

            -- Header
            local title = "REFERENCIAS"
            local header_div = ctx.pandoc.Div({ctx.pandoc.Para({ctx.pandoc.Str(title)})})
            header_div.classes = {"unnumbered-heading"}
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
