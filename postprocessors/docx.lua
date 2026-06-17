---ABNT OOXML Post-processor for SpecCompiler v2.
---Modifies DOCX files after Pandoc generation to apply ABNT-specific formatting.
---
---This includes:
---  - Table formatting (IBGE three-line style per ABNT NBR 14724:2011)
---  - Figure centering
---  - Code block styling
---  - Heading numbering
---
---@module abnt.ooxml.postprocess
---@author SpecCompiler Team
---@license MIT

local xml = require("infra.format.xml")
local table_formatter = require("infra.format.docx.table_formatter")
local heading_numberer = require("infra.format.docx.heading_numberer")
local bibliography_formatter = require("infra.format.docx.bibliography_formatter")
local header_builder = require("infra.format.docx.header_builder")
local section_manager = require("infra.format.docx.section_manager")

local M = {}

-- ============================================================================
-- Section Type Detection
-- ============================================================================

-- Textual styles: numbered main content sections
-- These sections use arabic numeral page numbering (1, 2, 3) starting at 1
local TEXTUAL_STYLES = {
    ["Heading1"] = true,
    ["Heading2"] = true,
    ["Heading3"] = true,
    ["Heading4"] = true,
    ["Heading5"] = true,
}

-- ============================================================================
-- ABNT Configuration for Shared Libraries
-- ============================================================================

-- Heading numbering definitions for heading_numberer
local ABNT_NUMBERING_DEFINITIONS = {
    {
        abstract_num_id = "0", nsid = "AB140001", tmpl = "AB140002",
        name = "HeadingNumbering", multi_level_type = "multilevel",
        num_id = "1",
        levels = {
            { ilvl = 0, start = "1", num_fmt = "decimal", lvl_text = "%1", suffix = "space", pstyle = "Heading1" },
            { ilvl = 1, start = "1", num_fmt = "decimal", lvl_text = "%1.%2", suffix = "space", pstyle = "Heading2" },
            { ilvl = 2, start = "1", num_fmt = "decimal", lvl_text = "%1.%2.%3", suffix = "space", pstyle = "Heading3" },
            { ilvl = 3, start = "1", num_fmt = "decimal", lvl_text = "%1.%2.%3.%4", suffix = "space", pstyle = "Heading4" },
            { ilvl = 4, start = "1", num_fmt = "decimal", lvl_text = "%1.%2.%3.%4.%5", suffix = "space", pstyle = "Heading5" },
        }
    },
}

local POST_TEXTUAL_NUMBERING = {
    Appendix = {
        title_patterns = { "^%s*APÊNDICE%s+([A-Z]+)", "^%s*APENDICE%s+([A-Z]+)" },
        num_id = "20",
    },
    Annex = {
        title_patterns = { "^%s*ANEXO%s+([A-Z]+)" },
        num_id = "21",
    },
}

local function post_textual_levels()
    return {
        { ilvl = 0, start = "1", num_fmt = "upperLetter", lvl_text = "", suffix = "nothing" },
        { ilvl = 1, start = "1", num_fmt = "decimal", lvl_text = "%1.%2", suffix = "space" },
        { ilvl = 2, start = "1", num_fmt = "decimal", lvl_text = "%1.%2.%3", suffix = "space" },
        { ilvl = 3, start = "1", num_fmt = "decimal", lvl_text = "%1.%2.%3.%4", suffix = "space" },
        { ilvl = 4, start = "1", num_fmt = "decimal", lvl_text = "%1.%2.%3.%4.%5", suffix = "space" },
    }
end

table.insert(ABNT_NUMBERING_DEFINITIONS, {
    abstract_num_id = "20",
    nsid = "AB170D20",
    tmpl = "AB170E20",
    name = "AppendixBodyNumbering",
    multi_level_type = "multilevel",
    num_id = POST_TEXTUAL_NUMBERING.Appendix.num_id,
    levels = post_textual_levels(),
})

table.insert(ABNT_NUMBERING_DEFINITIONS, {
    abstract_num_id = "21",
    nsid = "AB180D21",
    tmpl = "AB180E21",
    name = "AnnexBodyNumbering",
    multi_level_type = "multilevel",
    num_id = POST_TEXTUAL_NUMBERING.Annex.num_id,
    levels = post_textual_levels(),
})

-- Heading style to numbering level mapping
local ABNT_HEADING_MAP = {
    Heading1 = { ilvl = "0", numId = "1" },
    Heading2 = { ilvl = "1", numId = "1" },
    Heading3 = { ilvl = "2", numId = "1" },
    Heading4 = { ilvl = "3", numId = "1" },
    Heading5 = { ilvl = "4", numId = "1" },
}

-- IBGE three-line table config for table_formatter
local ABNT_TABLE_CONFIG = {
    borders = {
        top = { style = "single", sz = "8", space = "0", color = "000000" },
        bottom = { style = "single", sz = "8", space = "0", color = "000000" },
        left = { style = "nil" },
        right = { style = "nil" },
        insideH = { style = "nil" },
        insideV = { style = "nil" },
    },
    paragraph = { zero_indent = true },
    header = {
        remove_shading = true,
        cell_borders = {
            bottom = { style = "single", sz = "4", space = "0", color = "000000" }
        }
    }
}

-- Bibliography formatting config
local ABNT_BIB_CONFIG = {
    heading_text = nil,  -- ABNT doesn't inject heading (already in document)
    heading_style = nil,
    entry_style = "Reference",
    page_break_before = false,
    skip_styles = { "Heading", "UnnumberedHeading", "Caption", "Source" }
}

-- ABNT header parts configuration
local ABNT_HEADER_PARTS = {
    { file = "header1.xml", type = "header" },  -- Even pages with page number
    { file = "header2.xml", type = "header" },  -- Odd pages with page number
    { file = "header3.xml", type = "header" },  -- First page empty
    { file = "header4.xml", type = "header" },  -- Even pages empty (pre-textual)
}

