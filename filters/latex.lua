---ABNT LaTeX filter for SpecDown.
---Converts semantic elements to ABNT-specific LaTeX commands.
---
---Features:
---  - Converts RawBlock("specdown", "page-break") to LaTeX \clearpage
---  - Converts RawBlock("specdown", "vertical-space:NNNN") to LaTeX \vspace
---  - Converts semantic Div classes to abntex2 environments/commands:
---    - cover-* -> abntex2 metadata (handled by postprocessor, passed through here)
---    - dedication -> \begin{dedicatoria}...\end{dedicatoria}
---    - epigraph -> \begin{epigrafe}...\end{epigrafe}
---    - unnumbered-heading -> \chapter*{}
---
---@module models.abnt.filters.latex
---@author SpecDown Team
---@license MIT

local M = {}

-- ============================================================================
-- LaTeX Generation
-- ============================================================================

---Generate page break LaTeX.
---@param break_type string|nil Break type: "next" (default), "odd", "even"
---@return string LaTeX command
local function latex_page_break(break_type)
    break_type = break_type or "next"

    if break_type == "odd" then
        return "\\cleardoublepage"
    elseif break_type == "even" then
        -- LaTeX doesn't have a direct evenPage break, use clearpage
        return "\\clearpage"
    else
        return "\\clearpage"
    end
end

---Generate vertical space LaTeX.
---@param twips number Spacing in twips
---@return string LaTeX command
local function latex_vertical_space(twips)
    -- Convert twips to points (1 twip = 1/20 point)
    local points = math.floor(twips / 20)
    return string.format("\\vspace{%dpt}", points)
end

---Escape LaTeX special characters.
---@param text string Text to escape
---@return string Escaped text
local function latex_escape(text)
    if not text then return "" end
    -- Order matters: escape backslash first
    text = text:gsub("\\", "\\textbackslash{}")
    text = text:gsub("&", "\\&")
    text = text:gsub("%%", "\\%%")
    text = text:gsub("%$", "\\$")
    text = text:gsub("#", "\\#")
    text = text:gsub("_", "\\_")
    text = text:gsub("{", "\\{")
    text = text:gsub("}", "\\}")
    text = text:gsub("~", "\\textasciitilde{}")
    text = text:gsub("%^", "\\textasciicircum{}")
    return text
end

---UTF-8 aware uppercase function.
---Lua's string.upper() doesn't handle UTF-8, so we need to handle accented chars.
---@param text string Text to uppercase
---@return string Uppercased text
local function utf8_upper(text)
    if not text then return "" end
    -- First apply standard uppercase
    local result = text:upper()
    -- Then fix common Portuguese/Spanish accented lowercase characters
    result = result:gsub("á", "Á")
    result = result:gsub("à", "À")
    result = result:gsub("ã", "Ã")
    result = result:gsub("â", "Â")
    result = result:gsub("é", "É")
    result = result:gsub("ê", "Ê")
    result = result:gsub("í", "Í")
    result = result:gsub("ó", "Ó")
    result = result:gsub("ô", "Ô")
    result = result:gsub("õ", "Õ")
    result = result:gsub("ú", "Ú")
    result = result:gsub("ü", "Ü")
    result = result:gsub("ç", "Ç")
    result = result:gsub("ñ", "Ñ")
    return result
end

-- ============================================================================
-- Semantic Class Mapping for LaTeX
-- ============================================================================

---Map of semantic class names to LaTeX handling.
---For abntex2, many cover/titlepage elements are handled via metadata commands,
---not inline content. These are marked as "metadata" type.
local SEMANTIC_CLASS_MAP = {
    -- Cover page elements (passed to postprocessor via metadata)
    ["cover-institution"] = { type = "metadata", key = "institution", uppercase = true },
    ["cover-department"]  = { type = "metadata", key = "department", uppercase = false },
    ["cover-title"]       = { type = "metadata", key = "title", uppercase = true },
    ["cover-subtitle"]    = { type = "metadata", key = "subtitle", uppercase = false },
    ["cover-author"]      = { type = "metadata", key = "author", uppercase = false },
    ["cover-nature"]      = { type = "metadata", key = "preambulo", uppercase = false },
    ["cover-advisor"]     = { type = "metadata", key = "advisor", uppercase = false },
    ["cover-location"]    = { type = "metadata", key = "location", uppercase = false },
    ["cover-year"]        = { type = "metadata", key = "date", uppercase = false },

    -- Title page elements (same as cover in abntex2)
    ["titlepage-author"]   = { type = "metadata", key = "author", uppercase = false },
    ["titlepage-title"]    = { type = "metadata", key = "title", uppercase = true },
    ["titlepage-subtitle"] = { type = "metadata", key = "subtitle", uppercase = false },
    ["titlepage-nature"]   = { type = "metadata", key = "preambulo", uppercase = false },
    ["titlepage-advisor"]  = { type = "metadata", key = "advisor", uppercase = false },
    ["titlepage-location"] = { type = "metadata", key = "location", uppercase = false },
    ["titlepage-year"]     = { type = "metadata", key = "date", uppercase = false },

    -- Pre-textual elements (converted to LaTeX environments)
    ["dedication"]         = { type = "environment", env = "dedicatoria", uppercase = false },
    ["epigraph"]           = { type = "environment", env = "epigrafe", uppercase = false },

    -- Container classes (unwrap content for LaTeX - positioning handled by abntex2)
    ["bottom-aligned"]     = { type = "unwrap", uppercase = false },

    -- Structural elements
    ["unnumbered-heading"] = { type = "command", cmd = "chapter*", uppercase = false },
    ["toc-heading"]        = { type = "skip", uppercase = false },  -- TOC is auto-generated
}

