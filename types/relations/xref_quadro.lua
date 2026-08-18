---Cross-reference relation type for quadros.
---Targets: QUADRO_TABLE float type.
---
---The ABNT model splits tabular content into Tabela (XREF_TABLE) and Quadro,
---so the quadro needs its own label-based reference type.
---@module abnt.xref_quadro

return {
    kind = "relation",
    schema = {
        id = "XREF_QUADRO",
        extends = "LABEL_REF",
        long_name = "Quadro Reference",
        description = "Cross-reference to a quadro",
        target_type_ref = "QUADRO_TABLE",
    },
}