-- ============================================================================
-- Table Formatting (IBGE Three-Line Style for Tables, Closed for Quadros)
-- ============================================================================

---Get paragraph style from a paragraph element.
---@param p table Paragraph node
---@return string|nil style Style name or nil
local function get_table_para_style(p)
    local pPr = xml.find_child(p, "w:pPr")
    if pPr then
        local pStyle = xml.find_child(pPr, "w:pStyle")
        if pStyle then
            return xml.get_attr(pStyle, "w:val")
        end
    end
    return nil
end

---Apply ABNT table formatting by detecting tables after caption paragraphs.
---Per ABNT NBR 14724:2011:
---  - Tables after TableCaption: IBGE three-line style (open borders)
---  - Other tables: Left unchanged (layout tables, equations)
---
---Detection strategy: Tables that immediately follow a TableCaption paragraph
---are data tables that need IBGE styling.
---@param content string document.xml content
---@param log table Logger instance
---@return string Modified content
function M.fix_tables(content, log)
    local doc = xml.parse(content)
    if not doc or not doc.root then
        log.warn('[ABNT-TABLES] Failed to parse document.xml')
        return content
    end

    -- Get document body
    local body = xml.find_child(doc.root, "w:body")
    if not body then
        log.warn('[ABNT-TABLES] Could not find w:body')
        return content
    end

    local kids = body.kids or {}
    local tabela_count = 0

    -- Track if previous element was TableCaption
    local prev_was_table_caption = false

    for _, node in ipairs(kids) do
        if node.type == "element" then
            local name = node.name
            if name == "w:p" or name == "p" then
                local style = get_table_para_style(node)
                prev_was_table_caption = (style == "TableCaption")
            elseif name == "w:tbl" or name == "tbl" then
                if prev_was_table_caption then
                    -- This is a data table - apply IBGE style via shared lib
                    table_formatter.format_table_node(node, ABNT_TABLE_CONFIG)
                    tabela_count = tabela_count + 1
                end
                prev_was_table_caption = false
            else
                prev_was_table_caption = false
            end
        end
    end

    if tabela_count > 0 then
        log.info('[ABNT-TABLES] Applied IBGE three-line style to %d tabela(s)', tabela_count)
    end

    return xml.serialize(doc)
end

-- ============================================================================
-- Listing/Quadro Formatting (Box Borders)
-- ============================================================================

---Create full box border for listing paragraphs.
---@return table XML node for w:pBdr
local function create_listing_borders()
    return xml.node("w:pBdr", {}, {
        xml.node("w:top", {["w:val"]="single", ["w:sz"]="8", ["w:space"]="1", ["w:color"]="000000"}),
        xml.node("w:left", {["w:val"]="single", ["w:sz"]="8", ["w:space"]="4", ["w:color"]="000000"}),
        xml.node("w:bottom", {["w:val"]="single", ["w:sz"]="8", ["w:space"]="1", ["w:color"]="000000"}),
        xml.node("w:right", {["w:val"]="single", ["w:sz"]="8", ["w:space"]="4", ["w:color"]="000000"})
    })
end

---Get paragraph style from a paragraph element.
---@param p table Paragraph element
---@return string|nil Style name
local function get_para_style(p)
    if not p or p.type ~= "element" then return nil end
    local pPr = xml.find_child(p, "w:pPr")
    if pPr then
        local pStyle = xml.find_child(pPr, "w:pStyle")
        if pStyle then
            return xml.get_attr(pStyle, "w:val")
        end
    end
    return nil
end

---Apply box borders to code listings (quadros).
---ABNT listings should have a frame around the code, unlike tables (IBGE three-line).
---Only applies to actual listing floats (Caption -> SourceCode -> Source pattern),
---not to regular code blocks used inline.
---@param content string document.xml content
---@param log table Logger instance
---@return string Modified content
function M.fix_listings(content, log)
    local doc = xml.parse(content)
    if not doc or not doc.root then
        log.warn('[ABNT-LISTINGS] Failed to parse document.xml')
        return content
    end

    local listing_count = 0
    local float_count = 0

    -- Get document body
    local body = xml.find_child(doc.root, "w:body")
    if not body then
        log.warn('[ABNT-LISTINGS] Could not find w:body')
        return content
    end

    local kids = body.kids or {}

    -- Build index of paragraphs for neighbor lookup
    local para_indices = {}
    for i, node in ipairs(kids) do
        if node.type == "element" and (node.name == "w:p" or node.name == "p") then
            table.insert(para_indices, {index = i, node = node})
        end
    end

    -- Find groups of consecutive SourceCode paragraphs bounded by Caption...Source
    -- This handles multi-paragraph code blocks in listing floats
    local pi = 1
    while pi <= #para_indices do
        local style = get_para_style(para_indices[pi].node)

        if style == "SourceCode" then
            -- Check if previous paragraph is Caption
            local prev_style = nil
            if pi > 1 then
                prev_style = get_para_style(para_indices[pi - 1].node)
            end

            if prev_style == "Caption" then
                -- Found start of a potential listing float
                -- Collect all consecutive SourceCode paragraphs
                local group_start = pi
                local group_end = pi

                while group_end < #para_indices do
                    local next_style = get_para_style(para_indices[group_end + 1].node)
                    if next_style == "SourceCode" then
                        group_end = group_end + 1
                    else
                        break
                    end
                end

                -- Check if followed by Source
                local after_style = nil
                if group_end < #para_indices then
                    after_style = get_para_style(para_indices[group_end + 1].node)
                end

                if after_style == "Source" then
                    -- This is a listing float - apply borders to all SourceCode paragraphs
                    float_count = float_count + 1
                    for i = group_start, group_end do
                        local p = para_indices[i].node
                        local pPr = xml.find_child(p, "w:pPr")
                        if pPr and not xml.find_child(pPr, "w:pBdr") then
                            xml.add_child(pPr, create_listing_borders())
                            listing_count = listing_count + 1
                        end
                    end
                end

                -- Skip past the group we just processed
                pi = group_end + 1
            else
                pi = pi + 1
            end
        else
            pi = pi + 1
        end
    end

    if listing_count > 0 then
        log.info('[ABNT-LISTINGS] Applied box borders to %d paragraph(s) in %d listing float(s)', listing_count, float_count)
    end

    return xml.serialize(doc)
