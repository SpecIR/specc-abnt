---ABNT LaTeX Post-processor for SpecDown.
---Transforms Pandoc's default LaTeX output to abntex2-compliant document.
---
---This includes:
---  - Document class replacement (article/report -> abntex2)
---  - Required package injection
---  - Metadata command mapping (title -> titulo, author -> autor, etc.)
---  - Pre-textual/textual/post-textual structure injection
---  - Table formatting for IBGE three-line style
---
---@module abnt.postprocessors.latex
---@author SpecDown Team
---@license MIT

local M = {}

-- ============================================================================
-- abntex2 Document Structure
-- ============================================================================

-- abntex2 document class with ABNT-compliant options
local ABNTEX2_DOCUMENTCLASS = [[
\documentclass[
    12pt,
    openright,
    twoside,
    a4paper,
    chapter=TITLE,
    section=TITLE,
    sumario=tradicional
]{abntex2}
]]

-- Required packages for abntex2 documents
local ABNTEX2_PACKAGES = [[
% Encoding
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{lmodern}

% Language (Brazilian Portuguese)
\usepackage[brazil]{babel}

% Graphics and colors
\usepackage{graphicx}
\usepackage{color}
\usepackage{xcolor}

% Typography
\usepackage{microtype}
\usepackage{indentfirst}

% Mathematics
\usepackage{amsmath}
\usepackage{amssymb}

% Tables (IBGE three-line style)
\usepackage{longtable}
\usepackage{booktabs}
\usepackage{multirow}
\usepackage{array}

% Code listings (quadros)
\usepackage{listings}

% References and links
\usepackage{hyperref}
\usepackage{bookmark}

% Bibliography (ABNT style - author-date)
\usepackage[brazilian,hyperpageref]{backref}
\usepackage[alf]{abntex2cite}

% Float captions
\usepackage{caption}
\captionsetup{justification=centering,labelsep=endash}

]]

-- ============================================================================
-- Pattern Definitions
-- ============================================================================

-- Pattern to match Pandoc's default documentclass
local DOCUMENTCLASS_PATTERN = "\\documentclass%[?[^%]]*%]?{[^}]+}"

-- Pattern to extract title
local TITLE_PATTERN = "\\title{([^}]*)}"

-- Pattern to extract author
local AUTHOR_PATTERN = "\\author{([^}]*)}"

-- Pattern to extract date
local DATE_PATTERN = "\\date{([^}]*)}"

-- Pattern to find \begin{document}
local BEGIN_DOCUMENT_PATTERN = "\\begin{document}"

-- Pattern to find \end{document}
local END_DOCUMENT_PATTERN = "\\end{document}"

-- Pattern to find \maketitle
local MAKETITLE_PATTERN = "\\maketitle"

-- Pattern to find \tableofcontents
local TOC_PATTERN = "\\tableofcontents"

-- ============================================================================
-- Metadata Extraction
-- ============================================================================

---Extract metadata from specdown comments in LaTeX content.
---Parses lines like: % specdown:metadata:key:value
---@param content string LaTeX content
---@return table metadata Map of key → value
local function extract_metadata_from_comments(content)
    local metadata = {}
    for key, value in content:gmatch("%% specdown:metadata:([^:]+):([^\n]+)") do
        -- First occurrence wins (cover page values take precedence)
        if not metadata[key] then
            metadata[key] = value:gsub("^%s+", ""):gsub("%s+$", "")  -- trim
        end
    end
    return metadata
end

---Extract metadata from Pandoc-generated LaTeX.
---Combines specdown comment metadata with standard Pandoc commands.
---@param content string LaTeX content
---@return table metadata Extracted metadata
local function extract_metadata(content)
    local metadata = {}

    -- 1. Extract from specdown comments (from filter) - primary source
    local comment_meta = extract_metadata_from_comments(content)
    for k, v in pairs(comment_meta) do
        metadata[k] = v
    end

    -- 2. Extract from Pandoc's standard commands (fallback)
    local title = content:match(TITLE_PATTERN)
    if title and title ~= "" and not metadata.title then
        metadata.title = title
    end

    local author = content:match(AUTHOR_PATTERN)
    if author and author ~= "" and not metadata.author then
        metadata.author = author
    end

    local date = content:match(DATE_PATTERN)
    if date and date ~= "" and not metadata.date then
        metadata.date = date
    end

    return metadata
end