-- ============================================================================
-- Helper Functions
-- ============================================================================

---Get content from an element, handling both Pandoc objects (.content) and raw tables (.c).
---@param elem table Pandoc element or raw JSON table
---@return table|nil content The content array or nil
local function get_content(elem)
    if elem.content then
        return elem.content
    elseif elem.c then
        if type(elem.c) == "table" then
            local first = elem.c[1]
            if type(first) == "table" and type(first[1]) == "string" and type(first[2]) == "table" then
                return elem.c[2]
            else
                return elem.c
            end
        end
    end
    return nil
end

---Extract plain text from inline elements.
---@param inlines table Array of inline elements
---@return string Extracted text
local function extract_text(inlines)
    local parts = {}
    for _, inline in ipairs(inlines) do
        if inline.t == "Str" then
            table.insert(parts, inline.text)
        elseif inline.t == "Space" then
            table.insert(parts, " ")
        elseif inline.t == "SoftBreak" then
            table.insert(parts, " ")
        elseif inline.t == "LineBreak" then
            table.insert(parts, "\n")
        else
            local nested = get_content(inline)
            if nested then
                table.insert(parts, extract_text(nested))
            end
        end
    end
    return table.concat(parts)
end

---Extract text from a Div element (recursive for nested Divs).
---@param div table Pandoc Div element
---@return string Extracted text
local function extract_div_text(div)
    local parts = {}
    local content = get_content(div)
    if not content then return "" end

    for _, block in ipairs(content) do
        if block.t == "Para" or block.t == "Plain" then
            local block_content = get_content(block)
            if block_content then
                table.insert(parts, extract_text(block_content))
            end
        elseif block.t == "BlockQuote" then
            -- Use get_content to handle both .content and .c formats
            local bq_content = get_content(block)
            if bq_content then
                for _, inner in ipairs(bq_content) do
                    if inner.t == "Para" or inner.t == "Plain" then
                        local inner_content = get_content(inner)
                        if inner_content then
                            table.insert(parts, extract_text(inner_content))
                        end
                    elseif inner.t == "Div" then
                        -- Handle nested Divs inside BlockQuote
                        local nested = extract_div_text(inner)
                        if nested and nested ~= "" then
                            table.insert(parts, nested)
                        end
                    end
                end
            end
        elseif block.t == "Div" then
            -- Recursively extract text from nested Divs
            local nested_text = extract_div_text(block)
            if nested_text and nested_text ~= "" then
                table.insert(parts, nested_text)
            end
        end
    end
    return table.concat(parts, "\n")
end

---Get classes from a Pandoc element.
---@param elem table Pandoc element
---@return table Array of class names
local function get_classes(elem)
    if elem.classes then
        return elem.classes
    elseif elem.attr and elem.attr.classes then
        return elem.attr.classes
    elseif elem.c and type(elem.c) == "table" and type(elem.c[1]) == "table" then
        return elem.c[1][2] or {}
    end
    return {}
end

-- ============================================================================
-- Sourcepos Span Stripping (removes data-pos tracking spans)
-- ============================================================================

---Check if a Span only has data-pos attribute (tracking span from sourcepos)
---These spans cause word-by-word bracing in LaTeX output and must be stripped.
---@param elem table Pandoc Span element
---@return boolean True if this is a tracking span that should be unwrapped
local function is_tracking_span(elem)
    if not elem or elem.t ~= "Span" then return false end

    local id = elem.identifier or ""
    local classes = elem.classes or {}
    local attrs = elem.attributes or {}

    -- Empty id, no classes
    if id ~= "" then return false end
    if #classes > 0 then return false end

    -- Check attributes - should only have data-pos
    local attr_count = 0
    local has_data_pos = false
    for k, _ in pairs(attrs) do
        attr_count = attr_count + 1
        if k == "data-pos" then
            has_data_pos = true
        end
    end

    return has_data_pos and attr_count == 1
end