end

-- ============================================================================
-- Figure Centering
-- ============================================================================

---Center-align paragraphs containing figures/drawings and add keepNext for orphan control.
---ABNT figure captions go BELOW the image, so the image paragraph needs keepNext
---to stay with its following caption (preventing orphans).
---@param content string document.xml content
---@param log table Logger instance
---@return string Modified content
function M.fix_figures(content, log)
    local doc = xml.parse(content)
    if not doc or not doc.root then
        log.warn('[ABNT-FIGURES] Failed to parse document.xml')
        return content
    end

    local figure_count = 0
    local keepnext_count = 0
    local paras = xml.find_by_name(doc.root, "w:p")

    for _, p in ipairs(paras) do
        local drawings = xml.find_by_name(p, "w:drawing")
        if #drawings > 0 then
            figure_count = figure_count + 1

            local pPr = xml.find_child(p, "w:pPr")
            if not pPr then
                pPr = xml.node("w:pPr")
                xml.insert_child(p, pPr, 1)
            end

            -- Center justify
            xml.replace_child(pPr, "w:jc", xml.node("w:jc", {["w:val"]="center"}))

            -- Add keepNext to keep figure with its caption (ABNT: caption below image)
            -- This prevents orphan figures where the image and caption get split across pages
            if not xml.find_child(pPr, "w:keepNext") then
                xml.add_child(pPr, xml.node("w:keepNext"))
                keepnext_count = keepnext_count + 1
            end
        end
    end

    if figure_count > 0 then
        log.debug('[ABNT-FIGURES] Centered %d figure(s), added keepNext to %d', figure_count, keepnext_count)
    end

    return xml.serialize(doc)
end

---Ask Word to paginate float blocks as a group when caption/image/source are adjacent.
---This is not absolute floating placement; it prevents stranded captions/sources and
---gives Word a better unit to keep on the declaration page when there is room.
---@param content string document.xml content
---@param log table Logger instance
---@return string Modified content
function M.keep_float_blocks_together(content, log)
    local doc = xml.parse(content)
    if not doc or not doc.root then
        log.warn('[ABNT-FLOATS] Failed to parse document.xml')
        return content
    end

    local body = xml.find_child(doc.root, "w:body")
    if not body then
        log.warn('[ABNT-FLOATS] Could not find w:body')
        return content
    end

    local caption_styles = {
        ImageCaption = true,
        Caption = true,
    }
    local source_styles = {
        Source = true,
        FigureSource = true,
    }

    local function is_para(node)
        return node and node.type == "element" and (node.name == "w:p" or node.name == "p")
    end

    local function has_drawing(p)
        return #xml.find_by_name(p, "w:drawing") > 0
    end

    local function add_keep_next(p)
        local pPr = xml.find_child(p, "w:pPr")
        if not pPr then
            pPr = xml.node("w:pPr")
            xml.insert_child(p, pPr, 1)
        end
        if not xml.find_child(pPr, "w:keepNext") then
            xml.add_child(pPr, xml.node("w:keepNext"))
            return true
        end
        return false
    end

    local count = 0
    local kids = body.kids or {}
    for i, node in ipairs(kids) do
        if is_para(node) then
            local style = get_para_style(node)
            local next_node = kids[i + 1]
            if caption_styles[style] and is_para(next_node) and has_drawing(next_node) then
                if add_keep_next(node) then count = count + 1 end
            elseif has_drawing(node) and is_para(next_node) and source_styles[get_para_style(next_node)] then
                if add_keep_next(node) then count = count + 1 end
            end
        end
    end

    if count > 0 then
        log.debug('[ABNT-FLOATS] Added keepNext to %d float paragraph(s)', count)
    end

    return xml.serialize(doc)
end

