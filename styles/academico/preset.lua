---ABNT NBR 14724:2011 Compliant Style Preset for SpecDown v2.
---Based on abntex2 LaTeX class specifications for Brazilian academic documents.
---
---Key specifications:
--- - NBR 14724/2011 - 5.1: Margins (left 3cm, right 2cm, top 3cm, bottom 2cm)
--- - NBR 14724/2011 - 5.2: Line spacing 1.5
--- - NBR 6027:2012: Table of contents formatting
--- - Heading font: Sans-serif (Arial)
--- - Body font: Serif (Times New Roman, 12pt)
--- - Caption separator: Em-dash (-)
--- - Footnotes: 10pt
--- - Long quotes (>3 lines): 10pt, single spacing, 4cm indent
---
---Ported from v1's abnt/styles/academico/preset.ts
---@module preset

-- Load model config for language setting
local config = require("models.abnt.config")
local default_language = config.language.default

return {
    name = "Academico (NBR 14724)",
    description = "Brazilian academic standards (ABNT NBR 14724:2011)",

    -- Two-sided printing (anverso/verso) - NBR 14724:2011 section 5.1
    two_sided = true,

    -- ========================================================================
    -- Page Configuration (NBR 14724:2011 - 5.1)
    -- ========================================================================
    page = {
        size = "A4",
        orientation = "portrait",
        margins = {
            top = "3cm",
            bottom = "2cm",
            left = "3cm",   -- Inner margin for binding (anverso)
            right = "2cm",  -- Outer margin
        },
    },

    -- ========================================================================
    -- Paragraph Styles
    -- ========================================================================
    paragraph_styles = {
        -- Normal body text
        -- abntex2: \parindent=1.3cm
        {
            id = "Normal",
            name = "Normal",
            font = { name = "Times New Roman", size = 12 },
            spacing = { line = 1.5, after = 0 },
            indent = { first_line = "1.3cm" },
            alignment = "justified",
            widow_control = true,
        },

        -- Heading 1: CHAPTER TITLE (all caps, bold)
        -- abntex2: \chapter uses \ABNTEXchapterfont (Arial/Helvetica Bold, ~14pt)
        {
            id = "Heading1",
            name = "Heading 1",
            based_on = "Normal",
            next = "FirstParagraph",
            font = { name = "Arial", size = 14, bold = true, all_caps = true },
            spacing = { before = 0, after = 18, line = 1.0 },
            indent = { first_line = "0cm" },
            keep_next = true,
            keep_lines = true,
            page_break_before = true,
            outline_level = 0,
            widow_control = true,
        },

        -- Heading 2: Section title (bold)
        {
            id = "Heading2",
            name = "Heading 2",
            based_on = "Normal",
            next = "FirstParagraph",
            font = { name = "Arial", size = 12, bold = true },
            spacing = { before = 12, after = 6, line = 1.0 },
            indent = { first_line = "0cm" },
            keep_next = true,
            keep_lines = true,
            outline_level = 1,
            widow_control = true,
        },

        -- Heading 3: Subsection title (bold + italic)
        {
            id = "Heading3",
            name = "Heading 3",
            based_on = "Normal",
            next = "FirstParagraph",
            font = { name = "Arial", size = 12, bold = true, italic = true },
            spacing = { before = 12, after = 6, line = 1.0 },
            indent = { first_line = "0cm" },
            keep_next = true,
            keep_lines = true,
            outline_level = 2,
            widow_control = true,
        },

        -- Heading 4: Sub-subsection (italic only)
        {
            id = "Heading4",
            name = "Heading 4",
            based_on = "Normal",
            next = "FirstParagraph",
            font = { name = "Arial", size = 12, italic = true },
            spacing = { before = 12, after = 6, line = 1.0 },
            indent = { first_line = "0cm" },
            keep_next = true,
            keep_lines = true,
            outline_level = 3,
            widow_control = true,
        },

        -- Heading 5: Sub-sub-subsection (normal weight)
        {
            id = "Heading5",
            name = "Heading 5",
            based_on = "Normal",
            next = "FirstParagraph",
            font = { name = "Arial", size = 12 },
            spacing = { before = 12, after = 6, line = 1.0 },
            indent = { first_line = "0cm" },
            keep_next = true,
            keep_lines = true,
            outline_level = 4,
            widow_control = true,
        },

        -- Title (document title)
        {
            id = "Title",
            name = "Title",
            based_on = "Normal",
            next = "Normal",
            font = { name = "Arial", size = 14, bold = true, all_caps = true },
            spacing = { before = 0, after = 24, line = 1.5 },
            indent = { first_line = "0cm" },
            alignment = "center",
            widow_control = true,
        },

        -- Subtitle
        {
            id = "Subtitle",
            name = "Subtitle",
            based_on = "Normal",
            next = "Normal",
            font = { name = "Arial", size = 12 },
            spacing = { before = 0, after = 24, line = 1.5 },
            indent = { first_line = "0cm" },
            alignment = "center",
            widow_control = true,
        },

        -- Caption (general - used for floats)
        -- ABNT: Caption centered, 10pt, with spacing
        {
            id = "Caption",
            name = "Caption",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 10 },
            spacing = { before = 12, after = 6, line = 1.0 },
            indent = { first_line = "0cm" },
            alignment = "center",
            keep_next = true,
        },

        -- Table Caption - ABNT: Table caption goes ABOVE the table
        {
            id = "TableCaption",
            name = "Table Caption",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 10 },
            spacing = { before = 12, after = 6, line = 1.0 },
            indent = { first_line = "0cm" },
            alignment = "center",
            keep_next = true,
            keep_lines = true,
        },

        -- Image Caption - for figures (Pandoc uses this)
        {
            id = "ImageCaption",
            name = "Image Caption",
            based_on = "Caption",
            font = { name = "Times New Roman", size = 10 },
            spacing = { before = 12, after = 6, line = 1.0 },
            indent = { first_line = "0cm" },
            alignment = "center",
            keep_next = true,
            keep_lines = true,
        },

        -- Source line (generic - below figures/tables)
        -- ABNT: "Fonte:" centered below the element
        {
            id = "Source",
            name = "Source",
            based_on = "Caption",
            font = { name = "Times New Roman", size = 10 },
            spacing = { before = 6, after = 12, line = 1.0 },
            indent = { first_line = "0cm" },
            alignment = "center",
        },

        -- Figure Source
        {
            id = "FigureSource",
            name = "Figure Source",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 10 },
            spacing = { before = 6, after = 12, line = 1.0 },
            indent = { first_line = "0cm" },
            alignment = "center",
        },

        -- Table Source
        {
            id = "TableSource",
            name = "Table Source",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 10 },
            spacing = { before = 6, after = 12, line = 1.0 },
            indent = { first_line = "0cm" },
            alignment = "center",
        },

        -- Footnote Text
        {
            id = "FootnoteText",
            name = "Footnote Text",
            font = { name = "Times New Roman", size = 10 },
            spacing = { line = 1.0, after = 0 },
            alignment = "justified",
        },

        -- Block Quote (citacao longa - >3 lines)
        -- NBR 10520: 4cm left indent, 10pt, single spacing
        {
            id = "Quote",
            name = "Quote",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 10 },
            spacing = { line = 1.0, before = 12, after = 12 },
            indent = { left = "4cm" },
            alignment = "justified",
        },

        -- List Paragraph
        {
            id = "ListParagraph",
            name = "List Paragraph",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 12 },
            spacing = { line = 1.5, after = 0 },
            indent = { left = "1.27cm", hanging = "0.63cm" },
        },

        -- TOC styles
        -- TOC heading should match pre-textual unnumbered headings (abntex2 \chapter*)
        {
            id = "TOCHeading",
            name = "TOC Heading",
            based_on = "Normal",
            next = "Normal",
            font = { name = "Arial", size = 18, bold = false, all_caps = true },
            spacing = { before = 0, after = 24, line = 1.0 },
            alignment = "center",
            keep_next = true,
            keep_lines = true,
        },

        {
            id = "TOC1",
            name = "TOC 1",
            based_on = "Normal",
            next = "Normal",
            font = { name = "Times New Roman", size = 12, bold = true },
            spacing = { before = 12, after = 0, line = 1.5 },
        },

        {
            id = "TOC2",
            name = "TOC 2",
            based_on = "Normal",
            next = "Normal",
            font = { name = "Times New Roman", size = 12 },
            spacing = { before = 0, after = 0, line = 1.5 },
            indent = { left = "0.5cm" },
        },

        {
            id = "TOC3",
            name = "TOC 3",
            based_on = "Normal",
            next = "Normal",
            font = { name = "Times New Roman", size = 12 },
            spacing = { before = 0, after = 0, line = 1.5 },
            indent = { left = "1cm" },
        },

        -- Body Text
        {
            id = "BodyText",
            name = "Body Text",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 12 },
            spacing = { line = 1.5, after = 0 },  -- Changed from 12 to 0 to match Normal/LaTeX
            indent = { first_line = "1.3cm" },
            alignment = "justified",
            widow_control = true,
        },

        -- First Paragraph (no indent, with space before for separation from floats)
        {
            id = "FirstParagraph",
            name = "First Paragraph",
            based_on = "Normal",
            next = "Normal",
            font = { name = "Times New Roman", size = 12 },
            spacing = { before = 6, line = 1.5, after = 0 },  -- 6pt before for separation
            indent = { first_line = "0cm" },
            alignment = "justified",
            widow_control = true,
        },

        -- Code/Listing style
        {
            id = "Code",
            name = "Code",
            font = { name = "Courier New", size = 9 },
            spacing = { line = 1.0, before = 0, after = 0 },
            alignment = "left",
        },

        -- SourceCode - Pandoc's default for syntax-highlighted code
        {
            id = "SourceCode",
            name = "Source Code",
            font = { name = "Courier New", size = 9 },
            spacing = { line = 1.0, before = 6, after = 6 },
            alignment = "left",
        },

        -- Compact - for tight lists
        {
            id = "Compact",
            name = "Compact",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 12 },
            spacing = { line = 1.0, before = 0, after = 0 },
            indent = { first_line = "0cm" },
        },

        -- ====================================================================
        -- ABNT Section Type Styles (NBR 14724:2011)
        -- ====================================================================

        -- Unnumbered Heading - for pre/post-textual elements
        -- abntex2 uses \chapter* which renders as ~18pt, not bold, centered
        {
            id = "UnnumberedHeading",
            name = "Unnumbered Heading",
            based_on = "Normal",  -- NOT Heading1 to avoid numbering inheritance
            next = "FirstParagraph",
            font = {
                name = "Arial",
                size = 18,        -- Match abntex2 \chapter* size (~\LARGE)
                bold = false,     -- abntex2 uses regular weight for chapter*
            },
            caps = true,  -- ALL CAPS
            alignment = "center",
            spacing = {
                before = 0,
                after = 24,       -- More space after heading (match abntex2)
                line = 1.0,       -- Single spacing
            },
            outline_level = 1,  -- Required for TOC inclusion
            keep_next = true,
            keep_lines = true,
        },

        -- ====================================================================
        -- Cover Page Styles (Capa - ABNT NBR 14724:2011)
        -- ====================================================================

        {
            id = "CoverInstitution",
            name = "Cover Institution",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 12, bold = true, all_caps = true },
            spacing = { before = 0, after = 0, line = 1.5 },
            indent = { first_line = "0cm" },
            alignment = "center",
        },

        {
            id = "CoverDepartment",
            name = "Cover Department",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 12 },
            spacing = { before = 0, after = 0, line = 1.5 },
            indent = { first_line = "0cm" },
            alignment = "center",
        },

        {
            id = "CoverTitle",
            name = "Cover Title",
            based_on = "Normal",
            -- abntex2 uses \ABNTEXchapterfont\bfseries\LARGE
            font = { name = "Times New Roman", size = 22, bold = true, all_caps = true },
            spacing = { before = 0, after = 0, line = 1.0 },
            indent = { first_line = "0cm" },
            alignment = "center",
        },

        {
            id = "CoverSubtitle",
            name = "Cover Subtitle",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 12 },
            spacing = { before = 0, after = 0, line = 1.5 },
            indent = { first_line = "0cm" },
            alignment = "center",
        },

        {
            id = "CoverAuthor",
            name = "Cover Author",
            based_on = "Normal",
            -- abntex2 cover uses single-spaced text
            font = { name = "Times New Roman", size = 12 },
            spacing = { before = 0, after = 0, line = 1.0 },
            indent = { first_line = "0cm" },
            alignment = "center",
        },

        {
            id = "CoverNature",
            name = "Cover Nature",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 10 },
            spacing = { before = 0, after = 0, line = 1.0 },
            indent = { left = "8cm", first_line = "0cm" },
            alignment = "justified",
        },

        {
            id = "CoverAdvisor",
            name = "Cover Advisor",
            based_on = "CoverNature",
            font = { name = "Times New Roman", size = 10 },
            spacing = { before = 6, after = 0, line = 1.0 },
            indent = { left = "8cm", first_line = "0cm" },
            alignment = "left",
        },

        {
            id = "CoverLocation",
            name = "Cover Location",
            based_on = "Normal",
            -- Single line spacing to match abntex2 cover
            font = { name = "Times New Roman", size = 12 },
            spacing = { before = 0, after = 0, line = 1.0 },
            indent = { first_line = "0cm" },
            alignment = "center",
        },

        {
            id = "CoverYear",
            name = "Cover Year",
            based_on = "CoverLocation",
            -- Single line spacing to match abntex2 cover
            font = { name = "Times New Roman", size = 12 },
            spacing = { before = 0, after = 0, line = 1.0 },
            indent = { first_line = "0cm" },
            alignment = "center",
        },

        -- ====================================================================
        -- Title Page Styles (Folha de Rosto - ABNT NBR 14724:2011)
        -- Similar to Cover but for the inner title page
        -- ====================================================================

        {
            id = "TitlePageTitle",
            name = "Title Page Title",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 14, bold = true, all_caps = true },
            spacing = { before = 0, after = 0, line = 1.5 },
            indent = { first_line = "0cm" },
            alignment = "center",
        },

        {
            id = "TitlePageAuthor",
            name = "Title Page Author",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 12 },
            spacing = { before = 0, after = 0, line = 1.5 },
            indent = { first_line = "0cm" },
            alignment = "center",
        },

        {
            id = "TitlePageNature",
            name = "Title Page Nature",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 10 },
            spacing = { before = 0, after = 0, line = 1.0 },
            indent = { left = "8cm", first_line = "0cm" },
            alignment = "justified",
        },

        {
            id = "TitlePageInstitution",
            name = "Title Page Institution",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 12 },
            spacing = { before = 0, after = 0, line = 1.5 },
            indent = { first_line = "0cm" },
            alignment = "center",
        },

        {
            id = "TitlePageAdvisor",
            name = "Title Page Advisor",
            based_on = "TitlePageNature",
            font = { name = "Times New Roman", size = 10 },
            spacing = { before = 6, after = 0, line = 1.0 },
            indent = { left = "8cm", first_line = "0cm" },
            alignment = "left",
        },

        {
            id = "TitlePageLocation",
            name = "Title Page Location",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 12 },
            spacing = { before = 0, after = 0, line = 1.5 },
            indent = { first_line = "0cm" },
            alignment = "center",
        },

        {
            id = "TitlePageYear",
            name = "Title Page Year",
            based_on = "TitlePageLocation",
            font = { name = "Times New Roman", size = 12 },
            spacing = { before = 0, after = 0, line = 1.5 },
            indent = { first_line = "0cm" },
            alignment = "center",
        },

        -- ====================================================================
        -- Book Part Style (for book-style documents)
        -- ====================================================================

        {
            id = "BookPart",
            name = "Book Part",
            based_on = "Normal",
            next = "Normal",
            font = { name = "Arial", size = 18, bold = true, all_caps = true },
            spacing = { before = 0, after = 24, line = 1.0 },
            indent = { first_line = "0cm" },
            alignment = "center",
            keep_next = true,
            keep_lines = true,
            page_break_before = true,
        },

        -- Abstract body style - single spacing per ABNT NBR 6028:2003
        {
            id = "Abstract",
            name = "Abstract",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 12 },
            lang = "en-US",
            spacing = { line = 1.0, after = 12 },
            indent = { first_line = "0cm" },
            alignment = "justified",
        },

        -- Resumo body style - Portuguese version
        {
            id = "Resumo",
            name = "Resumo",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 12 },
            lang = "pt-BR",
            spacing = { line = 1.0, after = 12 },
            indent = { first_line = "0cm" },
            alignment = "justified",
        },

        -- Dedication style
        {
            id = "Dedication",
            name = "Dedication",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 12, italic = true },
            spacing = { before = 0, after = 0, line = 1.5 },
            indent = { left = "8cm", first_line = "0cm" },
            alignment = "right",
        },

        -- Epigraph style
        {
            id = "Epigraph",
            name = "Epigraph",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 10 },
            spacing = { before = 0, after = 0, line = 1.5 },
            indent = { left = "8cm", first_line = "0cm" },
            alignment = "right",
        },

        -- Reference entry style
        {
            id = "Reference",
            name = "Reference",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 12 },
            spacing = { before = 0, after = 12, line = 1.0 },
            indent = { left = "0cm", first_line = "0cm", hanging = "0cm" },
            alignment = "left",
        },

        -- Appendix Heading
        -- Match abntex2 chapter style for appendices
        {
            id = "AppendixHeading",
            name = "Appendix Heading",
            based_on = "Heading1",
            next = "FirstParagraph",
            font = { name = "Arial", size = 14, bold = true, all_caps = true },
            spacing = { before = 0, after = 18, line = 1.0 },
            indent = { first_line = "0cm" },
            alignment = "center",
            keep_next = true,
            keep_lines = true,
            outline_level = 0,
            widow_control = true,
        },

        -- Annex Heading
        {
            id = "AnnexHeading",
            name = "Annex Heading",
            based_on = "AppendixHeading",
            next = "FirstParagraph",
            font = { name = "Arial", size = 14, bold = true, all_caps = true },
        },

        -- Index style
        {
            id = "Index",
            name = "Index",
            based_on = "Normal",
            font = { name = "Times New Roman", size = 10 },
            spacing = { line = 1.0, after = 0 },
            indent = { left = "0cm", hanging = "0.5cm", first_line = "0cm" },
            alignment = "left",
        },
    },

    -- ========================================================================
    -- Character Styles
    -- ========================================================================
    character_styles = {
        {
            id = "Strong",
            name = "Strong",
            font = { bold = true },
        },
        {
            id = "Emphasis",
            name = "Emphasis",
            font = { italic = true },
        },
        {
            id = "CodeChar",
            name = "Code Char",
            font = { name = "Courier New", size = 9 },
        },
        {
            id = "VerbatimChar",
            name = "Verbatim Char",
            font = { name = "Courier New", size = 9 },
        },
        -- Pandoc syntax highlighting tokens
        {
            id = "NormalTok",
            name = "Normal Token",
            font = { name = "Courier New", size = 9 },
        },
        {
            id = "KeywordTok",
            name = "Keyword Token",
            font = { name = "Courier New", size = 9, bold = true },
        },
        {
            id = "DataTypeTok",
            name = "DataType Token",
            font = { name = "Courier New", size = 9, color = "902000" },
        },
        {
            id = "DecValTok",
            name = "DecVal Token",
            font = { name = "Courier New", size = 9, color = "40a070" },
        },
        {
            id = "StringTok",
            name = "String Token",
            font = { name = "Courier New", size = 9, color = "4070a0" },
        },
        {
            id = "CommentTok",
            name = "Comment Token",
            font = { name = "Courier New", size = 9, italic = true, color = "60a0b0" },
        },
        {
            id = "FunctionTok",
            name = "Function Token",
            font = { name = "Courier New", size = 9, color = "06287e" },
        },
        {
            id = "OperatorTok",
            name = "Operator Token",
            font = { name = "Courier New", size = 9, color = "666666" },
        },
        {
            id = "AlertTok",
            name = "Alert Token",
            font = { name = "Courier New", size = 9, bold = true, color = "ff0000" },
        },
        {
            id = "ErrorTok",
            name = "Error Token",
            font = { name = "Courier New", size = 9, bold = true, color = "ff0000" },
        },
    },

    -- ========================================================================
    -- Table Styles
    -- ========================================================================
    table_styles = {
        -- ABNT Table: horizontal lines only
        {
            id = "ABNTTable",
            name = "ABNT Table",
            spacing = { before = 0, after = 0 },
            borders = {
                top = { style = "single", width = 1, color = "000000" },
                bottom = { style = "single", width = 1, color = "000000" },
                left = { style = "none", width = 0, color = "000000" },
                right = { style = "none", width = 0, color = "000000" },
                inside_h = { style = "none", width = 0, color = "000000" },
                inside_v = { style = "none", width = 0, color = "000000" },
            },
            cell_margins = {
                top = "1mm",
                bottom = "1mm",
                left = "2mm",
                right = "2mm",
            },
            header_row = {
                font = { bold = true },
                borders = {
                    bottom = { style = "single", width = 1, color = "000000" },
                },
            },
            autofit = true,
        },

        -- Grid table
        {
            id = "TableGrid",
            name = "Table Grid",
            spacing = { before = 0, after = 0 },
            borders = {
                top = { style = "single", width = 0.5, color = "000000" },
                bottom = { style = "single", width = 0.5, color = "000000" },
                left = { style = "single", width = 0.5, color = "000000" },
                right = { style = "single", width = 0.5, color = "000000" },
                inside_h = { style = "single", width = 0.5, color = "000000" },
                inside_v = { style = "single", width = 0.5, color = "000000" },
            },
            cell_margins = {
                top = "1mm",
                bottom = "1mm",
                left = "2mm",
                right = "2mm",
            },
            autofit = true,
        },

        -- Table (Pandoc default)
        {
            id = "Table",
            name = "Table",
            spacing = { before = 0, after = 0 },
            borders = {
                top = { style = "single", width = 0.5, color = "000000" },
                bottom = { style = "single", width = 0.5, color = "000000" },
                left = { style = "single", width = 0.5, color = "000000" },
                right = { style = "single", width = 0.5, color = "000000" },
                inside_h = { style = "single", width = 0.5, color = "000000" },
                inside_v = { style = "single", width = 0.5, color = "000000" },
            },
            cell_margins = {
                top = "1mm",
                bottom = "1mm",
                left = "2mm",
                right = "2mm",
            },
            autofit = true,
        },
    },

    -- ========================================================================
    -- Caption Formats (ABNT uses em-dash separator)
    -- ========================================================================
    captions = {
        figure = {
            template = "{prefix} {number} {separator} {title}",
            prefix = "Figura",
            separator = "-",  -- Em-dash
            style = "Caption",
        },
        table = {
            template = "{prefix} {number} {separator} {title}",
            prefix = "Tabela",
            separator = "-",
            style = "Caption",
        },
        listing = {
            template = "{prefix} {number} {separator} {title}",
            prefix = "Quadro",
            separator = "–",
            style = "Caption",
        },
        equation = {
            template = "({number})",
            prefix = "",
            separator = "",
            style = "Caption",
        },
        chart = {
            template = "{prefix} {number} {separator} {title}",
            prefix = "Gráfico",
            separator = "–",
            style = "Caption",
        },
    },

    -- ========================================================================
    -- Enhanced Captions (ABNT chapter-prefixed numbering)
    -- ========================================================================
    enhanced_captions = {
        figure = {
            template = "{prefix} {number} {separator} {title}",
            prefix = "Figura",
            separator = "-",
            style = "ImageCaption",
            chapter_numbering = true,
            chapter_separator = "-",
            chapter_level = 1,
            sequence_name = "Figure",
            position = "below",
            source_style = "FigureSource",
            source_prefix = "Fonte: ",
        },
        table = {
            template = "{prefix} {number} {separator} {title}",
            prefix = "Tabela",
            separator = "-",
            style = "TableCaption",
            chapter_numbering = true,
            chapter_separator = "-",
            chapter_level = 1,
            sequence_name = "Table",
            position = "above",
            source_style = "TableSource",
            source_prefix = "Fonte: ",
        },
        listing = {
            template = "{prefix} {number} {separator} {title}",
            prefix = "Quadro",
            separator = "–",
            style = "Caption",
            chapter_numbering = true,
            chapter_separator = ".",
            chapter_level = 1,
            sequence_name = "Quadro",
            position = "above",
            source_style = "Source",
            source_prefix = "Fonte: ",
        },
        chart = {
            template = "{prefix} {number} {separator} {title}",
            prefix = "Gráfico",
            separator = "–",
            style = "Caption",
            chapter_numbering = true,
            chapter_separator = ".",
            chapter_level = 1,
            sequence_name = "Grafico",
            position = "below",
            source_style = "Source",
            source_prefix = "Fonte: ",
        },
        equation = {
            template = "({number})",
            prefix = "",
            separator = "",
            style = "Caption",
            chapter_numbering = true,
            chapter_separator = "-",
            chapter_level = 1,
            sequence_name = "Equation",
            position = "below",
        },
    },

    -- ========================================================================
    -- Float Configuration (ABNT-specific)
    -- ========================================================================
    floats = {
        source_self_text = "O autor",
        source_template = "Fonte: %s",
        source_style = "Source",
        caption_positions = {
            FIGURE = 'before',
            CHART = 'before',
            PLANTUML = 'before',
            TABLE = 'before',
            LISTING = 'before',
            MATH = 'inline',
        },
    },

    -- ========================================================================
    -- Numbering Configuration
    -- ========================================================================
    numbering = {
        abstract_num = {
            -- Heading numbering (1., 1.1., 1.1.1., etc.)
            {
                abstract_num_id = 0,
                name = "HeadingNumbering",
                multi_level_type = "multilevel",
                levels = {
                    { level = 0, format = "decimal", text = "%1", alignment = "left", start = 1, indent = { left = "0cm", hanging = "0cm" }, suffix = "space" },
                    { level = 1, format = "decimal", text = "%1.%2", alignment = "left", start = 1, restart_level = 0, indent = { left = "0cm", hanging = "0cm" }, suffix = "space" },
                    { level = 2, format = "decimal", text = "%1.%2.%3", alignment = "left", start = 1, restart_level = 1, indent = { left = "0cm", hanging = "0cm" }, suffix = "space" },
                    { level = 3, format = "decimal", text = "%1.%2.%3.%4", alignment = "left", start = 1, restart_level = 2, indent = { left = "0cm", hanging = "0cm" }, suffix = "space" },
                    { level = 4, format = "decimal", text = "%1.%2.%3.%4.%5", alignment = "left", start = 1, restart_level = 3, indent = { left = "0cm", hanging = "0cm" }, suffix = "space" },
                },
            },
            -- Bullet list
            {
                abstract_num_id = 1,
                name = "BulletList",
                multi_level_type = "hybridMultilevel",
                levels = {
                    { level = 0, format = "bullet", text = "*", alignment = "left", indent = { left = "1.27cm", hanging = "0.63cm" }, suffix = "tab" },
                    { level = 1, format = "bullet", text = "-", alignment = "left", indent = { left = "1.9cm", hanging = "0.63cm" }, suffix = "tab" },
                    { level = 2, format = "bullet", text = ".", alignment = "left", indent = { left = "2.54cm", hanging = "0.63cm" }, suffix = "tab" },
                },
            },
            -- Numbered list (a), b), c) style - ABNT)
            {
                abstract_num_id = 2,
                name = "NumberedListABNT",
                multi_level_type = "hybridMultilevel",
                levels = {
                    { level = 0, format = "lowerLetter", text = "%1)", alignment = "left", start = 1, indent = { left = "1.27cm", hanging = "0.63cm" }, suffix = "tab" },
                    { level = 1, format = "bullet", text = "-", alignment = "left", start = 1, restart_level = 0, indent = { left = "1.9cm", hanging = "0.63cm" }, suffix = "tab" },
                    { level = 2, format = "decimal", text = "%3.", alignment = "left", start = 1, restart_level = 1, indent = { left = "2.54cm", hanging = "0.63cm" }, suffix = "tab" },
                },
            },
        },
        num = {
            { num_id = 1, abstract_num_id = 0 },
            { num_id = 2, abstract_num_id = 1 },
            { num_id = 3, abstract_num_id = 2 },
            { num_id = 4, abstract_num_id = 3 },
            { num_id = 5, abstract_num_id = 4 },
        },
    },

    -- Letter sequence for Appendix
    appendix_numbering = {
        abstract_num_id = 3,
        name = "AppendixNumbering",
        multi_level_type = "singleLevel",
        levels = {
            { level = 0, format = "upperLetter", text = "APENDICE %1", alignment = "center", start = 1, suffix = "nothing" },
        },
    },

    -- Letter sequence for Annex
    annex_numbering = {
        abstract_num_id = 4,
        name = "AnnexNumbering",
        multi_level_type = "singleLevel",
        levels = {
            { level = 0, format = "upperLetter", text = "ANEXO %1", alignment = "center", start = 1, suffix = "nothing" },
        },
    },

    -- ========================================================================
    -- Section Configuration
    -- ========================================================================
    sections = {
        { id = "body", break_type = "nextPage", page_numbering = { format = "decimal", start = 1 } },
        { id = "pretextual", break_type = "nextPage", page_numbering = { format = "lowerRoman", start = 1 } },
        { id = "posttextual", break_type = "nextPage", page_numbering = { format = "decimal" } },
    },

    -- ========================================================================
    -- Document Settings
    -- ========================================================================
    settings = {
        default_tab_stop = 720,
        compatibility_mode = 15,
        language = default_language,  -- From config.lua
    },

    -- ========================================================================
    -- Theme Configuration
    -- ========================================================================
    theme = {
        major_font = "Arial",
        minor_font = "Times New Roman",
        color_scheme = "Office",
    },
}
