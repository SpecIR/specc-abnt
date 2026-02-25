---LOG (List of Graphs/Charts) view for ABNT.
---Generates "Lista de Gráficos" with PAGEREF fields.
---
---@module abnt.types.views.log
---@author SpecDown Team
---@license MIT

local M = {}

local OOXMLBuilder = require("infra.format.docx.ooxml_builder")

M.view = {
    id = "LOG",
    long_name = "Lista de Gráficos",
    description = "List of Graphs/Charts (Lista de Gráficos) - ABNT NBR 14724:2011",
    inline_prefix = "log"
}

-- ============================================================================
-- LOG Generation
-- ============================================================================

---Generate OOXML LOG field with Word's automatic list.
---@return string OOXML content
local function generate_auto_log()
    return OOXMLBuilder.static.list_field("CHART")
end

---Render LOG entries to OOXML (pure function, no DB access).
---@param entries table Array of {identifier, caption, number, label}
---@return string OOXML content
function M.render(entries)
    local parts = {}
    for _, chart in ipairs(entries or {}) do
        local title = chart.caption or chart.label or ""
        local text = string.format("Gráfico %s - %s", chart.number or "", title)
        local para = OOXMLBuilder.static.pageref_entry({
            anchor = chart.identifier or "",
            text = text,
            style = "TOC1"
        })
        table.insert(parts, para)
    end

    if #parts == 0 then
        return '<w:p><w:r><w:t>Nenhum gráfico encontrado.</w:t></w:r></w:p>'
    end

    return table.concat(parts, "\n")
end

-- ============================================================================
-- Public API
-- ============================================================================

---Generate LOG content (manual or automatic).
---When resolved_data is provided, uses pre-computed entries (no DB access).
---@param data DataManager Database instance (unused when resolved_data provided)
---@param spec_id string Specification identifier
---@param options table|nil {manual = true, resolved_data = table}
---@return string OOXML content
function M.generate(data, spec_id, options)
    options = options or {}

    if not options.manual then
        return generate_auto_log()
    end

    -- Use pre-computed data if available
    if options.resolved_data then
        return M.render(options.resolved_data)
    end

    -- Fallback: query DB (should not happen after view_materializer runs)
    local charts = data:query_all([[
        SELECT identifier, caption, number, label FROM spec_floats
        WHERE specification_ref = :spec_id
          AND type_ref = 'CHART'
        ORDER BY file_seq
    ]], { spec_id = spec_id })

    return M.render(charts)
end

return M