---Apply appendix/annex child heading numbering as A.1, A.1.1, etc.
---The visible APENDICE/ANEXO title remains manually rendered; internally it
---consumes hidden list level 0 so Word has the letter counter for descendants.
---@param content string document.xml content
---@param log table Logger instance
---@return string Modified content
function M.apply_appendix_annex_heading_numbering(content, log)
    local doc = xml.parse(content)
    if not doc or not doc.root then
        log.warn('[ABNT-APPENDIX] Failed to parse document.xml')
        return content
    end

    local body = xml.find_child(doc.root, "w:body")
    if not body then
        log.warn('[ABNT-APPENDIX] Could not find w:body')
        return content
    end

    local function paragraph_text(p)
        local parts = {}
        for _, t in ipairs(xml.find_by_name(p, "w:t")) do
            local kids = t.kids or {}
            for _, kid in ipairs(kids) do
                if kid.type == "text" and kid.value then
                    table.insert(parts, kid.value)
                end
            end
        end
        return table.concat(parts)
    end

    local function find_title_kind(text)
        for kind, config in pairs(POST_TEXTUAL_NUMBERING) do
            for _, pattern in ipairs(config.title_patterns) do
                if text:match(pattern) then
                    return kind
                end
            end
        end
        return nil
    end

    local function add_num_pr(p, ilvl, num_id)
        local pPr = xml.find_child(p, "w:pPr")
        if not pPr then
            pPr = xml.node("w:pPr")
            xml.insert_child(p, pPr, 1)
        end

        local existing = xml.find_child(pPr, "w:numPr")
        if existing then
            xml.remove_child(pPr, existing)
        end

        local numPr = xml.node("w:numPr", {}, {
            xml.node("w:ilvl", {["w:val"] = tostring(ilvl)}),
            xml.node("w:numId", {["w:val"] = tostring(num_id)}),
        })

        local insert_pos = 1
        for i, kid in ipairs(pPr.kids or {}) do
            if kid.name == "pStyle" or
               kid.name == "w:pStyle" or
               (kid.nsPrefix and kid.nsPrefix .. ":" .. kid.name == "w:pStyle") then
                insert_pos = i + 1
                break
            end
        end
        xml.insert_child(pPr, numPr, insert_pos)
    end

    local function set_para_style(p, style)
        local pPr = xml.find_child(p, "w:pPr")
        if not pPr then return end
        local pStyle = xml.find_child(pPr, "w:pStyle")
        if pStyle then
            xml.set_attr(pStyle, "w:val", style)
        end
    end

    local changed = 0
    local active_kind = nil
    local active_base_heading_level = nil

    for _, node in ipairs(body.kids or {}) do
        if node.type == "element" and (node.name == "w:p" or node.name == "p") then
            local style = get_para_style(node)
            local text = paragraph_text(node)
            local title_kind = find_title_kind(text)
            if title_kind then
                active_kind = title_kind
                active_base_heading_level = nil
                local config = POST_TEXTUAL_NUMBERING[active_kind]
                add_num_pr(node, 0, config.num_id)
                changed = changed + 1
            else
                local level = style and style:match("^Heading([1-5])$")
                if active_kind and level then
                    level = tonumber(level)
                    if not active_base_heading_level then
                        active_base_heading_level = level
                    end
                    local relative_level = math.max(1, math.min(4, level - active_base_heading_level + 1))
                    local config = POST_TEXTUAL_NUMBERING[active_kind]
                    set_para_style(node, "Heading" .. tostring(relative_level + 1))
                    add_num_pr(node, relative_level, config.num_id)
                    changed = changed + 1
                end
            end
        end
    end

    if changed > 0 then
        log.debug('[ABNT-APPENDIX] Applied appendix/annex numbering to %d paragraph(s)', changed)
    end

    return xml.serialize(doc)
end

-- ============================================================================
-- Code Block Styling
-- ============================================================================

---Fix code block styles (VerbatimChar, SourceCode).
---@param styles_content string styles.xml content
---@param log table Logger instance
---@return string Modified content
function M.fix_code_styles(styles_content, log)
    local doc = xml.parse(styles_content)
    if not doc or not doc.root then
        log.warn('[ABNT-STYLES] Failed to parse styles.xml')
        return styles_content
    end

    local styles_root = doc.root

    -- Helper to find style by styleId
    local function find_style_by_id(style_id)
        local all_styles = xml.find_children(styles_root, "w:style")
        for _, style in ipairs(all_styles) do
            if xml.get_attr(style, "w:styleId") == style_id then
                return style
            end
        end
        return nil
    end

    -- Check/add VerbatimChar style
    if not find_style_by_id("VerbatimChar") then
        local verbatim_style = xml.node("w:style", {
            ["w:type"] = "character",
            ["w:styleId"] = "VerbatimChar"
        }, {
            xml.node("w:name", {["w:val"] = "Verbatim Char"}),
            xml.node("w:basedOn", {["w:val"] = "DefaultParagraphFont"}),
            xml.node("w:rPr", {}, {
                xml.node("w:rFonts", {
                    ["w:ascii"] = "Courier New",
                    ["w:hAnsi"] = "Courier New"
                }),
                xml.node("w:sz", {["w:val"] = "18"}),
                xml.node("w:szCs", {["w:val"] = "18"})
            })
        })
        xml.add_child(styles_root, verbatim_style)
        log.debug('[ABNT-STYLES] Injected VerbatimChar style')
    end

    -- Check/add SourceCode style
    local source_code = find_style_by_id("SourceCode")
    if source_code then
        -- Style exists - ensure pPr has correct properties
        local pPr = xml.find_child(source_code, "w:pPr")
        if pPr then
            if not xml.find_child(pPr, "w:jc") then
                xml.add_child(pPr, xml.node("w:jc", {["w:val"] = "left"}))
            end
            local ind = xml.find_child(pPr, "w:ind")
            if ind then
                xml.set_attr(ind, "w:firstLine", "0")
            else
                xml.add_child(pPr, xml.node("w:ind", {["w:firstLine"] = "0"}))
            end
            log.debug('[ABNT-STYLES] Fixed SourceCode alignment')
        end
    else
        -- Style doesn't exist - create full definition
        local source_code_style = xml.node("w:style", {
            ["w:type"] = "paragraph",
            ["w:styleId"] = "SourceCode"
        }, {
            xml.node("w:name", {["w:val"] = "Source Code"}),
            xml.node("w:basedOn", {["w:val"] = "Normal"}),
            xml.node("w:pPr", {}, {
                xml.node("w:jc", {["w:val"] = "left"}),
                xml.node("w:spacing", {
                    ["w:before"] = "120",
                    ["w:after"] = "120",
                    ["w:line"] = "240",
                    ["w:lineRule"] = "auto"
                }),
                xml.node("w:ind", {["w:firstLine"] = "0"})
            }),
            xml.node("w:rPr", {}, {
                xml.node("w:rFonts", {
                    ["w:ascii"] = "Courier New",
                    ["w:hAnsi"] = "Courier New"
                }),
                xml.node("w:sz", {["w:val"] = "18"}),
                xml.node("w:szCs", {["w:val"] = "18"})
            })
        })
        xml.add_child(styles_root, source_code_style)
        log.debug('[ABNT-STYLES] Injected SourceCode style')
    end

    return xml.serialize(doc)
end

