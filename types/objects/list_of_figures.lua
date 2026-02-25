---LIST_OF_FIGURES - Lista de Ilustracoes (ABNT)
---Per ABNT NBR 14724:2011 - optional, auto-generated list

local render_utils = require("pipeline.shared.render_utils")

local M = {}

M.name = "list_of_figures"

M.object = {
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
}

function M.on_render_SpecObject(obj, ctx)
    local blocks = {}

    -- Page break
    render_utils.add_page_break(blocks, M.object.starts_on)

    -- Header: "LISTA DE FIGURAS"
    local title = "LISTA DE FIGURAS"
    local header_div = pandoc.Div({pandoc.Para({pandoc.Str(title)})})
    header_div.classes = {"unnumbered-heading"}
    render_utils.add_header_blocks(blocks, { header_div })

    -- Body: Generate LOF OOXML
    local lof_view = require("models.abnt.types.views.lof")
    local ooxml = lof_view.generate(ctx.db, ctx.spec_id, { manual = true })
    if ooxml then
        render_utils.add_blocks(blocks, { pandoc.RawBlock("openxml", ooxml) })
    end

    return blocks
end

return M
