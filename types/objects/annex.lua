---ANNEX - Anexo (ABNT)
---Per ABNT NBR 14724:2011 - optional, external supplementary material
---Uses letter numbering: ANEXO A, ANEXO B, etc.

local render_utils = require("pipeline.shared.render_utils")
local classes = require("models.abnt.shared.semantic_classes")
local post_textual_numbering = require("models.abnt.types.objects.post_textual_numbering")

return {
    kind = "object",
    schema = {
        id = "ANNEX",
        long_name = "Annex",
        description = "Anexo - annex with letter numbering (ABNT)",
        extends = "POST_TEXTUAL",
        implicit_aliases = { "Anexo", "Annex" },
        starts_on = "next"
    },
    hooks = {
        ---Render annex section with AnnexHeading style.
        ---Formats title as "ANEXO A – Title" per ABNT NBR 14724:2011.
        ---@param ctx table Render context
        ---@return table blocks Array of Pandoc blocks
        render = function(ctx)
            local obj = ctx.subject.object
            local blocks = {}

            -- Page break
            render_utils.add_page_break(blocks, ctx.subject.type_schema.starts_on)

            local letter = post_textual_numbering.section_letter(ctx)

            -- Format ABNT title: "ANEXO A – Title"
            local user_title = obj.title_text or ""
            local full_title = "ANEXO " .. letter .. " – " .. user_title

            -- Header
            local header_div = ctx.pandoc.Div({ctx.pandoc.Para({ctx.pandoc.Str(full_title)})})
            header_div.classes = {classes.UNNUMBERED_HEADING}
            header_div.attr = ctx.pandoc.Attr("", {classes.UNNUMBERED_HEADING}, {["custom-style"] = "AnnexHeading"})
            render_utils.add_header_blocks(blocks, { header_div })

            -- Body: include original content blocks
            for _, block in ipairs(ctx.subject.element or {}) do
                table.insert(blocks, block)
            end

            return blocks
        end,
    },
}
