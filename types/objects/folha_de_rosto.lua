---FOLHA_DE_ROSTO (ABNT)
---Per ABNT NBR 14724:2011 - Pre-textual element
---
---Uses semantic markers converted by format-specific filters.

local render_utils = require("pipeline.shared.render_utils")

local M = {}

M.name = "folha_de_rosto"

M.object = {
    id = "FOLHA_DE_ROSTO",
    long_name = "Folha de Rosto",
    description = "Title page (Folha de Rosto) - ABNT NBR 14724:2011",
    extends = "PRE_TEXTUAL",
    is_required = true,
    implicit_aliases = { "Folha de Rosto", "Folha de rosto", "Title Page", "Title page" },
    header_style_id = "",
    body_style_id = nil,
    starts_on = "next"  -- Start on next page (odd-page behavior deferred to postprocessor when twoside)
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
    for _, row in ipairs(results or {}) do
        attrs[row.name:lower()] = row.string_value or row.raw_value or ""
    end
    return attrs
end

function M.on_render_SpecObject(obj, ctx)
    local blocks = {}

    -- Page break is handled by capa (at its end) to ensure proper first section definition
    -- Don't add another page break here to avoid duplicate breaks
    -- render_utils.add_page_break(blocks, M.object.starts_on)

    -- No header for folha_de_rosto

    -- Body: Build title page from attributes
    local obj_attrs = ctx.attributes or {}
    local spec_attrs = get_spec_attributes(ctx.db, ctx.spec_id)

    local function get_attr(name)
        local lower = name:lower()
        return obj_attrs[lower] or obj_attrs[name:upper()] or spec_attrs[lower]
    end

    local author = get_attr("author")
    local title = get_attr("title")
    local subtitle = get_attr("subtitle")
    local nature = get_attr("nature")
    local institution = get_attr("institution")
    local advisor = get_attr("advisor")
    local coadvisor = get_attr("coadvisor")
    local city = get_attr("city")
    local year = get_attr("year")

    -- Fallback to original blocks if required attributes missing
    if not (title and author) then
        if ctx.original_blocks and #ctx.original_blocks > 0 then
            render_utils.add_blocks(blocks, ctx.original_blocks)
        end
        return blocks
    end

    -- Build title page matching abntex2 layout:
    -- 1. Author at top (centered)
    -- 2. Title (centered, bold)
    -- 3. Nature/Preâmbulo (right-aligned with indent)
    -- 4. Institution (centered)
    -- 5. Advisor (with label, indented)
    -- 6. Location and year at bottom (centered)
    --
    -- A4 usable height: ~13500 twips. Content: ~5000 twips (with multi-line elements).
    -- Available spacing: ~8500 twips total, distributed conservatively.

    local body_blocks = {}

    -- Author at top
    if author then table.insert(body_blocks, semantic_div(author, "titlepage-author")) end

    -- Space before title (~2.5 inches = 3600 twips) - matching abntex2 \vfill distribution
    table.insert(body_blocks, vertical_space(3600))

    -- Title
    if title then table.insert(body_blocks, semantic_div(title, "titlepage-title")) end
    if subtitle then table.insert(body_blocks, semantic_div(subtitle, "titlepage-subtitle")) end

    -- Space before nature (~1.5 inch = 2160 twips)
    table.insert(body_blocks, vertical_space(2160))

    -- Nature/Preâmbulo (right-aligned with indent)
    if nature then table.insert(body_blocks, semantic_div(nature, "titlepage-nature")) end

    -- Space before advisor (~1 inch = 1440 twips)
    -- Note: abntex2 puts orientador directly under preambulo without institution in between
    table.insert(body_blocks, vertical_space(1440))

    -- Advisor (orientador appears left-aligned/centered in abntex2, not right-indented)
    if advisor then table.insert(body_blocks, semantic_div("Orientador: " .. advisor, "titlepage-advisor")) end
    if coadvisor then table.insert(body_blocks, semantic_div("Coorientador: " .. coadvisor, "titlepage-advisor")) end

    -- Location and year at bottom - use absolute positioning like cover page
    -- These will be positioned from page bottom by the DOCX filter
    if city then table.insert(body_blocks, semantic_div(city, "titlepage-location")) end
    if year then table.insert(body_blocks, semantic_div(year, "titlepage-year")) end

    render_utils.add_blocks(blocks, body_blocks)

    return blocks
end

return M
