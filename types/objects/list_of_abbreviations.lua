---LIST_OF_ABBREVIATIONS - Lista de Siglas (ABNT)
---Per ABNT NBR 14724:2011 - optional, user-provided list
---
---Uses semantic markers converted by format-specific filters.

local render_utils = require("pipeline.shared.render_utils")
local lists = require("models.abnt.shared.pretextual_lists")

return {
    kind = "object",
    schema = {
        id = "LIST_OF_ABBREVIATIONS",
        long_name = "List of Abbreviations",
        description = "Lista de Abreviaturas e Siglas - list of abbreviations (ABNT)",
        extends = "PRE_TEXTUAL",
        implicit_aliases = {
            "Lista de Abreviaturas e Siglas",
            "Lista de Abreviaturas",
            "Lista de Siglas",
            "List of Abbreviations"
        },
        numbered = false,
        section_type = "pretextual",
        header_style_id = "UnnumberedHeading",
        starts_on = "next"
    },
    hooks = {
        render = function(ctx)
            local blocks = {}

            -- Page break
            render_utils.add_page_break(blocks, ctx.subject.type_schema.starts_on)

            -- Header: "LISTA DE ABREVIATURAS E SIGLAS"
            local title = "LISTA DE ABREVIATURAS E SIGLAS"
            local header_div = ctx.pandoc.Div({ctx.pandoc.Para({ctx.pandoc.Str(title)})})
            header_div.classes = {"unnumbered-heading"}
            render_utils.add_header_blocks(blocks, { header_div })

            -- Body: Lista de Siglas (semantic Pandoc table via the host; the docx
            -- filter styles it -- no model-side OOXML here)
            render_utils.add_blocks(blocks, { lists.abbrev_list_block(ctx) })

            return blocks
        end,
    },
}
