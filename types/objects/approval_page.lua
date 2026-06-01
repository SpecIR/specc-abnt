---APPROVAL_PAGE - Folha de Aprovacao (ABNT)
---Per ABNT NBR 14724:2011 - Section 4.2.1.3
---The approval page where the examining board records their approval

local render_utils = require("pipeline.shared.render_utils")

local function placeholder_div(ctx)
    return ctx.pandoc.Div({
        ctx.pandoc.Para({
            ctx.pandoc.Str("Folha de aprovação"),
            ctx.pandoc.LineBreak(),
            ctx.pandoc.LineBreak(),
            ctx.pandoc.Str("Substitua esta página pela folha de aprovação"),
            ctx.pandoc.LineBreak(),
            ctx.pandoc.Str("definitiva emitida ou validada pela instituição."),
        })
    }, ctx.pandoc.Attr("", {"approval-page-placeholder"}, {}))
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
        or docx.approval_page_pdf
        or docx.approval_pdf
        or docx.folha_de_aprovacao_pdf
        or docx.folhadeaprovacao_pdf
end

local function uses_default_asset(ctx)
    local docx = ctx.config.docx or {}
    return docx.approval_page ~= false
        and docx.approval_page_image ~= false
        and docx.use_approval_page_image ~= false
end

return {
    kind = "object",
    schema = {
        id = "APPROVAL_PAGE",
        long_name = "Folha de Aprovação",
        description = "Approval page (Folha de Aprovação) - ABNT NBR 14724:2011",
        extends = "PRE_TEXTUAL",
        implicit_aliases = {
            "Folha de Aprovação",
            "Folha de aprovação",
            "Folha de Aprovacao",
            "Approval Page",
            "Approval"
        },
        header_style_id = "",  -- No visible header - uses custom OOXML layout
        body_style_id = nil,
        attributes = {
            { name = "approval_date", type = "STRING" },
            { name = "examiner", type = "STRING" },
            { name = "pdf_path", type = "STRING" }
        }
    },
    hooks = {
        render = function(ctx)
            local obj = ctx.subject.object
            local blocks = {}

            render_utils.add_page_break(blocks, "next")

            if ctx.format == "docx"
                and (configured_pdf(ctx) or (not has_content(ctx.subject.element) and uses_default_asset(ctx))) then
                table.insert(blocks, ctx.pandoc.RawBlock("speccompiler", "abnt-full-page:approval-page"))
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
