---ABNT Listing type override.
---Portuguese caption format for code listings (Quadro).
---@module abnt.listing

return {
    kind = "float",
    schema = {
        id = "LISTING",
        long_name = "Quadro",
        description = "Quadro ou listagem de código",
        caption_format = "Quadro",
        counter_group = "LISTING",
        aliases = { "src", "code", "quadro" },
    },
    hooks = {},
}
