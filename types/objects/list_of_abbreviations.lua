---LIST_OF_ABBREVIATIONS - Lista de Siglas (ABNT)
---Per ABNT NBR 14724:2011 - optional, user-provided list
---
---Uses semantic markers converted by format-specific filters.

local render_utils = require("pipeline.shared.render_utils")

local M = {}

M.name = "list_of_abbreviations"

M.object = {
    id = "LIST_OF_ABBREVIATIONS",
    long_name = "List of Abbreviations",
    description = "Lista de Abreviaturas e Siglas - list of abbreviations (ABNT)",
    extends = "PRE_TEXTUAL",
    implicit_aliases = {
        "Lista de Abreviaturas e Siglas",
        "Lista de Abreviaturas",
        "Lista de Siglas",
        "List of Abbreviations"
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

    -- Header: "LISTA DE ABREVIATURAS E SIGLAS"
    local title = "LISTA DE ABREVIATURAS E SIGLAS"
    local header_div = pandoc.Div({pandoc.Para({pandoc.Str(title)})})
    header_div.classes = {"unnumbered-heading"}
    render_utils.add_header_blocks(blocks, { header_div })

    -- Body: Generate abbreviation list using default abbrev module
    local ok, abbrev_view = pcall(require, "models.default.types.views.abbrev")
    if ok and abbrev_view and abbrev_view.generate_list_ooxml then
        local ooxml = abbrev_view.generate_list_ooxml(ctx.db, ctx.spec_id)
        if ooxml then
            render_utils.add_blocks(blocks, { pandoc.RawBlock("openxml", ooxml) })
            return blocks
        end
    end

    -- Fallback: pass through original content
    local body_blocks = {}
    for _, block in ipairs(ctx.original_blocks or {}) do
        if block.t ~= "Header" then
            table.insert(body_blocks, block)
        end
    end
    render_utils.add_blocks(blocks, body_blocks)

    return blocks
end

return M
