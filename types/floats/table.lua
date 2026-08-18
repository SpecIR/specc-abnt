---ABNT Table type override.
---Portuguese caption format for tables (Tabela).
---
---Per the IBGE tabular norms adopted by NBR 14724, a *tabela* carries numeric
---or statistical data and is drawn with open sides (three-line style). Textual
---data belongs in a *quadro* instead -- see types/floats/quadro_table.lua.
---@module abnt.table

return {
    kind = "float",
    schema = {
        id = "TABLE",
        long_name = "Tabela",
        description = "Tabela de dados numericos (bordas abertas, estilo IBGE)",
        caption_format = "Tabela",
        counter_group = "TABLE",
        -- `list-table-t` is the list-table syntax forced into tabela styling;
        -- plain `list-table` defaults to QUADRO_TABLE.
        aliases = { "tab", "csv", "tsv", "list-table-t" },
    },
    hooks = {},
}
