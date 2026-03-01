---ANNEX - Anexo (ABNT)
---Per ABNT NBR 14724:2011 - optional, external supplementary material
---Uses letter numbering: ANEXO A, ANEXO B, etc.

local render_utils = require("pipeline.shared.render_utils")

local M = {}

M.name = "annex"

M.object = {
    id = "ANNEX",
    long_name = "Annex",
    description = "Anexo - annex with letter numbering (ABNT)",
    extends = "POST_TEXTUAL",
    implicit_aliases = { "Anexo", "Annex" },
    header_style_id = "AnnexHeading",
    starts_on = "next"
}

---Render annex section with AnnexHeading style.
---Formats title as "ANEXO A – Title" per ABNT NBR 14724:2011.
---@param obj table Spec object
---@param ctx table Render context
---@return table blocks Array of Pandoc blocks
function M.on_render_SpecObject(obj, ctx)
    local blocks = {}

    -- Page break
    render_utils.add_page_break(blocks, M.object.starts_on)

    -- Determine letter index by counting siblings of same type
    local Queries = require("db.queries.content")
    local siblings = ctx.db:query_all(Queries.objects_by_spec_type, {
        spec_id = obj.specification_ref, type_ref = obj.type_ref
    })
    local index = 1
    for i, sib in ipairs(siblings or {}) do
        if sib.id == obj.id then index = i; break end
    end
    local letter = string.char(64 + index)  -- A=1, B=2, ...

    -- Format ABNT title: "ANEXO A – Title"
    local user_title = obj.title_text or ""
    local full_title = "ANEXO " .. letter .. " – " .. user_title

    -- Header
    local header_div = pandoc.Div({pandoc.Para({pandoc.Str(full_title)})})
    header_div.classes = {"unnumbered-heading"}
    header_div.attr = pandoc.Attr("", {"unnumbered-heading"}, {["custom-style"] = "AnnexHeading"})
    render_utils.add_header_blocks(blocks, { header_div })

    -- Body: include original content blocks
    for _, block in ipairs(ctx.original_blocks or {}) do
        table.insert(blocks, block)
    end

    return blocks
end

return M
