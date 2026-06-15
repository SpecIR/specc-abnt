--- ABNT Model Configuration
---@module config

return {
    language = {
        default = "pt-BR",
        styles = {
            ["en-US"] = "Abstract",
        },
    },
    citation = {
        -- Resolved against models/abnt/assets/. Model-declared: citation
        -- style is part of the model, not project-configurable.
        csl = "abnt.csl",
    },
}
