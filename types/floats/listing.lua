---ABNT Listing type override.
---
---A *listagem* is framed preformatted text: source code, pseudocode or any
---block whose line breaks carry meaning. It is drawn with a box border and
---keeps its own counter, separate from Tabela and Quadro.
---
---Not to be confused with QUADRO_TABLE, which is the tabular quadro.
---@module abnt.listing

return {
    kind = "float",
    schema = {
        id = "LISTING",
        long_name = "Listagem",
        description = "Listagem de codigo ou texto preformatado (moldura)",
        caption_format = "Listagem",
        counter_group = "LISTING",
        aliases = { "src", "code", "listagem" },
    },
    hooks = {},
}
