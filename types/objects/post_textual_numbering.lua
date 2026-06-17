---Shared helpers for ABNT appendix/annex rendering.

local M = {}

local function letter_for_index(index)
    local n = tonumber(index) or 1
    local parts = {}
    repeat
        local rem = (n - 1) % 26
        table.insert(parts, 1, string.char(65 + rem))
        n = math.floor((n - 1) / 26)
    until n == 0
    return table.concat(parts)
end

function M.section_letter(ctx)
    local obj = ctx.subject.object
    local Queries = require("db.queries.content")
    local siblings = ctx.data:query_all(Queries.objects_by_spec_type, {
        spec_id = obj.specification_ref,
        type_ref = obj.type_ref,
    })

    local index = 1
    for i, sib in ipairs(siblings or {}) do
        if sib.id == obj.id then
            index = i
            break
        end
    end

    return letter_for_index(index)
end

return M
