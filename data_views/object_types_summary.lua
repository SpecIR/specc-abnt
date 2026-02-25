---Object Types Summary View.
---Counts objects by type.
---
---Returns: type_ref, count

local M = {}

---Generate object types summary.
---@param params table Parameters (unused)
---@param data DataManager Database instance
---@return table dataset ECharts dataset format
function M.generate(params, data)
    local sql = [[
        SELECT
            type_ref,
            COUNT(*) AS count
        FROM spec_objects
        GROUP BY type_ref
        ORDER BY count DESC
    ]]

    local rows = data:query_all(sql, {})

    -- Convert to ECharts dataset format
    local source = { {"type_ref", "count"} }
    for _, row in ipairs(rows) do
        table.insert(source, {row.type_ref, row.count})
    end

    return { source = source }
end

return M
