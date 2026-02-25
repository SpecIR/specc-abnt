---LIST_OF_TABLES - Lista de Tabelas (ABNT)
---Per ABNT NBR 14724:2011 - optional, auto-generated list

local render_utils = require("pipeline.shared.render_utils")

local M = {}

M.name = "list_of_tables"

M.object = {
    id = "LIST_OF_TABLES",
    long_name = "List of Tables",
    description = "Lista de Tabelas - auto-generated list of tables (ABNT)",
    extends = "PRE_TEXTUAL",
    implicit_aliases = { "Lista de Tabelas", "List of Tables" },
    numbered = false,
    section_type = "pretextual",
    header_style_id = "UnnumberedHeading",
    starts_on = "next"
}

function M.on_render_SpecObject(obj, ctx)
    local blocks = {}

    -- Page break
    render_utils.add_page_break(blocks, M.object.starts_on)

    -- Header: "LISTA DE TABELAS"
    local title = "LISTA DE TABELAS"
    local header_div = pandoc.Div({pandoc.Para({pandoc.Str(title)})})
    header_div.classes = {"unnumbered-heading"}
    render_utils.add_header_blocks(blocks, { header_div })

    -- Body: Generate LOT OOXML
    local lot_view = require("models.abnt.types.views.lot")
    local ooxml = lot_view.generate(ctx.db, ctx.spec_id, { manual = true })
    if ooxml then
        render_utils.add_blocks(blocks, { pandoc.RawBlock("openxml", ooxml) })
    end

    return blocks
end

return M
