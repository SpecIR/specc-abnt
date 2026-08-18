---LIST_OF_LISTINGS - Lista de Listagens (ABNT)
---Per ABNT NBR 14724:2011 - optional, auto-generated list.
---
---Lists LISTING floats (framed code and preformatted text). Tabular quadros
---are a separate sequence -- see list_of_quadros.lua.

local render_utils = require("pipeline.shared.render_utils")
local lists = require("models.abnt.shared.pretextual_lists")
local classes = require("models.abnt.shared.semantic_classes")

return {
    kind = "object",
    schema = {
        id = "LIST_OF_LISTINGS",
        long_name = "List of Listings",
        description = "Lista de Listagens - auto-generated list of listings (ABNT)",
        extends = "PRE_TEXTUAL",
        implicit_aliases = { "Lista de Listagens", "List of Listings" },
        numbered = false,
        section_type = "pretextual",
        starts_on = "next"
    },
    hooks = {
        render = function(ctx)
            local blocks = {}

            -- Page break
            render_utils.add_page_break(blocks, ctx.subject.type_schema.starts_on)

            -- Header: "LISTA DE LISTAGENS"
            local title = "LISTA DE LISTAGENS"
            local header_div = ctx.pandoc.Div({ctx.pandoc.Para({ctx.pandoc.Str(title)})})
            header_div.classes = {classes.UNNUMBERED_HEADING}
            render_utils.add_header_blocks(blocks, { header_div })

            -- Body: Lista de Listagens (PAGEREF entries)
            local ooxml = lists.float_list_ooxml(ctx.data, ctx.spec_id,
                "LISTING", "Listagem", "Nenhuma listagem encontrada.")
            render_utils.add_blocks(blocks, { ctx.pandoc.RawBlock("openxml", ooxml) })

            return blocks
        end
    }
}
