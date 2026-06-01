---CAPA (ABNT)
---Per ABNT NBR 14724:2011 - Pre-textual element (Capa)
---
---Uses semantic markers converted by format-specific filters:
---  - Div classes: cover-institution, cover-department, cover-title, etc.
---  - RawBlock("specdown", "page-break") for page breaks
---  - RawBlock("specdown", "vertical-space:NNNN") for spacing (twips)

local render_utils = require("pipeline.shared.render_utils")

local function render_body(ctx)
    -- One node-construction rule for this file: the ctx-provided pandoc, same as
    -- the rest of the model. The helpers below close over it.
    local pandoc = ctx.pandoc

    local function semantic_div(text, class)
        local div = pandoc.Div({pandoc.Para({pandoc.Str(text)})})
        div.classes = {class}
        return div
    end

    local function vertical_space(twips)
        return pandoc.RawBlock("specdown", "vertical-space:" .. tostring(twips))
    end

    local blocks = {}

    local obj_attrs = ctx.subject.attributes or {}
    local spec_attrs = ctx.subject.spec_attributes or {}

    local function get_attr(name)
        local lower = name:lower()
        local val = obj_attrs[lower] or obj_attrs[name:upper()] or obj_attrs[name]
        if val and val ~= "" then return val end
        return spec_attrs[lower]
    end

    local title = get_attr("title")
    local subtitle = get_attr("subtitle")
    local author = get_attr("author")
    local city = get_attr("city")
    local year = get_attr("year")

    -- Fallback to original blocks if required attributes missing
    if not (title and author) then
        return ctx.subject.element
    end

    local docx = ctx.config.docx or {}
    local use_cover_image = docx.cover_image ~= false and docx.use_cover_image ~= false
    if ctx.format == "docx" and use_cover_image then
        table.insert(blocks, pandoc.RawBlock("speccompiler", "abnt-cover-background"))
        if title then table.insert(blocks, semantic_div(title, "cover-image-title")) end
        if author then table.insert(blocks, semantic_div(author, "cover-image-author")) end
        return blocks
    end

    -- Build cover page matching abntex2 layout:
    -- 1. Author at top (centered)
    -- 2. Title at middle area (~40% from top, matching abntex2 \vfill distribution)
    -- 3. Location and year at bottom (centered)
    --
    -- Cover page layout with independent positioning:
    -- - Author: at top (normal flow)
    -- - Title: positioned with spacing from author
    -- - City/Year: absolutely positioned from page bottom (via DOCX filter framePr)
    --
    -- The city/year elements use position_from_bottom in the DOCX filter's
    -- SEMANTIC_CLASS_MAP, so they will be anchored to the page bottom
    -- regardless of title length.

    -- Small space before author to match LaTeX positioning (~0.1 inch = 144 twips)
    table.insert(blocks, vertical_space(144))

    -- Author at top
    if author then table.insert(blocks, semantic_div(author, "cover-author")) end

    -- Vertical space to position title (~3.3 inches = 4752 twips)
    table.insert(blocks, vertical_space(4752))

    -- Title in middle area (22pt font)
    if title then table.insert(blocks, semantic_div(title, "cover-title")) end
    if subtitle then table.insert(blocks, semantic_div(subtitle, "cover-subtitle")) end

    -- City/Year - absolutely positioned from page bottom by DOCX filter
    -- No vertical space needed - they will be anchored to page bottom
    if city then table.insert(blocks, semantic_div(city, "cover-location")) end
    if year then table.insert(blocks, semantic_div(year, "cover-year")) end

    return blocks
end

return {
    kind = "object",
    schema = {
        id = "CAPA",
        long_name = "Capa",
        description = "Cover page (Capa) - ABNT NBR 14724:2011",
        extends = "PRE_TEXTUAL",
        is_required = true,
        implicit_aliases = { "Capa", "Cover", "Portada" },
        header_style_id = "",
        body_style_id = nil
    },
    hooks = {
        render = function(ctx)
            local blocks = {}

            -- No page break at START (capa is first page)
            -- No header for capa

            -- Body
            local body_blocks = render_body(ctx)
            render_utils.add_blocks(blocks, body_blocks)

            -- Add page break at END of capa for proper section definition
            -- This ensures the first section is properly terminated before folha de rosto
            -- (folha de rosto also adds oddPage break, but having it here helps LibreOffice)
            render_utils.add_page_break(blocks, "odd")

            return blocks
        end,
    },
}