---Remove duplicate style definitions from styles.xml.
---Pandoc may inject a second definition of a custom style (e.g., Heading1)
---after the correct one from the reference-doc template. MS Word uses the
---last definition, which breaks formatting. This function keeps the first
---definition and removes any subsequent duplicates.
---@param content string styles.xml content
---@param log table Logger instance
---@return string Modified content
function M.remove_duplicate_custom_styles(content, log)
    local doc = xml.parse(content)
    if not doc or not doc.root then
        return content
    end

    local styles_root = doc.root
    if styles_root.name ~= "w:styles" then
        styles_root = xml.find_child(doc.root, "w:styles") or doc.root
    end

    local all_styles = xml.find_children(styles_root, "w:style")
    local seen = {}
    local removed = 0

    for _, style in ipairs(all_styles) do
        local style_id = xml.get_attr(style, "w:styleId")
        if style_id then
            if seen[style_id] then
                xml.remove_child(styles_root, style)
                removed = removed + 1
            else
                seen[style_id] = true
            end
        end
    end

    if removed > 0 then
        log.debug('[ABNT-STYLES] Removed %d duplicate style definition(s)', removed)
    end

    return xml.serialize(doc)
end

-- ============================================================================
-- Settings (Two-Sided Printing)
-- ============================================================================

---Configure settings.xml for ABNT two-sided printing.
---@param content string settings.xml content
---@param log table Logger instance
---@return string Modified content
function M.fix_settings(content, log)
    local modified = content

    -- Add mirrorMargins if not present (for two-sided printing)
    if not modified:match('<w:mirrorMargins') then
        modified = modified:gsub('(<w:zoom[^/]*/>)', '%1<w:mirrorMargins/>')
        log.debug('[ABNT-SETTINGS] Added mirrorMargins for two-sided printing')
    end

    -- Add evenAndOddHeaders for different even/odd page headers
    if not modified:match('<w:evenAndOddHeaders') then
        modified = modified:gsub('(<w:mirrorMargins[^/]*/>)', '%1<w:evenAndOddHeaders/>')
        log.debug('[ABNT-SETTINGS] Added evenAndOddHeaders for page numbering')
    end

    return modified
end

-- ============================================================================
-- Header File Creation (via shared header_builder)
-- ============================================================================

local prepare_pretextual_media

---Create header XML files in the word/ directory.
---This hook is called by the docx postprocessor to create additional parts.
---@param temp_dir string Path to the unpacked DOCX directory
---@param log table Logger instance
---@param _config table|nil Configuration (unused, interface contract)
function M.create_additional_parts(temp_dir, log, _config)
    local parts = {
        {file = "header1.xml", content = header_builder.build_page_number_header("right")},
        {file = "header2.xml", content = header_builder.build_page_number_header("right")},
        {file = "header3.xml", content = header_builder.build_empty_header()},
        {file = "header4.xml", content = header_builder.build_empty_header()},
    }
    header_builder.write_parts(temp_dir, parts, log)
    if prepare_pretextual_media then
        prepare_pretextual_media(temp_dir, log, _config)
    end
end

-- ============================================================================
-- Section Management (Pre-textual / Textual / Positioned Floats)
-- Uses shared section_manager module with ABNT-specific configuration.
-- ============================================================================

-- Expected header files for the ABNT model (4 headers)
local ABNT_EXPECTED_HEADERS = {"header1.xml", "header2.xml", "header3.xml", "header4.xml"}

-- Standard A4 margins used by all ABNT sections
local A4_MARGINS = {
    top = "1701", right = "1134", bottom = "1134",
    left = "1701", header = "709", footer = "709", gutter = "0",
}

local A4_EMU = { width = 7560310, height = 10692130 }

local PRETEXTUAL_IMAGES = {
    cover = {
        marker = "cover-background",
        rid = "rIdAbntCover",
        media = "abnt-cover.png",
        config_keys = {"cover_image", "cover_background", "icmc_cover_image"},
        default_asset = "assets/cover.png",
        disable_keys = {"cover_image", "use_cover_image"},
    },
    ["catalog-sheet"] = {
        marker = "full-page:catalog-sheet",
        rid = "rIdAbntCatalogSheet",
        media = "abnt-catalog-sheet.png",
        config_keys = {"catalog_sheet_pdf", "catalog_pdf", "fichacatalografica_pdf", "catalog_sheet_image", "catalog_sheet_background"},
        default_asset = "assets/catalog_sheet.png",
        disable_keys = {"catalog_sheet", "catalog_sheet_image", "use_catalog_sheet_image"},
    },
    ["approval-page"] = {
        marker = "full-page:approval-page",
        rid = "rIdAbntApprovalPage",
        media = "abnt-approval-page.png",
        config_keys = {"approval_page_pdf", "approval_pdf", "folha_de_aprovacao_pdf", "folhadeaprovacao_pdf", "approval_page_image", "approval_page_background"},
        default_asset = "assets/approval_page.png",
        disable_keys = {"approval_page", "approval_page_image", "use_approval_page_image"},
    },
}

local function docx_config(config)
    return (config and config.docx) or config or {}
end

local function shell_quote(path)
    return "'" .. tostring(path):gsub("'", "'\\''") .. "'"
end

local function file_exists(path)
    local f = io.open(path, "rb")
    if f then
        f:close()
        return true
    end
    return false
end

