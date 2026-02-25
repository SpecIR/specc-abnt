---Trabalho Acadêmico Specification Handler for ABNT
---Suppresses the default document title since ABNT uses the Capa (Cover) object.
---The Capa page displays the title via document attributes from \titulo{}.
---
---Per ABNT NBR 14724:2011, academic works (TCC, monografia, dissertação, tese)
---use a cover page (capa) that contains the title - the H1 specification
---heading should NOT appear on the cover page.
---
---@module trabalho_academico
---@author SpecDown Team
---@license MIT

local M = {}

local specification_base = require("pipeline.shared.specification_base")

M.specification = {
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

    -- Implicit aliases for document type detection
    -- These match the H1 heading to determine the specification type
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
}

---Custom header that returns an empty anchor-only Div.
---This suppresses the default document title since ABNT cover pages display the title.
---For abntex2 compatibility, the title is rendered via \titulo{} and \imprimircapa,
---not as a visible H1 heading.
---@param ctx table Render context
---@param pandoc table Pandoc module
---@return table Empty Div with anchor
local function empty_header(ctx, pandoc)
    local spec = ctx.specification
    local anchor_id = spec.pid or spec.identifier or ""

    -- Return empty Div with just the anchor for cross-references
    -- This prevents the assembler from adding the default title ("TRABALHO ACADÊMICO")
    return pandoc.Div({}, pandoc.Attr(anchor_id, {"spec-anchor"}, {}))
end

-- Create handler using specification_base with custom header
M.handler = specification_base.create_handler("trabalho_academico_spec_handler", {
    header = empty_header
})

return M
