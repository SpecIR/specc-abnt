---CATALOG_SHEET - Ficha Catalografica (ABNT)
---Per ABNT NBR 14724:2011 - Section 4.2.1.1.2
---Contains bibliographic data for library cataloging

local render_utils = require("pipeline.shared.render_utils")

local M = {}

M.object = {
    id = "CATALOG_SHEET",
    long_name = "Ficha Catalográfica",
    description = "Cataloging sheet (Ficha Catalográfica) - ABNT NBR 14724:2011",
    extends = "PRE_TEXTUAL",
    implicit_aliases = {
        "Ficha Catalográfica",
        "Ficha catalográfica",
        "Ficha Catalográfica",
        "Catalog Sheet",
        "Cataloging Sheet"
    },
    header_style_id = "",  -- No visible header
    body_style_id = nil,
    attributes = {
        { name = "pdf_path", type = "STRING" }
    }
}

local function placeholder_div()
    return pandoc.Div({
        pandoc.Para({
            pandoc.Str("É possível elaborar a ficha catalográfica"),
            pandoc.LineBreak(),
            pandoc.Str("em LaTeX ou incluir a fornecida pela"),
            pandoc.LineBreak(),
            pandoc.Str("Biblioteca. Para tanto observe a"),
            pandoc.LineBreak(),
            pandoc.Str("programação contida nos arquivos USPSC-"),
            pandoc.LineBreak(),
            pandoc.Str("modelo.tex e fichacatalográfica.tex e/ou"),
            pandoc.LineBreak(),
            pandoc.Str("gere o arquivo fichacatalografica.pdf."),
            pandoc.LineBreak(),
            pandoc.LineBreak(),
            pandoc.Str("A biblioteca da sua Unidade lhe"),
            pandoc.LineBreak(),
            pandoc.Str("fornecerá um arquivo PDF com a ficha"),
            pandoc.LineBreak(),
            pandoc.Str("catalográfica definitiva, que deverá ser"),
            pandoc.LineBreak(),
            pandoc.Str("salvo como fichacatalografica.pdf no"),
            pandoc.LineBreak(),
            pandoc.Str("diretório do seu projeto."),
        }),
    }, pandoc.Attr("", {"catalog-sheet-placeholder"}, {}))
end

local function has_content(blocks)
    return blocks and #blocks > 0
end

function M.on_render_SpecObject(_obj, ctx)
    local blocks = {}

    render_utils.add_page_break(blocks, "next")

    if has_content(ctx.original_blocks) then
        render_utils.add_blocks(blocks, ctx.original_blocks)
    else
        render_utils.add_blocks(blocks, {
            placeholder_div(),
        })
    end

    return blocks
end

return M
