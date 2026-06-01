---CATALOG_SHEET - Ficha Catalografica (ABNT)
---Per ABNT NBR 14724:2011 - Section 4.2.1.1.2
---Contains bibliographic data for library cataloging

local render_utils = require("pipeline.shared.render_utils")

local function placeholder_div(ctx)
    return ctx.pandoc.Div({
        ctx.pandoc.Para({
            ctx.pandoc.Str("Ficha catalográfica"),
            ctx.pandoc.LineBreak(),
            ctx.pandoc.LineBreak(),
            ctx.pandoc.Str("Substitua esta página pela ficha catalográfica"),
            ctx.pandoc.LineBreak(),
            ctx.pandoc.Str("definitiva fornecida pela biblioteca responsável."),
        }),
    }, ctx.pandoc.Attr("", {"catalog-sheet-placeholder"}, {}))
end

local function has_content(blocks)
    return blocks and #blocks > 0
end

local function attr_value(attrs, name)
    local value = attrs and attrs[name]
    if type(value) == "table" then
        return value.value
    end
    return value
end

local function configured_pdf(ctx)
    local docx = ctx.config.docx or {}
    return attr_value(ctx.subject.attributes, "pdf_path")
        or docx.catalog_sheet_pdf
        or docx.catalog_pdf
        or docx.fichacatalografica_pdf
end

local function uses_default_asset(ctx)
    local docx = ctx.config.docx or {}
    return docx.catalog_sheet ~= false
        and docx.catalog_sheet_image ~= false
        and docx.use_catalog_sheet_image ~= false
end

return {
    kind = "object",
    schema = {
        id = "CATALOG_SHEET",
        long_name = "Ficha Catalográfica",
        description = "Cataloging sheet (Ficha Catalográfica) - ABNT NBR 14724:2011",
        extends = "PRE_TEXTUAL",
        implicit_aliases = {
            "Ficha Catalográfica",
            "Ficha catalográfica",
            "Ficha Catalográfica",
            "Catalog Sheet",
            "Cataloging Sheet"
        },
        header_style_id = "",  -- No visible header
        body_style_id = nil,
        attributes = {
            { name = "pdf_path", type = "STRING" }
        }
    },
    hooks = {
        render = function(ctx)
            local blocks = {}

            render_utils.add_page_break(blocks, "next")

            if ctx.format == "docx"
                and (configured_pdf(ctx) or (not has_content(ctx.subject.element) and uses_default_asset(ctx))) then
                table.insert(blocks, ctx.pandoc.RawBlock("speccompiler", "abnt-full-page:catalog-sheet"))
            elseif has_content(ctx.subject.element) then
                render_utils.add_blocks(blocks, ctx.subject.element)
            else
                render_utils.add_blocks(blocks, {
                    placeholder_div(ctx),
                })
            end

            return blocks
        end,
    },
}
