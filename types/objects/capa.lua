---CAPA (ABNT)
---Per ABNT NBR 14724:2011 - Pre-textual element (Capa)
---
---Uses semantic markers converted by format-specific filters:
---  - Div classes: cover-institution, cover-department, cover-title, etc.
---  - RawBlock("specdown", "page-break") for page breaks
---  - RawBlock("specdown", "vertical-space:NNNN") for spacing (twips)

local render_utils = require("pipeline.shared.render_utils")

local M = {}

M.name = "capa"

M.object = {
    id = "CAPA",
    long_name = "Capa",
    description = "Cover page (Capa) - ABNT NBR 14724:2011",
    extends = "PRE_TEXTUAL",
    is_required = true,
    implicit_aliases = { "Capa", "Cover", "Portada" },
    header_style_id = "",
    body_style_id = nil
}

-- Semantic helpers
local function semantic_div(text, class)
    local div = pandoc.Div({pandoc.Para({pandoc.Str(text)})})
    div.classes = {class}
    return div
end

local function vertical_space(twips)
    return pandoc.RawBlock("specdown", "vertical-space:" .. tostring(twips))
end

local function get_spec_attributes(db, spec_ref)
    if not db or not spec_ref then return {} end

    local results = db:query_all([[
        SELECT name, string_value, raw_value
        FROM spec_attribute_values
        WHERE specification_ref = :spec_ref
          AND owner_object_id IS NULL
          AND owner_float_id IS NULL
    ]], {spec_ref = spec_ref})

    local attrs = {}
    if results then
        for _, row in ipairs(results) do
            local name = row.name and row.name:lower() or ""
            attrs[name] = row.string_value or row.raw_value or ""
        end
    end
    return attrs
end

function M._render_body(ctx, db)
    local blocks = {}

    local obj_attrs = ctx.attributes or {}
    local spec_attrs = get_spec_attributes(db, ctx.spec_id)

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
        return ctx.original_blocks
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

function M.on_render_SpecObject(obj, ctx)
    local blocks = {}

    -- No page break at START (capa is first page)
    -- No header for capa

    -- Body
    local body_blocks = M._render_body(ctx, ctx.db)
    render_utils.add_blocks(blocks, body_blocks)

    -- Add page break at END of capa for proper section definition
    -- This ensures the first section is properly terminated before folha de rosto
    -- (folha de rosto also adds oddPage break, but having it here helps LibreOffice)
    render_utils.add_page_break(blocks, "odd")

    return blocks
end

return M