-- ============================================================================
-- LaTeX Transformations
-- ============================================================================

---Replace Pandoc's documentclass with abntex2.
---@param content string LaTeX content
---@return string Modified content
local function replace_documentclass(content)
    return content:gsub(DOCUMENTCLASS_PATTERN, ABNTEX2_DOCUMENTCLASS, 1)
end

---Inject required packages after documentclass.
---@param content string LaTeX content
---@return string Modified content
local function inject_packages(content)
    -- Find the end of documentclass and inject packages
    local doc_class_end = content:find("}", content:find("\\documentclass"))
    if doc_class_end then
        local before = content:sub(1, doc_class_end)
        local after = content:sub(doc_class_end + 1)
        return before .. "\n\n" .. ABNTEX2_PACKAGES .. after
    end
    return content
end

---Build abntex2 metadata commands from extracted metadata.
---Handles metadata from both specdown comments and config.
---@param metadata table Extracted metadata (from comments and Pandoc)
---@param config table|nil Configuration with additional metadata
---@return string LaTeX commands for metadata
local function build_metadata_commands(metadata, config)
    config = config or {}
    local commands = {}

    -- Title (titulo) - from metadata or config
    local title = metadata.title or config.title
    if title and title ~= "" then
        table.insert(commands, string.format("\\titulo{%s}", title))
    end

    -- Author (autor) - from metadata or config
    local author = metadata.author or config.author
    if author and author ~= "" then
        table.insert(commands, string.format("\\autor{%s}", author))
    end

    -- Institution (instituicao) - from metadata or config
    local institution = metadata.institution or config.institution
    if institution and institution ~= "" then
        table.insert(commands, string.format("\\instituicao{%s}", institution))
    end

    -- Advisor (orientador) - from metadata or config
    local advisor = metadata.advisor or config.advisor
    if advisor and advisor ~= "" then
        -- Strip "Orientador: " prefix if present
        advisor = advisor:gsub("^Orientador:%s*", "")
        table.insert(commands, string.format("\\orientador{%s}", advisor))
    end

    -- Co-advisor (coorientador) - from config only
    if config.coadvisor then
        table.insert(commands, string.format("\\coorientador{%s}", config.coadvisor))
    end

    -- Location (local) - from metadata or config
    local location = metadata.location or config.location
    if location and location ~= "" then
        table.insert(commands, string.format("\\local{%s}", location))
    end

    -- Date/Year (data) - from metadata or config
    local date = metadata.date or config.date
    if date and date ~= "" then
        table.insert(commands, string.format("\\data{%s}", date))
    else
        table.insert(commands, "\\data{\\the\\year}")
    end

    -- Preambulo (nature of work) - from metadata or config
    local preambulo = metadata.preambulo or config.preamble_text
    if preambulo and preambulo ~= "" then
        table.insert(commands, string.format("\\preambulo{%s}", preambulo))
    end

    return table.concat(commands, "\n")
end

---Inject metadata commands before \begin{document}.
---@param content string LaTeX content
---@param metadata_commands string Generated metadata commands
---@return string Modified content
local function inject_metadata(content, metadata_commands)
    local begin_doc_pos = content:find(BEGIN_DOCUMENT_PATTERN)
    if begin_doc_pos then
        local before = content:sub(1, begin_doc_pos - 1)
        local after = content:sub(begin_doc_pos)
        return before .. "\n% ABNT Metadata\n" .. metadata_commands .. "\n\n" .. after
    end
    return content
end

---Replace \maketitle with abntex2 cover and title page commands.
---@param content string LaTeX content
---@return string Modified content
local function replace_maketitle(content)
    -- Replace \maketitle with abntex2 pre-textual structure
    local pretextual_commands = [[
% Pre-textual elements
\pretextual

% Cover page
\imprimircapa

% Title page
\imprimirfolhaderosto*

]]

    local modified = content:gsub(MAKETITLE_PATTERN, pretextual_commands, 1)
    return modified
end

