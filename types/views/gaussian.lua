---Gaussian Distribution view type module.
---Alias for the 'gauss' view in default model.
---
---@module gaussian
---@author SpecDown Team

local gauss = require("models.default.types.views.gauss")

local M = {}

M.view = {
    id = "GAUSSIAN",
    long_name = "Gaussian Distribution",
    description = "Gaussian/Normal distribution curve data (alias for gauss)",
}

-- Re-export the generate function from gauss
M.generate = gauss.generate

-- NOTE: Don't re-export handler to avoid duplicate registration
-- The gauss module already registers gauss_handler

return M
