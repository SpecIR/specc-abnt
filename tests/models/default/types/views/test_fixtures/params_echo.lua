---Test fixture view for data_loader parameter parsing.
---Returns parameters as dataset rows so tests can assert injected values.
---@module test_fixtures.params_echo
local M = {}

function M.dataset(dctx)
    local params = dctx.subject.params or {}
    return {
        source = {
            { "alpha", "count", "name", "spec_id", "params_raw" },
            { params.alpha, params.count, params.name, dctx.spec_id, params.params }
        }
    }
end

return M
