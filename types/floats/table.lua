---ABNT Table type override.
---Portuguese caption format for tables.
---@module abnt.table

return {
    kind = "float",
    schema = {
        id = "TABLE",
        long_name = "Tabela",
        description = "Tabela com legenda",
        caption_format = "Tabela",
        counter_group = "TABLE",
        aliases = { "tab", "csv", "tsv", "list-table" },
    },
    hooks = {},
}
