---LOF (List of Figures) view for ABNT.
---Generates "Lista de Figuras" with PAGEREF fields.
---
---@module abnt.types.views.lof
---@author SpecDown Team
---@license MIT

local M = {}

local OOXMLBuilder = require("infra.format.docx.ooxml_builder")

M.view = {
    id = "LOF",
    long_name = "Lista de Figuras",
    description = "List of Figures (Lista de Figuras) - ABNT NBR 14724:2011",
    inline_prefix = "lof",
    materializer_type = "lof",
    counter_group = "FIGURE"
}

-- ============================================================================
-- LOF Generation
-- ============================================================================

---Generate OOXML LOF field with Word's automatic list.
---@return string OOXML content
local function generate_auto_lof()
    return OOXMLBuilder.static.list_field("Figure")
end

---Render LOF entries to OOXML (pure function, no DB access).
---@param entries table Array of {identifier, caption, number, label}
---@return string OOXML content
function M.render(entries)
    local parts = {}
    for _, fig in ipairs(entries or {}) do
        local title = fig.caption or fig.label or ""
        local text = string.format("Figura %s - %s", fig.number or "", title)
        local para = OOXMLBuilder.static.pageref_entry({
            anchor = fig.identifier or "",
            text = text,
            style = "TOC1"
        })
        table.insert(parts, para)
    end

    if #parts == 0 then
        return '<w:p><w:r><w:t>Nenhuma figura encontrada.</w:t></w:r></w:p>'
    end

    return table.concat(parts, "\n")
end

-- ============================================================================
-- Public API
-- ============================================================================

---Generate LOF content (manual or automatic).
---When resolved_data is provided, uses pre-computed entries (no DB access).
---@param data DataManager Database instance (unused when resolved_data provided)
---@param spec_id string Specification identifier
---@param options table|nil {manual = true, resolved_data = table}
---@return string OOXML content
function M.generate(data, spec_id, options)
    options = options or {}

    if not options.manual then
        return generate_auto_lof()
    end

    -- Use pre-computed data if available
    if options.resolved_data then
        return M.render(options.resolved_data)
    end

    -- Fallback: query DB (should not happen after view_materializer runs)
    -- Query floats with counter_group = 'FIGURE' (includes FIGURE, PLANTUML, etc.)
    -- Only include figures that have captions
    local figures = data:query_all([[
        SELECT f.anchor AS identifier, f.caption, f.number, f.label
        FROM spec_floats f
        JOIN spec_float_types ft ON f.type_ref = ft.identifier
        WHERE f.specification_ref = :spec_id
          AND COALESCE(ft.counter_group, ft.identifier) = 'FIGURE'
          AND f.caption IS NOT NULL AND f.caption != ''
        ORDER BY f.file_seq
    ]], { spec_id = spec_id })

    return M.render(figures)
end

return M
