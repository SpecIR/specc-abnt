---CONCLUSION - Conclusao (ABNT)
---Per ABNT NBR 14724:2011 - final textual chapter
---Starts on odd (right-hand) page per abntex2 \textual behavior

local render_utils = require("pipeline.shared.render_utils")

local M = {}

M.name = "conclusion"

M.object = {
    id = "CONCLUSION",
    long_name = "Conclusion",
    description = "Conclusao - conclusion chapter (ABNT)",
    extends = "TEXTUAL",
    is_required = true,  -- Mandatory per ABNT NBR 14724
    implicit_aliases = {
        "Conclusão",
        "Conclusao",
        "Conclusion",
        "Considerações Finais",
        "Consideracoes Finais"
    },
    starts_on = "next"  -- Start on next page (odd-page behavior deferred to postprocessor when twoside)
}

---Render conclusion chapter with odd page break.
---@param obj table Spec object
---@param ctx table Render context
---@return table blocks Array of Pandoc blocks
function M.on_render_SpecObject(obj, ctx)
    local blocks = {}

    -- Page break to odd page (matches abntex2 \textual behavior)
    render_utils.add_page_break(blocks, M.object.starts_on)

    -- Header: always level 1 (chapter-level textual element).
    -- obj.level inherits from the markdown heading (## = 2), but the assembler's
    -- normalize_header_levels() only shifts top-level Headers — not those inside
    -- spec-object-header Divs — so we must use the correct level directly.
    local level = 1
    local title = obj.title_text or "Conclusão"
    local header = pandoc.Header(level, {pandoc.Str(title)})
    header.attr = pandoc.Attr(obj.pid or "", {}, {["custom-style"] = "Heading1"})
    render_utils.add_header_blocks(blocks, header)

    -- Body: include original content blocks
    for _, block in ipairs(ctx.original_blocks or {}) do
        table.insert(blocks, block)
    end

    return blocks
end

return M
