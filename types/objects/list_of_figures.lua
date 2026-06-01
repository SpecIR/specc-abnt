---LIST_OF_FIGURES - Lista de Ilustracoes (ABNT)
---Per ABNT NBR 14724:2011 - optional, auto-generated list

local render_utils = require("pipeline.shared.render_utils")

return {
    kind = "object",
    schema = {
        id = "LIST_OF_FIGURES",
        long_name = "List of Figures",
        description = "Lista de Ilustracoes - auto-generated list of figures (ABNT)",
        extends = "PRE_TEXTUAL",
        implicit_aliases = {
            "Lista de Ilustracoes",
            "Lista de Ilustracoes",
            "Lista de Figuras",
            "List of Figures"
        },
        numbered = false,
        section_type = "pretextual",
        header_style_id = "UnnumberedHeading",
        starts_on = "next"
    },
    hooks = {
        render = function(ctx)
            local blocks = {}

            -- Page break
            render_utils.add_page_break(blocks, "next")

            -- Header: "LISTA DE FIGURAS"
            local title = "LISTA DE FIGURAS"
            local header_div = ctx.pandoc.Div({ctx.pandoc.Para({ctx.pandoc.Str(title)})})
            header_div.classes = {"unnumbered-heading"}
            render_utils.add_header_blocks(blocks, { header_div })

            -- Body: Generate LOF OOXML
            local lof_view = require("models.abnt.types.views.lof")
            local ooxml = lof_view.generate(ctx.data, ctx.spec_id, { manual = true })
            if ooxml then
                render_utils.add_blocks(blocks, { ctx.pandoc.RawBlock("openxml", ooxml) })
            end

            return blocks
        end,
    },
}
