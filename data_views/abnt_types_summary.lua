---ABNT Object Types Summary View.
---Groups objects by ABNT document structure category using type inheritance.
---
---Returns: category, obrigatorio_count, opcional_count, total_count

local M = {}

---Generate summary of ABNT object types by category.
---Uses type inheritance (extends field) to classify objects.
---Only counts level 2 sections (main chapters), not subsections.
---@param params table Parameters (unused)
---@param data DataManager Database instance
---@return table dataset ECharts dataset format
function M.generate(params, data)
    -- Query level-2 objects (main sections) with their type inheritance
    -- Types extend PRE_TEXTUAL, TEXTUAL, or POST_TEXTUAL (which all extend SECTION)
    -- SECTION type (unrecognized titles) treated as TEXTUAL in ABNT context
    -- Uses is_required to separate obrigatório from opcional
    local sql = [[
        SELECT
            CASE
                WHEN t.extends = 'PRE_TEXTUAL' OR t.identifier = 'PRE_TEXTUAL' THEN 'Pré-textual'
                WHEN t.extends = 'POST_TEXTUAL' OR t.identifier = 'POST_TEXTUAL' THEN 'Pós-textual'
                ELSE 'Textual'  -- TEXTUAL, SECTION, and unrecognized types
            END AS category,
            SUM(CASE WHEN t.is_required = 1 THEN 1 ELSE 0 END) AS obrigatorio_count,
            SUM(CASE WHEN t.is_required = 0 THEN 1 ELSE 0 END) AS opcional_count,
            COUNT(*) AS total_count
        FROM spec_objects o
        JOIN spec_object_types t ON o.type_ref = t.identifier
        WHERE o.level = 2  -- Only main sections (H2), not subsections
        GROUP BY category
        ORDER BY
            CASE category
                WHEN 'Pré-textual' THEN 1
                WHEN 'Textual' THEN 2
                WHEN 'Pós-textual' THEN 3
            END
    ]]

    local rows = data:query_all(sql, {})

    -- Convert to ECharts dataset format
    local source = { {"category", "obrigatorio_count", "opcional_count", "total_count"} }
    for _, row in ipairs(rows or {}) do
        table.insert(source, {
            row.category,
            row.obrigatorio_count,
            row.opcional_count,
            row.total_count
        })
    end

    return { source = source }
end

return M