-- ============================================================================
-- Native Pandoc Filter Functions
-- ============================================================================

---Process Span elements.
---Unwraps tracking spans from sourcepos extension to prevent word-by-word bracing.
---@param span table Pandoc Span
---@return table|nil Content if tracking span, nil otherwise
function Span(span)
    if is_tracking_span(span) then
        -- Return the content directly, unwrapping the tracking span
        return span.content
    end
    return nil  -- Keep original span
end

---Process RawBlock elements.
---Converts specdown markers to LaTeX.
---@param block table Pandoc RawBlock
---@return table|nil Modified element or nil
function RawBlock(block)
    if block.format ~= "specdown" then
        return nil
    end

    local text = block.text

    -- Page break: page-break[:type]
    if text:match("^page%-break") then
        local break_type = text:match("^page%-break:(%w+)$") or "next"
        local latex = latex_page_break(break_type)
        return pandoc.RawBlock("latex", latex)
    end

    -- Vertical space: vertical-space:TWIPS
    if text:match("^vertical%-space:") then
        local twips = tonumber(text:match("^vertical%-space:(%d+)$"))
        if twips then
            local latex = latex_vertical_space(twips)
            return pandoc.RawBlock("latex", latex)
        end
    end

    -- Pass through other specdown markers as comments
    return pandoc.RawBlock("latex", string.format("%% specdown: %s", text))
end

---Process Div elements.
---Converts semantic classes to LaTeX environments/commands.
---@param div table Pandoc Div
---@return table|nil Modified element or nil
function Div(div)
    local classes = get_classes(div)

    for _, class in ipairs(classes) do
        local mapping = SEMANTIC_CLASS_MAP[class]
        if mapping then
            local text = extract_div_text(div)

            if mapping.uppercase and text then
                text = text:upper()
            end

            if mapping.type == "environment" then
                -- Wrap in LaTeX environment
                local latex = string.format(
                    "\\begin{%s}\n%s\n\\end{%s}",
                    mapping.env,
                    text,
                    mapping.env
                )
                return pandoc.RawBlock("latex", latex)

            elseif mapping.type == "command" then
                -- Single command (like \chapter*{})
                local latex = string.format("\\%s{%s}", mapping.cmd, latex_escape(text))
                return pandoc.RawBlock("latex", latex)

            elseif mapping.type == "metadata" then
                -- Metadata elements: emit as LaTeX comment for postprocessor
                -- The postprocessor will extract these and build metadata commands
                local latex = string.format(
                    "%% specdown:metadata:%s:%s",
                    mapping.key,
                    text:gsub("\n", " ")
                )
                return pandoc.RawBlock("latex", latex)

            elseif mapping.type == "skip" then
                -- Skip this element entirely (e.g., TOC placeholder)
                return pandoc.RawBlock("latex", "% TOC will be auto-generated")

            elseif mapping.type == "unwrap" then
                -- Unwrap the Div and return its content directly
                -- This allows nested Divs (like dedication inside bottom-aligned) to be processed
                return div.content
            end
        end
    end

    return nil
end

---Process Header elements.
---Strips level 1 headers (spec titles) since abntex2 uses \titulo{} for the title.
---Level 2+ headers become LaTeX sections/chapters.
---@param header table Pandoc Header
---@return table|nil Modified element or nil
function Header(header)
    -- Level 1 headers are spec titles - strip them from content
    -- The title is already in abntex2 metadata via \titulo{}
    if header.level == 1 then
        return {}  -- Remove the H1 header entirely
    end
    return nil  -- Keep other headers unchanged
end

---Process Link elements.
---Replace .ext placeholder with .tex for cross-document links.
---@param link table Pandoc Link
---@return table|nil Modified element or nil
function Link(link)
    if link.target then
        local new_target = link.target:gsub("%.ext#", ".tex#"):gsub("%.ext$", ".tex")
        if new_target ~= link.target then
            link.target = new_target
            return link
        end
    end
    return nil
end

-- ============================================================================
-- Module Interface for Direct Apply (non-Pandoc filter mode)
-- ============================================================================

---Apply filter to a document directly.
---Used when running inside SpecDown (not as a native Pandoc filter).
---@param doc table Pandoc document
---@param config table Configuration
---@param log table Logger
---@return table Modified document
function M.apply(doc, config, log)
    log = log or { debug = function() end }
    log.debug("[ABNT-LATEX-FILTER] Applying LaTeX filter")

    -- Use Pandoc's walk mechanism if available
    if pandoc and pandoc.walk_block then
        local filter = {
            Span = Span,
            RawBlock = RawBlock,
            Div = Div,
            Header = Header,
            Link = Link,
        }
        return doc:walk(filter)
    end

    -- Fallback: return document unchanged
    log.debug("[ABNT-LATEX-FILTER] pandoc.walk_block not available, returning unchanged")
    return doc
end

return M
