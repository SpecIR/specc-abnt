---Trabalho Acadêmico Specification type for ABNT.
---Suppresses the default document title since ABNT uses the Capa (Cover) object.
---The Capa page displays the title via document attributes from \titulo{}.
---
---Per ABNT NBR 14724:2011, academic works (TCC, monografia, dissertação, tese)
---use a cover page (capa) that contains the title - the H1 specification
---heading should NOT appear on the cover page. The render hook therefore emits
---an empty anchor-only Div (truthy, so the assembler does not inject the default
---long_name title), and the type does NOT extend SPEC_TITLE.
---
---@module trabalho_academico
---@author SpecDown Team
---@license MIT

return {
    kind = "specification",
    schema = {
        id = "TRABALHO_ACADEMICO",
        long_name = "Trabalho Acadêmico",
        description = "Academic work document (TCC, monografia, dissertação, tese) per ABNT NBR 14724",
        style = "ABNT",
        is_default = true,  -- Default spec type for ABNT model - suppresses spec title on cover page

        -- Document-level attributes for ABNT academic works
        attributes = {
            { name = "title", type = "STRING", required = true, label = "Título", description = "Título do trabalho" },
            { name = "subtitle", type = "STRING", required = false, label = "Subtítulo", description = "Subtítulo do trabalho" },
            { name = "author", type = "STRING", required = true, label = "Autor", description = "Nome do autor" },
            { name = "advisor", type = "STRING", required = false, label = "Orientador", description = "Nome do orientador" },
            { name = "coadvisor", type = "STRING", required = false, label = "Coorientador", description = "Nome do coorientador" },
            { name = "institution", type = "STRING", required = false, label = "Instituição", description = "Nome da instituição" },
            { name = "faculty", type = "STRING", required = false, label = "Faculdade", description = "Nome da faculdade" },
            { name = "department", type = "STRING", required = false, label = "Departamento", description = "Nome do departamento" },
            { name = "course", type = "STRING", required = false, label = "Curso", description = "Nome do curso" },
            { name = "nature", type = "STRING", required = false, label = "Natureza", description = "Natureza do trabalho (preâmbulo)" },
            { name = "city", type = "STRING", required = false, label = "Cidade", description = "Cidade" },
            { name = "year", type = "STRING", required = false, label = "Ano", description = "Ano de publicação" },
            { name = "date", type = "DATE", required = false, label = "Data", description = "Data do documento" }
        },

        -- Default types by header level
        default_types = {
            ["2"] = "SECTION",
            ["3+"] = "SECTION"
        },

        -- Allowed object types for ABNT academic works
        allowed_objects = {
            -- Pre-textual elements
            CAPA = { required = true },
            FOLHA_DE_ROSTO = { required = true },
            ERRATA = { required = false },
            CATALOG_SHEET = { required = false },
            APPROVAL_PAGE = { required = false },
            DEDICATORIA = { required = false },
            AGRADECIMENTOS = { required = false },
            EPIGRAFE = { required = false },
            ABSTRACT = { required = true },  -- Resumo + Abstract
            TOC = { required = true },
            LIST_OF_FIGURES = { required = false },
            LIST_OF_TABLES = { required = false },
            LIST_OF_ABBREVIATIONS = { required = false },
            LIST_OF_SYMBOLS = { required = false },

            -- Textual elements
            INTRODUCTION = { required = true },
            DEVELOPMENT = { required = true },
            CONCLUSION = { required = true },
            SECTION = { required = false },

            -- Post-textual elements
            REFERENCES = { required = true },
            GLOSSARY = { required = false },
            APPENDIX = { required = false },
            ANNEX = { required = false },
            INDEX = { required = false }
        },

        -- Implicit aliases for document type detection (match the H1 heading)
        implicit_aliases = {
            "Trabalho Acadêmico",
            "Trabalho de Conclusão de Curso",
            "TCC",
            "Monografia",
            "Dissertação",
            "Dissertacao",
            "Tese",
            "Academic Work",
            "Thesis",
            "Dissertation"
        }
    },
    hooks = {
        ---Empty anchor-only header: suppresses the default document title (the
        ---Capa carries it). Must return a truthy Div so the assembler skips its
        ---default long_name-title fallback.
        ---@param ctx table canonical ctx (subject.specification, pandoc)
        ---@return table Pandoc Div (empty, anchor only)
        render = function(ctx)
            local spec = ctx.subject.specification
            local anchor_id = spec.pid or spec.identifier or ""
            return ctx.pandoc.Div({}, ctx.pandoc.Attr(anchor_id, { "spec-anchor" }, {}))
        end,
    },
}
