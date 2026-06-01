---APPENDIX - Apendice (ABNT)
---Per ABNT NBR 14724:2011 - optional, author's supplementary material
---Uses letter numbering: APENDICE A, APENDICE B, etc.

local render_utils = require("pipeline.shared.render_utils")

return {
    kind = "object",
    schema = {
        id = "APPENDIX",
        long_name = "Appendix",
        description = "Apendice - appendix with letter numbering (ABNT)",
        extends = "POST_TEXTUAL",
        implicit_aliases = { "Apêndice", "Apendice", "Appendix" },
        header_style_id = "AppendixHeading",
        starts_on = "next"
    },
    hooks = {
        ---Render appendix section with AppendixHeading style.
        ---Formats title as "APÊNDICE A – Title" per ABNT NBR 14724:2011.
        ---@param ctx table Render context
        ---@return table blocks Array of Pandoc blocks
        render = function(ctx)
            local obj = ctx.subject.object
            local blocks = {}

            -- Page break
            render_utils.add_page_break(blocks, ctx.subject.type_schema.starts_on)

            -- Determine letter index by counting siblings of same type
            local Queries = require("db.queries.content")
            local siblings = ctx.data:query_all(Queries.objects_by_spec_type, {
                spec_id = obj.specification_ref, type_ref = obj.type_ref
            })
            local index = 1
            for i, sib in ipairs(siblings or {}) do
                if sib.id == obj.id then index = i; break end
            end
            local letter = string.char(64 + index)  -- A=1, B=2, ...

            -- Format ABNT title: "APÊNDICE A – Title"
            local user_title = obj.title_text or ""
            local full_title = "APÊNDICE " .. letter .. " – " .. user_title

            -- Header
            local header_div = ctx.pandoc.Div({ctx.pandoc.Para({ctx.pandoc.Str(full_title)})})
            header_div.classes = {"unnumbered-heading"}
            header_div.attr = ctx.pandoc.Attr("", {"unnumbered-heading"}, {["custom-style"] = "AppendixHeading"})
            render_utils.add_header_blocks(blocks, { header_div })

            -- Body: include original content blocks
            for _, block in ipairs(ctx.subject.element or {}) do
                table.insert(blocks, block)
            end

            return blocks
        end,
    },
}
