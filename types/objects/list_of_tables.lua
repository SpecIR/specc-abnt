---LIST_OF_TABLES - Lista de Tabelas (ABNT)
---Per ABNT NBR 14724:2011 - optional, auto-generated list

local render_utils = require("pipeline.shared.render_utils")

return {
    kind = "object",
    schema = {
        id = "LIST_OF_TABLES",
        long_name = "List of Tables",
        description = "Lista de Tabelas - auto-generated list of tables (ABNT)",
        extends = "PRE_TEXTUAL",
        implicit_aliases = { "Lista de Tabelas", "List of Tables" },
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

            -- Header: "LISTA DE TABELAS"
            local title = "LISTA DE TABELAS"
            local header_div = ctx.pandoc.Div({ctx.pandoc.Para({ctx.pandoc.Str(title)})})
            header_div.classes = {"unnumbered-heading"}
            render_utils.add_header_blocks(blocks, { header_div })

            -- Body: Generate LOT OOXML
            local lot_view = require("models.abnt.types.views.lot")
            local ooxml = lot_view.generate(ctx.data, ctx.spec_id, { manual = true })
            if ooxml then
                render_utils.add_blocks(blocks, { ctx.pandoc.RawBlock("openxml", ooxml) })
            end

            return blocks
        end
    }
}