local function read_binary(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local data = f:read("*a")
    f:close()
    return data
end

local function write_binary(path, data)
    local f = io.open(path, "wb")
    if not f then return false end
    f:write(data)
    f:close()
    return true
end

local function model_root()
    local source = (debug.getinfo(1, "S").source or ""):gsub("^@", "")
    return source:gsub("/postprocessors/docx%.lua$", "")
end

local function resolve_project_path(path, config)
    if not path or path == "" then return nil end
    if path == true then return nil end
    if path:match("^/") then return path end
    local root = (config and config.project_root) or "."
    return root .. "/" .. path
end

local function configured_path(config, item)
    local docx = docx_config(config)
    for _, key in ipairs(item.disable_keys or {}) do
        if docx[key] == false then
            return nil
        end
    end
    for _, key in ipairs(item.config_keys or {}) do
        if docx[key] and docx[key] ~= "" then
            if docx[key] ~= true then
                return resolve_project_path(docx[key], config)
            end
        end
    end
    if item.default_asset then
        local path = model_root() .. "/" .. item.default_asset
        if file_exists(path) then return path end
    end
    return nil
end

local function register_image_relationships(content, config, log)
    local doc = xml.parse(content)
    if not doc or not doc.root then
        return content
    end

    local existing = {}
    for _, kid in ipairs(doc.root.kids or {}) do
        if kid.name == "Relationship" then
            local id = xml.get_attr(kid, "Id")
            if id then existing[id] = true end
        end
    end

    local rel_type = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"
    local added = 0
    for _, item in pairs(PRETEXTUAL_IMAGES) do
        if configured_path(config, item) and not existing[item.rid] then
            xml.add_child(doc.root, xml.node("Relationship", {
                Id = item.rid,
                Type = rel_type,
                Target = "media/" .. item.media,
            }))
            added = added + 1
        end
    end
    if added > 0 then
        log.debug("[ABNT-PRETEXTUAL] Registered %d pre-textual image relationship(s)", added)
    end

    return xml.serialize(doc)
end

local function ensure_image_content_types(content, config)
    local needs_png = false
    local needs_jpeg = false
    for _, item in pairs(PRETEXTUAL_IMAGES) do
        if configured_path(config, item) then
            if item.media:match("%.png$") then needs_png = true end
            if item.media:match("%.jpe?g$") then needs_jpeg = true end
        end
    end
    if needs_png and not content:match('Extension="png"') then
        content = content:gsub('</Types>', '<Default Extension="png" ContentType="image/png"/></Types>')
    end
    if needs_jpeg and not content:match('Extension="jpg"') then
        content = content:gsub('</Types>', '<Default Extension="jpg" ContentType="image/jpeg"/></Types>')
    end
    return content
end

local function full_page_image_ooxml(rid, alt_text, behind_doc)
    return xml.serialize_element(xml.node("w:p", {}, {
        xml.node("w:pPr", {}, {
            xml.node("w:spacing", {["w:before"] = "0", ["w:after"] = "0", ["w:line"] = "20", ["w:lineRule"] = "exact"}),
        }),
        xml.node("w:r", {}, {
            xml.node("w:drawing", {}, {
                xml.node("wp:anchor", {
                    distT = "0", distB = "0", distL = "0", distR = "0",
                    simplePos = "0", relativeHeight = behind_doc and "0" or "251658240",
                    behindDoc = behind_doc and "1" or "0",
                    locked = "0", layoutInCell = "1", allowOverlap = "1",
                }, {
                    xml.node("wp:simplePos", {x = "0", y = "0"}),
                    xml.node("wp:positionH", {relativeFrom = "page"}, {
                        xml.node("wp:posOffset", {}, {xml.text("0")}),
                    }),
                    xml.node("wp:positionV", {relativeFrom = "page"}, {
                        xml.node("wp:posOffset", {}, {xml.text("0")}),
                    }),
                    xml.node("wp:extent", {cx = tostring(A4_EMU.width), cy = tostring(A4_EMU.height)}),
                    xml.node("wp:wrapNone"),
                    xml.node("wp:docPr", {id = behind_doc and "9201" or "9202", name = alt_text or ""}),
                    xml.node("a:graphic", {["xmlns:a"] = "http://schemas.openxmlformats.org/drawingml/2006/main"}, {
                        xml.node("a:graphicData", {uri = "http://schemas.openxmlformats.org/drawingml/2006/picture"}, {
                            xml.node("pic:pic", {["xmlns:pic"] = "http://schemas.openxmlformats.org/drawingml/2006/picture"}, {
                                xml.node("pic:nvPicPr", {}, {
                                    xml.node("pic:cNvPr", {id = "0", name = alt_text or ""}),
                                    xml.node("pic:cNvPicPr"),
                                }),
                                xml.node("pic:blipFill", {}, {
                                    xml.node("a:blip", {["r:embed"] = rid}),
                                    xml.node("a:stretch", {}, {xml.node("a:fillRect")}),
                                }),
                                xml.node("pic:spPr", {}, {
                                    xml.node("a:xfrm", {}, {
                                        xml.node("a:off", {x = "0", y = "0"}),
                                        xml.node("a:ext", {cx = tostring(A4_EMU.width), cy = tostring(A4_EMU.height)}),
                                    }),
                                    xml.node("a:prstGeom", {prst = "rect"}, {xml.node("a:avLst")}),
                                }),
                            }),
                        }),
                    }),
                }),
            }),
        }),
    }))
end

local function replace_pretextual_markers(content, config, log)
    if configured_path(config, PRETEXTUAL_IMAGES.cover) then
        content = content:gsub(
            '<!%-%- specdown:abnt%-cover%-background %-%->',
            full_page_image_ooxml(PRETEXTUAL_IMAGES.cover.rid, "ABNT cover background", true)
        )
    end
    if configured_path(config, PRETEXTUAL_IMAGES["catalog-sheet"]) then
        content = content:gsub(
            '<!%-%- specdown:abnt%-full%-page:catalog%-sheet %-%->',
            full_page_image_ooxml(PRETEXTUAL_IMAGES["catalog-sheet"].rid, "Ficha catalografica", false)
        )
    end
    if configured_path(config, PRETEXTUAL_IMAGES["approval-page"]) then
        content = content:gsub(
            '<!%-%- specdown:abnt%-full%-page:approval%-page %-%->',
            full_page_image_ooxml(PRETEXTUAL_IMAGES["approval-page"].rid, "Folha de aprovacao", false)
        )
    end
    log.debug("[ABNT-PRETEXTUAL] Replaced configured pre-textual page marker(s)")
    return content
end

local function prepare_media(source, dest, log)
    if not source or not file_exists(source) then
        log.warn("[ABNT-PRETEXTUAL] Source not found: %s", tostring(source))
        return false
    end

    if source:lower():match("%.pdf$") then
        local text_cmd = "pdftotext " .. shell_quote(source) .. " - 2>/dev/null"
        local pipe = io.popen(text_cmd)
        local text = pipe and pipe:read("*a") or ""
        if pipe then pipe:close() end
        if text:match("É possível elaborar a ficha catalográfica")
            or text:match("ficha catalográfica definitiva")
            or text:match("Folha de aprovação em conformidade")
            or text:match("folhadeaprovacao%.pdf") then
            log.warn("[ABNT-PRETEXTUAL] Configured PDF appears to be a placeholder, not a final document: %s", source)
        end
        local dest_base = dest:gsub("%.png$", "")
        local cmd = "pdftoppm -singlefile -png -r 300 " .. shell_quote(source) .. " " .. shell_quote(dest_base)
        local ok = os.execute(cmd)
        if ok == true or ok == 0 then
            return file_exists(dest)
        end
        log.warn("[ABNT-PRETEXTUAL] Failed to convert PDF with pdftoppm: %s", source)
        return false
    end

    local data = read_binary(source)
    if not data then
        log.warn("[ABNT-PRETEXTUAL] Failed to read image: %s", source)
        return false
    end
    return write_binary(dest, data)
end

prepare_pretextual_media = function(temp_dir, log, config)
    local media_dir = temp_dir .. "/word/media"
    os.execute("mkdir -p " .. shell_quote(media_dir))
    for _, item in pairs(PRETEXTUAL_IMAGES) do
        local source = configured_path(config, item)
        if source then
            local dest = media_dir .. "/" .. item.media
            if prepare_media(source, dest, log) then
                log.debug("[ABNT-PRETEXTUAL] Prepared media/%s", item.media)
            end
        end
    end
end

---Build ABNT section config for pre-textual (roman numeral) pages.
---Uses empty headers (header3/header4) so no visible page numbers appear.
---@param ids table Header relationship IDs from section_manager.extract_header_ids
---@return table Section config for section_manager.build_section_properties
local function build_pretextual_config(ids)
    return {
        headers = {
            {type = "even", rid = ids.header4},
            {type = "default", rid = ids.header3},
            {type = "first", rid = ids.header3},
        },
        page_size = {w = "11906", h = "16838"},
        margins = A4_MARGINS,
        page_numbering = {fmt = "lowerRoman", start = "1"},
        cols = {space = "708"},
        title_pg = true,
        doc_grid = {line_pitch = "360"},
    }
end

---Build ABNT section config for textual (decimal) pages.
---Uses numbered headers (header1/header2) with page numbers visible.
---@param ids table Header relationship IDs from section_manager.extract_header_ids
---@return table Section config for section_manager.build_section_properties
local function build_textual_config(ids)
    return {
        headers = {
            {type = "even", rid = ids.header1},
            {type = "default", rid = ids.header2},
            {type = "first", rid = ids.header3},
        },
        page_size = {w = "11906", h = "16838"},
        margins = A4_MARGINS,
        page_numbering = {fmt = "decimal", start = "1"},
        cols = {space = "708"},
        title_pg = true,
        doc_grid = {line_pitch = "360"},
    }
end

---Build ABNT section config for positioned float pages (continues numbering).
---Supports both portrait and landscape orientations.
---@param ids table Header relationship IDs from section_manager.extract_header_ids
---@param orientation string "portrait" or "landscape"
---@return table Section config for section_manager.build_section_properties
local function build_float_config(ids, orientation)
    local pg_size
    if orientation == "landscape" then
        pg_size = {w = "16838", h = "11906", orient = "landscape"}
    else
        pg_size = {w = "11906", h = "16838"}
    end
    return {
        headers = {
            {type = "even", rid = ids.header1},
            {type = "default", rid = ids.header2},
            {type = "first", rid = ids.header3},
        },
        page_size = pg_size,
        margins = A4_MARGINS,
        page_numbering = {fmt = "decimal"},  -- no start = continues numbering
        cols = {space = "708"},
        section_type = "nextPage",
        doc_grid = {line_pitch = "360"},
    }
end

---Inject final section properties with header references into document.xml.
---Creates section-aware headers per ABNT NBR 14724:
---  - Pre-textual pages (before first numbered heading): NO page numbers
---  - Textual pages (from first numbered heading onwards): WITH page numbers
---@param content string document.xml content
---@param log table Logger instance
---@param rels_content string document.xml.rels content (to get header rIds)
---@return string Modified content
function M.inject_final_section(content, log, rels_content)
    -- Extract header relationship IDs from rels content
    local ids = section_manager.extract_header_ids(rels_content, ABNT_EXPECTED_HEADERS)

    if not ids then
        log.warn('[ABNT-SECTION] Could not find all header rIds, skipping section injection')
        return content
    end

    -- Fix positioned float section breaks (landscape pages, etc.)
    -- This must happen first so those sections get proper header references
    local function float_section_builder(orientation)
        return section_manager.build_section_properties(build_float_config(ids, orientation))
    end
    content = section_manager.fix_positioned_float_sections(content, float_section_builder, log, {
        width_emu = 8892000,
        height_emu = 5040000,
    })

    -- Find where textual content starts (first Heading1-5)
    local textual_pos = section_manager.find_first_style_position(content, TEXTUAL_STYLES)

    if textual_pos then
        -- Document has both pre-textual and textual sections
        -- 1. Inject pretextual section break before first textual heading
        local pretextual_sect = section_manager.build_section_properties(build_pretextual_config(ids))
        content = section_manager.inject_section_break(content, textual_pos, pretextual_sect, log)

        -- 2. Update first positioned float sectPr to restart at page 1
        local first_float_pattern = '<w:sectPr>%s*<w:headerReference[^>]+/>%s*<w:headerReference[^>]+/>%s*<w:headerReference[^>]+/>%s*<w:pgSz[^>]+/>%s*<w:pgMar[^>]+/>%s*<w:pgNumType w:fmt="decimal"/>'
        content = content:gsub(first_float_pattern, function(match)
            return match:gsub('<w:pgNumType w:fmt="decimal"/>', '<w:pgNumType w:fmt="decimal" w:start="1"/>')
        end, 1)
        log.debug('[ABNT-SECTION] Set first positioned float sectPr to start page numbering at 1')

        -- 3. Set body sectPr to textual (continues numbering, no start)
        local textual_continue_config = build_textual_config(ids)
        textual_continue_config.page_numbering = {fmt = "decimal"}  -- remove start
        textual_continue_config.title_pg = true
        local textual_sect_continue = section_manager.build_section_properties(textual_continue_config)
        local replaced
        content, replaced = section_manager.replace_body_sectpr(content, textual_sect_continue)
        if replaced then
            log.debug('[ABNT-SECTION] Replaced body sectPr with textual section (continues numbering)')
        else
            content = content:gsub('</w:body>', textual_sect_continue .. '</w:body>')
            log.debug('[ABNT-SECTION] Injected body sectPr with textual section (continues numbering)')
        end

        log.debug('[ABNT-SECTION] Created sections: pre-textual (roman) + textual (decimal from 1)')
    else
        -- No textual headings found - treat entire document as textual
        local textual_sect = section_manager.build_section_properties(build_textual_config(ids))
        local replaced
        content, replaced = section_manager.replace_body_sectpr(content, textual_sect)
        if replaced then
            log.debug('[ABNT-SECTION] Replaced body sectPr (no pre-textual content found)')
        else
            content = content:gsub('</w:body>', textual_sect .. '</w:body>')
            log.debug('[ABNT-SECTION] Injected body sectPr (no pre-textual content found)')
        end
    end

    return content
end

-- ============================================================================
-- Main Hook Functions (called by docx postprocessor)
-- ============================================================================

---Process document.xml with ABNT-specific modifications.
---@param content string document.xml content
---@param _config table Configuration (unused, interface contract)
---@param log table Logger instance
---@param rels_content string|nil document.xml.rels content (for header rIds)
---@return string Modified content
function M.process_document(content, _config, log, rels_content)
    -- Apply ABNT table formatting (IBGE three-line style for tables)
    content = M.fix_tables(content, log)

    -- Apply box borders to code listings (quadros)
    content = M.fix_listings(content, log)

    -- Center-align figures
    content = M.fix_figures(content, log)

    -- Keep adjacent caption/image/source paragraphs together during Word pagination
    content = M.keep_float_blocks_together(content, log)

    -- Replace configured cover/catalog/approval markers with full-page drawings.
    content = replace_pretextual_markers(content, _config, log)

    -- Apply Reference style to bibliography entries
    content = bibliography_formatter.format_bibliography(content, ABNT_BIB_CONFIG, log)

    -- Add heading numbering references
    content = heading_numberer.apply_numbering(content, ABNT_HEADING_MAP, log)

    -- Appendix/annex body headings use the post-textual letter as their parent level
    content = M.apply_appendix_annex_heading_numbering(content, log)

    -- Inject section properties with header references
    if rels_content then
        content = M.inject_final_section(content, log, rels_content)
    end

    return content
end

---Process styles.xml with ABNT-specific modifications.
---@param content string styles.xml content
---@param log table Logger instance
---@param _config table|nil Configuration (unused, interface contract)
---@return string Modified content
function M.process_styles(content, log, _config)
    -- Remove duplicate style definitions injected by Pandoc
    content = M.remove_duplicate_custom_styles(content, log)
    -- Fix code block styles
    content = M.fix_code_styles(content, log)

    return content
end

---Process numbering.xml with ABNT heading numbering.
---@param content string numbering.xml content
---@param log table Logger instance
---@return string Modified content
function M.process_numbering(content, log)
    return heading_numberer.merge_numbering(content, ABNT_NUMBERING_DEFINITIONS, log)
end

---Process settings.xml for ABNT requirements.
---@param content string settings.xml content
---@param log table Logger instance
---@return string Modified content
function M.process_settings(content, log)
    return M.fix_settings(content, log)
end

---Process [Content_Types].xml to register header parts.
---@param content string [Content_Types].xml content
---@param log table Logger instance
---@return string Modified content
function M.process_content_types(content, log, config)
    content = header_builder.register_content_types(content, ABNT_HEADER_PARTS, log)
    return ensure_image_content_types(content, config)
end

---Process document.xml.rels to add header relationships.
---@param content string document.xml.rels content
---@param log table Logger instance
---@return string Modified content
function M.process_rels(content, log, config)
    local result = header_builder.register_relationships(content, ABNT_HEADER_PARTS, log)
    return register_image_relationships(result, config, log)
end

-- ============================================================================
-- Writer Interface
-- ============================================================================

---Run the ABNT DOCX postprocessor.
---This is the standard interface called by the writer:
---  postprocessor.run(out_path, config, log)
---
---@param path string Path to the DOCX file
---@param config table Configuration (must contain template or docx settings)
---@param log table Logger instance
---@return boolean Success status
function M.run(path, config, log)
    local template = config.template or "abnt"
    -- For ABNT, we use the default DOCX postprocessor which loads this module
    -- as a template-specific handler
    local default_pp = require("models.default.postprocessors.docx")
    return default_pp.postprocess(path, template, log, config)
end

---Finalize batch of DOCX files.
---This is called by the emitter after all Pandoc processes complete.
---@param paths table Array of DOCX file paths
---@param config table Configuration (must contain template)
---@param log table Logger instance
function M.finalize(paths, config, log)
    for _, path in ipairs(paths) do
        local ok, err = pcall(M.run, path, config, log)
        if not ok then
            log.warn("[ABNT-DOCX] Postprocess failed for %s: %s", path, tostring(err))
        end
    end
end

return M
