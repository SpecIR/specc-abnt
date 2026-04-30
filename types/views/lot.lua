---LOT (List of Tables) view for ABNT.
---Generates "Lista de Tabelas" with PAGEREF fields.
---
---@module abnt.types.views.lot
---@author SpecDown Team
---@license MIT

local M = {}

local OOXMLBuilder = require("infra.format.docx.ooxml_builder")

M.view = {
    id = "LOT",
    long_name = "Lista de Tabelas",
    description = "List of Tables (Lista de Tabelas) - ABNT NBR 14724:2011",
    inline_prefix = "lot",
    materializer_type = "lot",
    counter_group = "TABLE"
}

-- ============================================================================
-- LOT Generation
-- ============================================================================

---Generate OOXML LOT field with Word's automatic list.
---@return string OOXML content
local function generate_auto_lot()
    return OOXMLBuilder.static.list_field("Table")
end

---Render LOT entries to OOXML (pure function, no DB access).
---`identifier` is the canonical float key used by emitted bookmarks (`syntax_key`).
---@param entries table Array of {identifier, caption, number, label}
---@return string OOXML content
function M.render(entries)
    local parts = {}
    for _, tbl in ipairs(entries or {}) do
        local title = tbl.caption or tbl.label or tbl.identifier or ""
        local text = string.format("Tabela %s - %s", tbl.number or "", title)
        local para = OOXMLBuilder.static.pageref_entry({
            anchor = tbl.identifier or "",
            text = text,
            style = "TOC1"
        })
        table.insert(parts, para)
    end

    if #parts == 0 then
        return '<w:p><w:r><w:t>Nenhuma tabela encontrada.</w:t></w:r></w:p>'
    end

    return table.concat(parts, "\n")
end

-- ============================================================================
-- Public API
-- ============================================================================

---Generate LOT content (manual or automatic).
---When resolved_data is provided, uses pre-computed entries (no DB access).
---@param data DataManager Database instance (unused when resolved_data provided)
---@param spec_id string Specification identifier
---@param options table|nil {manual = true, resolved_data = table}
---@return string OOXML content
function M.generate(data, spec_id, options)
    options = options or {}

    if not options.manual then
        return generate_auto_lot()
    end

    -- Use pre-computed data if available
    if options.resolved_data then
        return M.render(options.resolved_data)
    end

    -- Fallback: query DB (should not happen after view_materializer runs)
    -- Query the TABLE counter group so future table-like float types are also
    -- included. Use syntax_key as the emitted bookmark identifier.
    local tables = data:query_all([[
        SELECT f.syntax_key AS identifier, f.caption, f.number,
               f.syntax_key AS label
        FROM spec_floats f
        JOIN spec_float_types ft ON f.type_ref = ft.identifier
        WHERE f.specification_ref = :spec_id
          AND COALESCE(ft.counter_group, ft.identifier) = 'TABLE'
          AND f.caption IS NOT NULL AND f.caption != ''
        ORDER BY f.file_seq
    ]], { spec_id = spec_id })

    return M.render(tables)
end

return M
