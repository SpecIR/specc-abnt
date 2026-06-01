---EPIGRAFE (ABNT)
---Per ABNT NBR 14724:2011 - optional, right-aligned quote at page bottom
---
---Uses semantic markers converted by format-specific filters:
---  - Div with class "bottom-aligned" wraps content for page-bottom positioning
---  - Div with class "epigraph" applies Epigraph style

local render_utils = require("pipeline.shared.render_utils")

return {
    kind = "object",
    schema = {
        id = "EPIGRAFE",
        long_name = "Epigrafe",
        description = "Epigrafe - epigraph/quote page (ABNT)",
        extends = "PRE_TEXTUAL",
        implicit_aliases = { "Epígrafe", "Epigrafe", "Epigraph" },
        numbered = false,
        section_type = "pretextual",
        header_style_id = "",
        body_style_id = "Epigraph",
        starts_on = "next",  -- Start on next page (odd-page behavior deferred to postprocessor when twoside)
        attributes = {
            { name = "author", type = "STRING" }
        }
    },
    hooks = {
        render = function(ctx)
            local obj = ctx.subject.object
            local blocks = {}

            -- Page break
            render_utils.add_page_break(blocks, "next")

            -- No header for epigrafe

            -- Body: wrap content in epigraph style, then in bottom-aligned container
            local content_blocks = {}
            for _, block in ipairs(ctx.subject.element or {}) do
                if block.t ~= "Header" then
                    local styled = ctx.pandoc.Div({block})
                    styled.classes = {"epigraph"}
                    table.insert(content_blocks, styled)
                end
            end

            if #content_blocks > 0 then
                local container = ctx.pandoc.Div(content_blocks)
                container.classes = {"bottom-aligned"}
                render_utils.add_blocks(blocks, { container })
            end

            return blocks
        end,
    },
}
