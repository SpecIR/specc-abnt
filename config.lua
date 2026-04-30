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
        -- Resolved against models/abnt/assets/. Projects can override via
        -- `csl:` in project.yaml.
        csl = "abnt.csl",
    },
}
