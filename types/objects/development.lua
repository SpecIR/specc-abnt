---DEVELOPMENT - Desenvolvimento (ABNT)
---Per ABNT NBR 14724:2011 - main body chapters
---Starts on odd (right-hand) page per abntex2 \textual behavior

local render_utils = require("pipeline.shared.render_utils")

return {
    kind = "object",
    schema = {
        id = "DEVELOPMENT",
        long_name = "Development",
        description = "Desenvolvimento - development/body chapter (ABNT)",
        extends = "TEXTUAL",
        implicit_aliases = { "Desenvolvimento", "Development" },
        starts_on = "next"  -- Start on next page (odd-page behavior deferred to postprocessor when twoside)
    },
    hooks = {
        ---Render development chapter with odd page break.
        ---@param ctx table Render context
        ---@return table blocks Array of Pandoc blocks
        render = function(ctx)
            local obj = ctx.subject.object
            local blocks = {}

            -- Page break to odd page (matches abntex2 \textual behavior)
            render_utils.add_page_break(blocks, "next")

            -- Header: always level 1 (chapter-level textual element).
            -- obj.level inherits from the markdown heading (## = 2), but the assembler's
            -- normalize_header_levels() only shifts top-level Headers — not those inside
            -- spec-object-header Divs — so we must use the correct level directly.
            local level = 1
            local title = obj.title_text or "Desenvolvimento"
            local header = ctx.pandoc.Header(level, {ctx.pandoc.Str(title)})
            header.attr = ctx.pandoc.Attr(obj.pid or "", {}, {["custom-style"] = "Heading1"})
            render_utils.add_header_blocks(blocks, header)

            -- Body: include original content blocks
            for _, block in ipairs(ctx.subject.element or {}) do
                table.insert(blocks, block)
            end

            return blocks
        end,
    },
}
