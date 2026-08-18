---LIST_OF_QUADROS - Lista de Quadros (ABNT)
---Per ABNT NBR 14724:2011 - optional, auto-generated list.
---
---Lists QUADRO_TABLE floats (tabular quadros). Code and preformatted listings
---are a separate sequence -- see list_of_listings.lua.

local render_utils = require("pipeline.shared.render_utils")
local lists = require("models.abnt.shared.pretextual_lists")
local classes = require("models.abnt.shared.semantic_classes")

return {
    kind = "object",
    schema = {
        id = "LIST_OF_QUADROS",
        long_name = "List of Quadros",
        description = "Lista de Quadros - auto-generated list of quadros (ABNT)",
        extends = "PRE_TEXTUAL",
        implicit_aliases = { "Lista de Quadros", "List of Quadros" },
        numbered = false,
        section_type = "pretextual",
        starts_on = "next"
    },
    hooks = {
        render = function(ctx)
            local blocks = {}

            -- Page break
            render_utils.add_page_break(blocks, ctx.subject.type_schema.starts_on)

            -- Header: "LISTA DE QUADROS"
            local title = "LISTA DE QUADROS"
            local header_div = ctx.pandoc.Div({ctx.pandoc.Para({ctx.pandoc.Str(title)})})
            header_div.classes = {classes.UNNUMBERED_HEADING}
            render_utils.add_header_blocks(blocks, { header_div })

            -- Body: Lista de Quadros (PAGEREF entries)
            local ooxml = lists.float_list_ooxml(ctx.data, ctx.spec_id,
                "QUADRO", "Quadro", "Nenhum quadro encontrado.")
            render_utils.add_blocks(blocks, { ctx.pandoc.RawBlock("openxml", ooxml) })

            return blocks
        end
    }
}
