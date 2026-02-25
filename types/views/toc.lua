---TOC (Table of Contents) view for ABNT.
---Generates "Sumário" with PAGEREF fields for manual TOC.
---
---@module abnt.types.views.toc
---@author SpecDown Team
---@license MIT

local M = {}

local OOXMLBuilder = require("infra.format.docx.ooxml_builder")

M.view = {
    id = "TOC",
    long_name = "Sumário",
    description = "Table of Contents (Sumário) - ABNT NBR 14724:2011",
    inline_prefix = "toc",
    materializer_type = "toc"
}

-- ============================================================================
-- TOC Generation
-- ============================================================================

---Generate OOXML TOC field with Word's automatic TOC.
---Includes UnnumberedHeading style for pre-textual elements.
---@param options table {depth = 3, hyperlinks = true}
---@return string OOXML content
local function generate_auto_toc(options)
    local depth = options.depth or 3
    local hyperlinks = options.hyperlinks ~= false

    -- Build TOC field switches:
    -- \o "1-3" - include heading levels 1-3
    -- \t "UnnumberedHeading,1" - also include UnnumberedHeading style as level 1
    -- \h - hyperlinks
    local switches = string.format('TOC \\o "1-%d" \\t "UnnumberedHeading,1"', depth)
    if hyperlinks then
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

---Render TOC entries to OOXML (pure function, no DB access).
---@param entries table Array of {pid, title_text, level, identifier}
---@return string OOXML content
function M.render(entries)
    local parts = {}
    for _, entry in ipairs(entries or {}) do
        local text = (entry.pid or "") .. " " .. (entry.title_text or "")
        local para = OOXMLBuilder.static.pageref_entry({
            anchor = entry.identifier or "",
            text = text,
            style = "TOC" .. (entry.level or 1)
        })
        table.insert(parts, para)
    end

    return table.concat(parts, "\n")
end

-- ============================================================================
-- Public API
-- ============================================================================

---Generate TOC content (manual or automatic).
---When resolved_data is provided, uses pre-computed entries (no DB access).
---@param data DataManager Database instance (unused when resolved_data provided)
---@param spec_id string Specification identifier
---@param options table|nil {manual = true, depth = 3, max_level = 3, resolved_data = table}
---@return string OOXML content
function M.generate(data, spec_id, options)
    options = options or {}

    if not options.manual then
        return generate_auto_toc(options)
    end

    -- Use pre-computed data if available
    if options.resolved_data then
        return M.render(options.resolved_data)
    end

    -- Fallback: query DB (should not happen after view_materializer runs)
    local max_level = options.max_level or 3
    local entries = data:query_all([[
        SELECT pid, title_text, level, identifier FROM spec_objects
        WHERE specification_ref = :spec_id
          AND level > 0
          AND level <= :max_level
        ORDER BY file_seq
    ]], { spec_id = spec_id, max_level = max_level })

    return M.render(entries)
end

return M
