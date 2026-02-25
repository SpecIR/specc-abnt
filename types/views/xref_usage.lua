---Cross-Reference Usage View.
---Shows cross-references by target type for Sankey diagrams.
---Groups references by float type (Figures, Tables, Charts, etc.)
---
---Returns: data (nodes) and links (for Sankey format)
---
---@module xref_usage
---@author SpecDown Team

local M = {}

M.view = {
    id = "XREF_USAGE",
    long_name = "Cross-Reference Usage",
    description = "Cross-reference distribution by target type (Sankey format)",
}

---Generate cross-reference usage data.
---@param params table Parameters (unused)
---@param data DataManager Database instance
---@param spec_id string Specification identifier (unused)
---@return table result ECharts Sankey format with data/links
function M.generate(params, data, spec_id)
    -- Parse float type from target_text prefix (e.g., "chart:gauss" → "Gráficos")
    local sql = [[
        SELECT
            'Documento' AS source,
            CASE
                WHEN target_text LIKE 'listing:%' THEN 'Listagens'
                WHEN target_text LIKE 'chart:%' THEN 'Gráficos'
                WHEN target_text LIKE 'fig:%' OR target_text LIKE 'figure:%' THEN 'Figuras'
                WHEN target_text LIKE 'table:%' OR target_text LIKE 'csv:%' OR target_text LIKE 'list-table:%' THEN 'Tabelas'
                WHEN target_text LIKE 'math:%' OR target_text LIKE 'eq:%' THEN 'Equações'
                WHEN target_text LIKE 'puml:%' OR target_text LIKE 'plantuml:%' THEN 'Diagramas'
                WHEN target_text LIKE 'src%:%' OR target_text LIKE 'code:%' THEN 'Código'
                ELSE 'Outros'
            END AS target,
            COUNT(*) AS value
        FROM spec_relations
        WHERE type_ref LIKE 'XREF%'
        GROUP BY target
        HAVING value > 0
        ORDER BY value DESC
    ]]

    local rows = data:query_all(sql, {})

    -- Build nodes and links for Sankey format
    local nodes_map = {}
    local nodes = {}
    local links = {}

    for _, row in ipairs(rows) do
        -- Add source node
        if not nodes_map[row.source] then
            nodes_map[row.source] = true
            table.insert(nodes, { name = row.source })
        end
        -- Add target node
        if not nodes_map[row.target] then
            nodes_map[row.target] = true
            table.insert(nodes, { name = row.target })
        end
        -- Add link
        table.insert(links, {
            source = row.source,
            target = row.target,
            value = row.value
        })
    end

    -- Return Sankey-specific format
    return {
        data = nodes,
        links = links
    }
end

return M
