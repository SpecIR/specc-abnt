---LIST_OF_FIGURES - Lista de Ilustracoes (ABNT)
---Per ABNT NBR 14724:2011 - optional, auto-generated list

local render_utils = require("pipeline.shared.render_utils")
local lists = require("models.abnt.shared.pretextual_lists")
local classes = require("models.abnt.shared.semantic_classes")

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
        starts_on = "next"
    },
    hooks = {
        render = function(ctx)
            local blocks = {}

            -- Page break
            render_utils.add_page_break(blocks, ctx.subject.type_schema.starts_on)

            -- Header: "LISTA DE FIGURAS"
            local title = "LISTA DE FIGURAS"
            local header_div = ctx.pandoc.Div({ctx.pandoc.Para({ctx.pandoc.Str(title)})})
            header_div.classes = {classes.UNNUMBERED_HEADING}
            render_utils.add_header_blocks(blocks, { header_div })

            -- Body: Lista de Figuras (PAGEREF entries)
            local ooxml = lists.float_list_ooxml(ctx.data, ctx.spec_id,
                "FIGURE", "Figura", "Nenhuma figura encontrada.")
            render_utils.add_blocks(blocks, { ctx.pandoc.RawBlock("openxml", ooxml) })

            return blocks
        end,
    },
}