---Inject pre-textual structure after \begin{document}.
---Called when \maketitle is not present (Pandoc didn't generate title metadata).
---@param content string LaTeX content
---@return string Modified content
local function inject_pretextual_structure(content)
    -- Check if pretextual structure already exists (from replace_maketitle)
    if content:find("\\pretextual") then
        return content
    end

    -- Find \begin{document}
    local begin_doc_pos = content:find("\\begin{document}")
    if not begin_doc_pos then
        return content
    end

    -- Find end of \begin{document} line
    local line_end = content:find("\n", begin_doc_pos) or begin_doc_pos + 16

    local pretextual = [[

% Pre-textual elements
\pretextual

% Cover page
\imprimircapa

% Title page
\imprimirfolhaderosto*

]]

    local before = content:sub(1, line_end)
    local after = content:sub(line_end + 1)

    return before .. pretextual .. after
end

---Inject TOC, LOF, LOT before main content.
---These come after pre-textual elements (abstracts) but before textual content.
---@param content string LaTeX content
---@return string Modified content
local function inject_lists(content)
    -- Find a good insertion point: after last abstract/resumo, before first section
    -- Look for \chapter*{RESUMO} or \chapter*{ABSTRACT} - TOC comes after these

    -- Find the last pre-textual chapter* (RESUMO, ABSTRACT, AGRADECIMENTOS, etc.)
    local last_pretextual_end = 0
    for match_start in content:gmatch("()\\chapter%*{[^}]+}") do
        local next_content = content:sub(match_start, match_start + 200)
        -- Check if this is a pre-textual chapter (RESUMO, ABSTRACT, AGRADECIMENTOS)
        if next_content:match("\\chapter%*{RESUMO}") or
           next_content:match("\\chapter%*{ABSTRACT}") or
           next_content:match("\\chapter%*{AGRADECIMENTOS}") then
            -- Find the end of this chapter's content (next \chapter or \section)
            local chapter_end = content:find("\\chapter", match_start + 10) or
                               content:find("\\section", match_start + 10) or
                               content:find("\\hypertarget", match_start + 100)
            if chapter_end and chapter_end > last_pretextual_end then
                last_pretextual_end = chapter_end
            end
        end
    end

    -- If we found pre-textual content, insert TOC/LOF/LOT before the main content
    if last_pretextual_end > 0 then
        local before = content:sub(1, last_pretextual_end - 1)
        local after = content:sub(last_pretextual_end)

        local lists = [[

% Table of Contents
\pdfbookmark[0]{\contentsname}{toc}
\tableofcontents*
\cleardoublepage

% List of Figures
\pdfbookmark[0]{\listfigurename}{lof}
\listoffigures*
\cleardoublepage

% List of Tables
\pdfbookmark[0]{\listtablename}{lot}
\listoftables*
\cleardoublepage

]]
        return before .. lists .. after
    end

    -- Fallback: insert before \textual if it exists
    local textual_pos = content:find("\\textual")
    if textual_pos then
        local before = content:sub(1, textual_pos - 1)
        local after = content:sub(textual_pos)

        local lists = [[
% Table of Contents
\pdfbookmark[0]{\contentsname}{toc}
\tableofcontents*
\cleardoublepage

% List of Figures
\pdfbookmark[0]{\listfigurename}{lof}
\listoffigures*
\cleardoublepage

% List of Tables
\pdfbookmark[0]{\listtablename}{lot}
\listoftables*
\cleardoublepage

]]
        return before .. lists .. after
    end

    return content
end

---Inject \textual marker before main content.
---Finds the first numbered section/chapter and injects \textual before it.
---@param content string LaTeX content
---@return string Modified content
local function inject_textual_marker(content)
    -- Check if \textual already exists
    if content:find("\\textual") then
        return content
    end

    -- Strategy: Find the first numbered section/chapter (not starred like \chapter*)
    -- The main content typically starts with Introduction (\section{Introdução})
    -- or numbered chapters (\chapter{...} without *)

    -- Patterns to find first main content section
    -- Order matters - try most specific first
    local patterns = {
        -- Hypertarget for introduction (common Pandoc output)
        "(\\hypertarget{introdu[^}]*})",
        -- First numbered section
        "(\\section{[^}]+})",
        -- First numbered chapter (not starred)
        "(\\chapter{[^*][^}]*})",
    }

    for _, pattern in ipairs(patterns) do
        local match_start, match_end = content:find(pattern)
        if match_start then
            -- Check it's not inside pretextual (before \imprimirfolhaderosto)
            local pretextual_end = content:find("\\imprimirfolhaderosto")
            if not pretextual_end or match_start > pretextual_end then
                local before = content:sub(1, match_start - 1)
                local after = content:sub(match_start)
                return before .. "\n% Main content\n\\textual\n\n" .. after
            end
        end
    end

    -- Fallback: Look for \tableofcontents and inject \textual after it
    local toc_pos = content:find(TOC_PATTERN)
    if toc_pos then
        local toc_end = toc_pos + #"\\tableofcontents"
        local before = content:sub(1, toc_end)
        local after = content:sub(toc_end + 1)
        return before .. "\n\n% Main content\n\\textual\n" .. after
    end

    -- Last resort: inject after \imprimirfolhaderosto
    local titlepage_pos = content:find("\\imprimirfolhaderosto")
    if titlepage_pos then
        local line_end = content:find("\n", titlepage_pos) or titlepage_pos + 30
        local before = content:sub(1, line_end)
        local after = content:sub(line_end + 1)
        return before .. "\n\n% Main content\n\\textual\n" .. after
    end

    return content
end

---Inject post-textual marker and bibliography before \end{document}.
---@param content string LaTeX content
---@param config table|nil Configuration with bibliography settings
---@return string Modified content
local function inject_posttextual(content, config)
    config = config or {}
    local end_doc_pos = content:find(END_DOCUMENT_PATTERN)

    if end_doc_pos then
        local before = content:sub(1, end_doc_pos - 1)
        local end_doc = content:sub(end_doc_pos)

        -- Build post-textual section
        local posttextual = "\n% Post-textual elements\n\\postextual\n"

        -- Add bibliography if configured
        local bib_file = config.bibliography
        if bib_file then
            -- Remove extension if present
            bib_file = bib_file:gsub("%.bib$", "")
            posttextual = posttextual .. string.format("\n\\bibliography{%s}\n", bib_file)
        end

        return before .. posttextual .. "\n" .. end_doc
    end

    return content
end

---Transform tables to IBGE three-line style using booktabs.
---Replaces \hline with \toprule, \midrule, \bottomrule.
---@param content string LaTeX content
---@return string Modified content
local function transform_tables(content)
    local modified = content

    -- Pattern to find tabular environments
    -- This is a simplified transformation - may need refinement

    -- Replace first \hline after \begin{tabular} with \toprule
    modified = modified:gsub(
        "(\\begin{tabular}[^\n]*\n)\\hline",
        "%1\\toprule"
    )

    -- Replace \hline before \end{tabular} with \bottomrule
    modified = modified:gsub(
        "\\hline(\n\\end{tabular})",
        "\\bottomrule%1"
    )

    -- Replace remaining \hline between header and data with \midrule
    -- This is approximate - proper handling would require parsing table structure
    -- For now, replace second \hline occurrence in tables with \midrule
    modified = modified:gsub(
        "(\\toprule[^\n]*\n[^\n]*\n)\\hline",
        "%1\\midrule"
    )

    return modified
end

---Remove specdown metadata comments from final output.
---These comments were used for metadata extraction and are no longer needed.
---@param content string LaTeX content
---@return string Modified content
local function remove_metadata_comments(content)
    return content:gsub("%% specdown:metadata:[^\n]+\n?", "")
end

---Remove H1 spec title that leaks into content after title page.
---The spec title appears as plain text after \imprimirfolhaderosto* with a hypertarget.
---Pattern: \leavevmode\vadjust pre{\hypertarget{SPECID}{}}%\nTitle Text
---@param content string LaTeX content
---@return string Modified content
local function remove_spec_title(content)
    -- Pattern matches the hypertarget line followed by a single line of title text
    -- The hypertarget is for the document root (e.g., "monografia")
    local modified = content:gsub(
        "\\leavevmode\\vadjust pre{\\hypertarget{[^}]+}{}}%%\n[^\n]+\n",
        ""
    )
    return modified
end

---Remove Pandoc's default metadata commands (they're replaced with abntex2 equivalents).
---@param content string LaTeX content
---@return string Modified content
local function remove_pandoc_metadata(content)
    local modified = content

    -- Remove \title{...}
    modified = modified:gsub("\\title{[^}]*}\n?", "")

    -- Remove \author{...}
    modified = modified:gsub("\\author{[^}]*}\n?", "")

    -- Remove \date{...}
    modified = modified:gsub("\\date{[^}]*}\n?", "")

    return modified
