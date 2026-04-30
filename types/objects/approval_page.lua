---APPROVAL_PAGE - Folha de Aprovacao (ABNT)
---Per ABNT NBR 14724:2011 - Section 4.2.1.3
---The approval page where the examining board records their approval

local render_utils = require("pipeline.shared.render_utils")

local M = {}

M.object = {
    id = "APPROVAL_PAGE",
    long_name = "Folha de Aprovação",
    description = "Approval page (Folha de Aprovação) - ABNT NBR 14724:2011",
    extends = "PRE_TEXTUAL",
    implicit_aliases = {
        "Folha de Aprovação",
        "Folha de aprovação",
        "Folha de Aprovacao",
        "Approval Page",
        "Approval"
    },
    header_style_id = "",  -- No visible header - uses custom OOXML layout
    body_style_id = nil,
    attributes = {
        { name = "approval_date", type = "STRING" },
        { name = "examiner", type = "STRING" },
        { name = "pdf_path", type = "STRING" }
    }
}

local function placeholder_div()
    return pandoc.Div({
        pandoc.Para({
            pandoc.Str("Folha de aprovação em conformidade"),
            pandoc.LineBreak(),
            pandoc.Str("com o padrão definido"),
            pandoc.LineBreak(),
            pandoc.Str("pela Unidade."),
            pandoc.LineBreak(),
            pandoc.Str("No presente modelo consta como"),
            pandoc.LineBreak(),
            pandoc.Str("folhadeaprovacao.pdf"),
        })
    }, pandoc.Attr("", {"approval-page-placeholder"}, {}))
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
