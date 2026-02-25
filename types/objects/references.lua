---REFERENCES - Referencias (ABNT)
---Per ABNT NBR 6023:2018 - mandatory, bibliography

local render_utils = require("pipeline.shared.render_utils")

local M = {}

M.name = "references"

M.object = {
    id = "REFERENCES",
    long_name = "References",
    description = "Referencias - bibliography section (ABNT NBR 6023:2018)",
    extends = "POST_TEXTUAL",
    is_required = true,
    implicit_aliases = { "Referências", "Referencias", "References", "Bibliography" },
    header_style_id = "UnnumberedHeading",
    body_style_id = "Reference",
    starts_on = "next"
}

function M.on_render_SpecObject(obj, ctx)
    local blocks = {}

    -- Page break
    render_utils.add_page_break(blocks, M.object.starts_on)

    -- Header
    local title = "REFERENCIAS"
    local header_div = pandoc.Div({pandoc.Para({pandoc.Str(title)})})
    header_div.classes = {"unnumbered-heading"}
    render_utils.add_header_blocks(blocks, { header_div })

    -- Body: refs div placeholder for citeproc
    local refs_div = pandoc.Div({})
    refs_div.identifier = "refs"
    refs_div.classes = {"references", "csl-bib-body"}
    render_utils.add_blocks(blocks, { refs_div })

    return blocks
end

return M