end

-- ============================================================================
-- Main Processing
-- ============================================================================

---Process LaTeX content and transform to abntex2 format.
---@param content string Original Pandoc LaTeX output
---@param config table|nil Configuration
---@param log table Logger instance
---@return string Modified LaTeX content
function M.process(content, config, log)
    config = config or {}
    log.info('[ABNT-LATEX] Transforming to abntex2 format')

    -- Extract metadata before modifications
    local metadata = extract_metadata(content)
    log.debug('[ABNT-LATEX] Extracted metadata: title=%s, author=%s',
        metadata.title or "(none)", metadata.author or "(none)")

    -- Apply transformations in order
    local modified = content

    -- 1. Replace documentclass with abntex2
    log.debug('[ABNT-LATEX] Replacing documentclass with abntex2')
    modified = replace_documentclass(modified)

    -- 2. Inject required packages
    log.debug('[ABNT-LATEX] Injecting required packages')
    modified = inject_packages(modified)

    -- 3. Remove Pandoc's metadata commands
    log.debug('[ABNT-LATEX] Removing Pandoc metadata commands')
    modified = remove_pandoc_metadata(modified)

    -- 4. Build and inject abntex2 metadata
    local metadata_commands = build_metadata_commands(metadata, config)
    log.debug('[ABNT-LATEX] Injecting abntex2 metadata commands')
    modified = inject_metadata(modified, metadata_commands)

    -- 5. Replace \maketitle with abntex2 cover/title page
    log.debug('[ABNT-LATEX] Replacing maketitle with abntex2 pre-textual')
    modified = replace_maketitle(modified)

    -- 6. Inject pre-textual structure if not already present
    -- (replace_maketitle only works if Pandoc generated \maketitle)
    log.debug('[ABNT-LATEX] Ensuring pre-textual structure exists')
    modified = inject_pretextual_structure(modified)

    -- 6b. Remove H1 spec title that leaks into content
    log.debug('[ABNT-LATEX] Removing spec title leak')
    modified = remove_spec_title(modified)

    -- 7. Inject \textual marker before main content
    log.debug('[ABNT-LATEX] Injecting textual marker')
    modified = inject_textual_marker(modified)

    -- 7b. Inject TOC, LOF, LOT between pre-textual and textual
    log.debug('[ABNT-LATEX] Injecting TOC, LOF, LOT')
    modified = inject_lists(modified)

    -- 8. Inject post-textual and bibliography
    log.debug('[ABNT-LATEX] Injecting post-textual section')
    modified = inject_posttextual(modified, config)

    -- 9. Transform tables to IBGE style
    log.debug('[ABNT-LATEX] Transforming tables to IBGE style')
    modified = transform_tables(modified)

    -- 10. Remove specdown metadata comments (no longer needed)
    log.debug('[ABNT-LATEX] Removing metadata comments')
    modified = remove_metadata_comments(modified)

    log.info('[ABNT-LATEX] Transformation complete')
    return modified
