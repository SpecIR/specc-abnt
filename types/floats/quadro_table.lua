---ABNT Quadro type (tabular form).
---
---ABNT/IBGE splits tabular content in two:
---  - tabela  : numeric or statistical data, borders open at the sides
---  - quadro  : textual data, closed borders with a complete cell grid
---
---This type is the tabular quadro. It reuses TABLE's CSV / list-table parsing
---through `extends`, and differs only in presentation: caption prefix "Quadro",
---the QuadroCaption paragraph style (which the DOCX post-processor keys off to
---draw the closed grid), and its own "Quadro" counter.
---
---Default syntax mapping:
---  list-table: -> quadro   (textual by nature)
---  csv:        -> tabela   (numeric by nature)
---Override with the `csv-q:` and `list-table-t:` variants.
---@module abnt.quadro_table

return {
    kind = "float",
    schema = {
        id = "QUADRO_TABLE",
        long_name = "Quadro",
        description = "Quadro tabular de informacoes textuais (grade fechada)",
        caption_format = "Quadro",
        counter_group = "QUADRO",
        extends = "TABLE",
        aliases = { "list-table", "csv-q", "tsv-q", "quadro" },
    },
    hooks = {},
}
