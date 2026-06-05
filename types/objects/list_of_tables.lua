---LIST_OF_TABLES - Lista de Tabelas (ABNT)
---Per ABNT NBR 14724:2011 - optional, auto-generated list

local render_utils = require("pipeline.shared.render_utils")
local lists = require("models.abnt.shared.pretextual_lists")
local classes = require("models.abnt.shared.semantic_classes")

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
        starts_on = "next"
    },
    hooks = {
        render = function(ctx)
            local blocks = {}

            -- Page break
            render_utils.add_page_break(blocks, ctx.subject.type_schema.starts_on)

            -- Header: "LISTA DE TABELAS"
            local title = "LISTA DE TABELAS"
            local header_div = ctx.pandoc.Div({ctx.pandoc.Para({ctx.pandoc.Str(title)})})
            header_div.classes = {classes.UNNUMBERED_HEADING}
            render_utils.add_header_blocks(blocks, { header_div })

            -- Body: Lista de Tabelas (PAGEREF entries)
            local ooxml = lists.float_list_ooxml(ctx.data, ctx.spec_id,
                "TABLE", "Tabela", "Nenhuma tabela encontrada.")
            render_utils.add_blocks(blocks, { ctx.pandoc.RawBlock("openxml", ooxml) })

            return blocks
        end
    }
}
