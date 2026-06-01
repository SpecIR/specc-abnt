---Pre-textual list generation for ABNT (Lista de Figuras / Tabelas, Sumário,
---Lista de Siglas).
---
---A plain helper module -- NOT a type descriptor. The pre-textual section objects
---(list_of_figures, list_of_tables, toc, list_of_abbreviations) call these
---functions from their render hooks to emit their OOXML lists.
---
---ABNT documents trigger these lists via pre-textual SECTIONS (## Lista de
---Figuras), not inline `lof:` views, so there are no list "view" descriptors --
---the generation lives here, once.
---
---The float PAGEREF anchor is taken from `float_anchor.ref_anchor(row)` -- the
---SAME function emit_float uses to name the bookmark -- so list references resolve
---by construction (see VC-ABNT-002).
---
---@module abnt.shared.pretextual_lists

local OOXMLBuilder = require("infra.format.docx.ooxml_builder")
local float_anchor = require("pipeline.shared.float_anchor")
local hook_ctx = require("pipeline.shared.hook_ctx")

local M = {}

---Generate a list-of-floats (LOF/LOT) as OOXML: one PAGEREF entry per captioned
---float in the counter group, ordered by document position.
---@param data DataManager Database instance
---@param spec_id string Specification identifier
---@param counter_group string e.g. "FIGURE" or "TABLE"
---@param caption_prefix string ABNT caption word, e.g. "Figura" or "Tabela"
---@param empty_msg string Message when the group has no captioned floats
---@return string OOXML content
function M.float_list_ooxml(data, spec_id, counter_group, caption_prefix, empty_msg)
    -- Select the raw anchor/label columns; the reference anchor is computed in
    -- Lua via float_anchor.ref_anchor so it matches emit_float's bookmark exactly.
    local rows = data:query_all([[
        SELECT f.anchor, f.label, f.caption, f.number
        FROM spec_floats f
        JOIN spec_float_types ft ON f.type_ref = ft.identifier
        WHERE f.specification_ref = :spec_id
          AND COALESCE(ft.counter_group, ft.identifier) = :counter_group
          AND f.caption IS NOT NULL AND f.caption != ''
        ORDER BY f.file_seq
    ]], { spec_id = spec_id, counter_group = counter_group })

    local parts = {}
    for _, row in ipairs(rows or {}) do
        local anchor = float_anchor.ref_anchor(row) or ""
        local title = row.caption or anchor
        local text = string.format("%s %s - %s", caption_prefix, row.number or "", title)
        table.insert(parts, OOXMLBuilder.static.pageref_entry({
            anchor = anchor,
            text = text,
            style = "TOC1",
        }))
    end

    if #parts == 0 then
        return string.format('<w:p><w:r><w:t>%s</w:t></w:r></w:p>', empty_msg or "")
    end
    return table.concat(parts, "\n")
end

---Generate the Sumário as a native Word TOC field (auto-updating). Includes the
---UnnumberedHeading style as a level-1 entry so pre-textual sections appear.
---@param opts table|nil {depth = 3, hyperlinks = true}
---@return string OOXML content
function M.toc_ooxml(opts)
    opts = opts or {}
    local depth = opts.depth or 3
    local switches = string.format('TOC \\o "1-%d" \\t "UnnumberedHeading,1"', depth)
    if opts.hyperlinks ~= false then
        switches = switches .. ' \\h'
    end
    return string.format([[
<w:p>
  <w:r><w:fldChar w:fldCharType="begin"/></w:r>
  <w:r><w:instrText xml:space="preserve"> %s </w:instrText></w:r>
  <w:r><w:fldChar w:fldCharType="separate"/></w:r>
</w:p>
<w:p>
  <w:r><w:fldChar w:fldCharType="end"/></w:r>
</w:p>]], switches)
end

---Build the Lista de Siglas as a semantic Pandoc table, via the default model's
---ABBREV_LIST `build_block` data hook (host-dispatched off the render ctx -- no
---cross-model file-path require, no raw OOXML). Returns Pandoc AST; the docx/html
---filters style it per format.
---@param ctx table the object render ctx (ctx.host, ctx.data, ctx.spec_id, ctx.pandoc)
---@return table block A pandoc.Block
function M.abbrev_list_block(ctx)
    local build_block = ctx.host
        and ctx.host:get_hook("view", "ABBREV_LIST", "build_block")
    if build_block then
        local dctx = hook_ctx.build_data(
            { log = ctx.log, model = ctx.model, config = ctx.config },
            ctx.data, ctx.diagnostics, { params = {} }, "build_block", ctx.spec_id)
        local block = build_block(dctx)
        if block then return block end
    end
    return ctx.pandoc.Para({ ctx.pandoc.Str("[Nenhuma sigla encontrada]") })
end

return M
