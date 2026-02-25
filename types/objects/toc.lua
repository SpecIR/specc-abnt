---TOC - Sumario (ABNT)
---Per ABNT NBR 14724:2011 and NBR 6027:2012 - Pre-textual element

local render_utils = require("pipeline.shared.render_utils")

local M = {}

M.name = "toc"

M.object = {
    id = "TOC",
    long_name = "Sumario",
    description = "Table of Contents (Sumario) - ABNT NBR 6027:2012",
    extends = "PRE_TEXTUAL",
    implicit_aliases = { "Sumário", "Sumario", "Table of Contents", "TOC", "Contents" },
    numbered = false,
    section_type = "pretextual",
    header_style_id = "TOCHeading",
    starts_on = "next"
}

function M.on_render_SpecObject(obj, ctx)
    local blocks = {}

    -- Page break
    render_utils.add_page_break(blocks, M.object.starts_on)

    -- Header: "SUMÁRIO" with TOCHeading style
    -- Uses TOCHeading to prevent TOC header from appearing in the TOC itself
    local title = "SUMÁRIO"
    local header_div = pandoc.Div({pandoc.Para({pandoc.Str(title)})})
    header_div.classes = {"toc-heading"}
    render_utils.add_header_blocks(blocks, { header_div })

    -- Body: Generate TOC OOXML
    local toc_view = require("models.abnt.types.views.toc")
    local ooxml = toc_view.generate(ctx.db, ctx.spec_id, { manual = false, depth = 3 })
    if ooxml then
        render_utils.add_blocks(blocks, { pandoc.RawBlock("openxml", ooxml) })
    end

    return blocks
end

return M
