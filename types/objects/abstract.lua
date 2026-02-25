---ABSTRACT - Resumo (ABNT)
---Per ABNT NBR 6028:2003 - mandatory, with keywords
---
---Uses semantic markers converted by format-specific filters.
---
---Language detection based on section title:
---  - "Abstract" -> ABSTRACT / Keywords: (en-US)
---  - "Resumo" -> RESUMO / Palavras-chave: (pt-BR)
---
---Uses lang helper for language-aware styling.

local render_utils = require("pipeline.shared.render_utils")
local lang = require("models.abnt.types.shared.lang")

local M = {}

M.name = "abstract"

M.object = {
    id = "ABSTRACT",
    long_name = "Abstract",
    description = "Resumo - abstract with keywords (ABNT NBR 6028:2003)",
    extends = "PRE_TEXTUAL",
    is_required = true,
    implicit_aliases = { "Resumo", "Abstract", "Resume", "Resumen" },
    numbered = false,
    section_type = "pretextual",
    header_style_id = "UnnumberedHeading",
    body_style_id = "Abstract",
    starts_on = "next",  -- Start on next page (odd-page behavior deferred to postprocessor when twoside)
    attributes = {
        { name = "keywords", type = "STRING" }
    }
}

---Get display title based on detected language.
---@param title_text string|nil The section title
---@return string display_title The title to render (uppercase)
local function get_display_title(title_text)
    if lang.is_english(title_text) then
        return "ABSTRACT"
    else
        return "RESUMO"
    end
end

function M.on_render_SpecObject(obj, ctx)
    local blocks = {}

    -- Page break
    render_utils.add_page_break(blocks, M.object.starts_on)

    -- Header: Language-aware title
    local title_text = obj and obj.title_text
    local display_title = get_display_title(title_text)
    local header_div = pandoc.Div({pandoc.Para({pandoc.Str(display_title)})})
    header_div.classes = {"unnumbered-heading"}
    render_utils.add_header_blocks(blocks, { header_div })

    -- Body: Filter content and apply language-aware styling
    local body_blocks = {}
    for _, block in ipairs(ctx.original_blocks or {}) do
        if block.t ~= "Header" then
            table.insert(body_blocks, block)
        end
    end

    if #body_blocks > 0 then
        -- Use lang helper for language-aware styling
        local styled_div = lang.auto_styled_div(body_blocks, title_text)
        render_utils.add_blocks(blocks, { styled_div })
    end

    return blocks
end

return M