end

-- ============================================================================
-- File I/O Utilities
-- ============================================================================

---Read file content.
---@param path string Path to file
---@return string|nil Content or nil if failed
local function read_file(path)
    local f = io.open(path, 'r')
    if not f then
        return nil
    end
    local content = f:read('*all')
    f:close()
    return content
end

---Write file content.
---@param path string Path to file
---@param content string Content to write
---@return boolean Success status
local function write_file(path, content)
    local f = io.open(path, 'w')
    if not f then
        return false
    end
    f:write(content)
    f:close()
    return true
end

-- ============================================================================
-- Writer Interface
-- ============================================================================

---Run the ABNT LaTeX postprocessor on a single file.
---@param path string Path to the LaTeX file
---@param config table Configuration
---@param log table Logger instance
---@return boolean Success status
function M.run(path, config, log)
    -- Read LaTeX content
    local content = read_file(path)
    if not content then
        log.warn('[ABNT-LATEX] Could not read LaTeX file: %s', path)
        return false
    end

    -- Process content
    local latex_config = config.latex or config
    local modified = M.process(content, latex_config, log)

    -- Write modified content
    local success = write_file(path, modified)
    if not success then
        log.warn('[ABNT-LATEX] Failed to write modified LaTeX: %s', path)
    end

    return success
end

---Finalize batch of LaTeX files.
---This is called by the emitter after all Pandoc processes complete.
---@param paths table Array of LaTeX file paths
---@param config table Configuration
---@param log table Logger instance
function M.finalize(paths, config, log)
    for _, path in ipairs(paths) do
        local ok, err = pcall(M.run, path, config, log)
        if not ok then
            log.warn("[ABNT-LATEX] Postprocess failed for %s: %s", path, tostring(err))
        end
    end
end

return M
