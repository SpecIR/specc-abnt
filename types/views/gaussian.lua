---Gaussian Distribution view type module.
---Alias for the 'gauss' view in default model.
---
---@module gaussian
---@author SpecDown Team

local gauss = require("models.default.types.views.gauss")

-- NOTE: Don't re-export handler to avoid duplicate registration
-- The gauss module already registers gauss_handler

return {
    kind = "view",
    schema = {
        id = "GAUSSIAN",
        long_name = "Gaussian Distribution",
        description = "Gaussian/Normal distribution curve data (alias for gauss)",
    },
    hooks = {
        -- Re-export the dataset function from gauss
        dataset = gauss.hooks.dataset,
    },
}
