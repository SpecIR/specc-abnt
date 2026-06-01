---LOG (List of Graphs/Charts) view for ABNT.
---Generates "Lista de Gráficos" with PAGEREF fields.
---
---@module abnt.types.views.log
---@author SpecDown Team
---@license MIT

local OOXMLBuilder = require("infra.format.docx.ooxml_builder")

-- ============================================================================
-- LOG Generation
-- ============================================================================

---Generate OOXML LOG field with Word's automatic list.
---@return string OOXML content
local function generate_auto_log()
    return OOXMLBuilder.static.list_field("CHART")
end

---Render LOG entries to OOXML (pure function, no DB access).
---`identifier` is the float's reference anchor (`anchor`/`label`) — the SAME key
---emit_float emits as the bookmark, so the PAGEREF resolves.
---@param entries table Array of {identifier, caption, number, label}
---@return string OOXML content
local function render_entries(entries)
    local parts = {}
    for _, chart in ipairs(entries or {}) do
        local title = chart.caption or chart.label or chart.identifier or ""
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
local function generate(data, spec_id, options)
    options = options or {}

    if not options.manual then
        return generate_auto_log()
    end

    -- Use pre-computed data if available
    if options.resolved_data then
        return render_entries(options.resolved_data)
    end

    -- Fallback: query DB (should not happen after view_materializer runs).
    -- The PAGEREF anchor MUST equal the bookmark emit_float emits
    -- (`float.anchor or float.label`) -- NOT the raw syntax_key, which would dangle.
    local charts = data:query_all([[
        SELECT COALESCE(f.anchor, f.label) AS identifier, f.caption, f.number,
               f.label AS label
        FROM spec_floats f
        WHERE f.specification_ref = :spec_id
          AND f.type_ref = 'CHART'
          AND f.caption IS NOT NULL AND f.caption != ''
        ORDER BY f.file_seq
    ]], { spec_id = spec_id })

    return render_entries(charts)
end

return {
    kind = "view",
    schema = {
        id = "LOG",
        long_name = "Lista de Gráficos",
        description = "List of Graphs/Charts (Lista de Gráficos) - ABNT NBR 14724:2011",
        inline_prefix = "log"
    },
    hooks = {},
    generate = generate,
    render = render_entries
}
