---Test fixture that raises at runtime.
---Used to exercise the data_loader dataset() error path.
---@module test_fixtures.bad_throw
local M = {}

function M.dataset()
    error("intentional data loader fixture failure")
end

return M
