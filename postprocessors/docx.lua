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
    -- Word's default side cell margins (108dxa) break narrow headers like "CSCI"
    -- mid-word; tighten them toward LaTeX's \tabcolsep and add a little vertical
    -- padding so rows breathe closer to the abntex/uspsc PDF.
    cell_margins = { top = "90", bottom = "90", left = "40", right = "40" },
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
    skip_styles = { "Heading", "UnnumberedHeading", "Caption", "Source", "FigureSource", "TableSource" }
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
        TableSource = true,
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

---Fix the SourceCode style so code blocks render flush-left.
---VerbatimChar/SourceCode existence is guaranteed by the default postprocessor's
---base process_styles (which runs first); here we only patch the SourceCode
---paragraph properties: left alignment and no first-line indent (SourceCode may
---be basedOn Normal, whose ABNT first-line indent would shift code blocks).
---@param styles_content string styles.xml content
---@param log table Logger instance
---@return string Modified content
function M.fix_code_styles(styles_content, log)
    local doc = xml.parse(styles_content)
    if not doc or not doc.root then
        log.warn('[ABNT-STYLES] Failed to parse styles.xml')
        return styles_content
    end

    local source_code
    for _, style in ipairs(xml.find_children(doc.root, "w:style")) do
        if xml.get_attr(style, "w:styleId") == "SourceCode" then
            source_code = style
            break
        end
    end
    if not source_code then
        return styles_content
    end

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
        config_keys = {"cover_image", "cover_background"},
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

local function command_output(cmd)
    local pipe = io.popen(cmd .. " 2>/dev/null")
    if not pipe then return nil end
    local out = pipe:read("*l")
    pipe:close()
    if out and out ~= "" then return out end
    return nil
end

local function command_exists(name)
    return command_output("command -v " .. shell_quote(name))
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

local function source_extension(path)
    local ext = tostring(path or ""):match("%.([A-Za-z0-9]+)$")
    if not ext then return "png" end
    ext = ext:lower()
    if ext == "jpeg" then return "jpg" end
    if ext == "pdf" then return "png" end
    if ext == "png" or ext == "jpg" or ext == "gif" or ext == "bmp" or ext == "tiff" or ext == "tif" then
        return ext
    end
    return "png"
end

local function media_name_for(config, item)
    local source = configured_path(config, item)
    if not source then return item.media end
    local stem = item.media:gsub("%.[^.]+$", "")
    return stem .. "." .. source_extension(source)
end

local function content_type_for_extension(ext)
    ext = (ext or ""):lower()
    if ext == "jpg" or ext == "jpeg" then return "image/jpeg" end
    if ext == "png" then return "image/png" end
    if ext == "gif" then return "image/gif" end
    if ext == "bmp" then return "image/bmp" end
    if ext == "tif" or ext == "tiff" then return "image/tiff" end
    return "image/png"
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
                Target = "media/" .. media_name_for(config, item),
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
    local needed = {}
    for _, item in pairs(PRETEXTUAL_IMAGES) do
        local source = configured_path(config, item)
        if source then
            needed[source_extension(source)] = true
        end
    end
    for ext in pairs(needed) do
        if not content:match('Extension="' .. ext .. '"') then
            content = content:gsub(
                '</Types>',
                '<Default Extension="' .. ext .. '" ContentType="' .. content_type_for_extension(ext) .. '"/></Types>'
            )
        end
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
            local dest = media_dir .. "/" .. media_name_for(config, item)
            if prepare_media(source, dest, log) then
                log.debug("[ABNT-PRETEXTUAL] Prepared media/%s", media_name_for(config, item))
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
    -- Duplicate-style removal and code-style injection already ran in the
    -- default postprocessor's base process_styles; only ABNT-specific
    -- SourceCode paragraph fixes remain here.
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
    -- Drive the default DOCX postprocessor with this module as the hook
    -- provider, instead of having it re-require us by template name
    local default_pp = require("models.default.postprocessors.docx")
    return default_pp.postprocess(path, template, log, config, M)
end

local function truthy(value)
    if value == true then return true end
    if type(value) == "string" then
        local normalized = value:lower()
        return normalized == "1" or normalized == "true" or normalized == "yes" or normalized == "on"
    end
    return false
end

local function field_update_enabled(config)
    local docx = docx_config(config)
    if docx.update_fields ~= nil then return truthy(docx.update_fields) end
    if docx.libreoffice_update_fields ~= nil then return truthy(docx.libreoffice_update_fields) end
    if docx.refresh_fields ~= nil then return truthy(docx.refresh_fields) end
    return false
end

local function pdf_export_enabled(config)
    local docx = docx_config(config)
    if docx.export_pdf ~= nil then return truthy(docx.export_pdf) end
    if docx.pdf ~= nil then return truthy(docx.pdf) end
    if docx.libreoffice_export_pdf ~= nil then return truthy(docx.libreoffice_export_pdf) end
    return false
end

local function dirname(path)
    return tostring(path):match("^(.*)/[^/]+$") or "."
end

local function default_pdf_path(path)
    local stem = tostring(path):gsub("%.docx$", "")
    if stem == path then return path .. ".pdf" end
    return stem .. ".pdf"
end

local function pdf_output_path(path, config)
    local docx = docx_config(config)
    local configured = docx.pdf_path or docx.export_pdf_path
    if configured and configured ~= "" then
        if configured:match("^/") then return configured end
        return ((config and config.project_root) or ".") .. "/" .. configured
    end
    return default_pdf_path(path)
end

local function make_temp_dir()
    return command_output("mktemp -d 2>/dev/null")
end

local function remove_tree(path)
    if path and path ~= "" then
        os.execute("rm -rf " .. shell_quote(path))
    end
end

local function ensure_parent_dir(path)
    local dir = dirname(path)
    if dir and dir ~= "." then
        os.execute("mkdir -p " .. shell_quote(dir))
    end
end

local function replace_file(source, target)
    local data = read_binary(source)
    if not data then return false end
    return write_binary(target, data)
end

local function python_can_import_uno(python)
    local ok = os.execute(shell_quote(python) .. " -c " .. shell_quote("import uno") .. " >/dev/null 2>&1")
    return ok == true or ok == 0
end

local function find_uno_python()
    local candidates = {"/usr/bin/python3"}
    local path_python3 = command_exists("python3")
    if path_python3 then table.insert(candidates, path_python3) end
    local path_python = command_exists("python")
    if path_python then table.insert(candidates, path_python) end

    local seen = {}
    for _, candidate in ipairs(candidates) do
        if candidate and not seen[candidate] then
            seen[candidate] = true
            if candidate:match("^/") or command_exists(candidate) then
                if python_can_import_uno(candidate) then
                    return candidate
                end
            end
        end
    end
    return nil
end

local function write_field_update_script(path)
    local script = [=[
import os
import subprocess
import sys
import time
from pathlib import Path

import uno
from com.sun.star.beans import PropertyValue


def prop(name, value):
    item = PropertyValue()
    item.Name = name
    item.Value = value
    return item


def file_url(path):
    return Path(path).resolve().as_uri()


def connect(port):
    local_ctx = uno.getComponentContext()
    resolver = local_ctx.ServiceManager.createInstanceWithContext(
        "com.sun.star.bridge.UnoUrlResolver", local_ctx
    )
    url = f"uno:socket,host=127.0.0.1,port={port};urp;StarOffice.ComponentContext"
    deadline = time.time() + 30
    last_error = None
    while time.time() < deadline:
        try:
            return resolver.resolve(url)
        except Exception as exc:
            last_error = exc
            time.sleep(0.5)
    raise RuntimeError(f"could not connect to LibreOffice UNO: {last_error}")


def update_document(doc, desktop, ctx):
    try:
        doc.updateLinks()
    except Exception:
        pass

    for method_name in ("calculateAll", "updateAll"):
        method = getattr(doc, method_name, None)
        if method:
            try:
                method()
            except Exception:
                pass

    try:
        fields = doc.getTextFields().createEnumeration()
        while fields.hasMoreElements():
            try:
                fields.nextElement().update()
            except Exception:
                pass
    except Exception:
        pass

    try:
        indexes = doc.getDocumentIndexes()
        for idx in range(indexes.getCount()):
            indexes.getByIndex(idx).update()
    except Exception:
        pass

    try:
        frame = doc.getCurrentController().getFrame()
        dispatcher = ctx.ServiceManager.createInstanceWithContext(
            "com.sun.star.frame.DispatchHelper", ctx
        )
        for command in (".uno:SelectAll", ".uno:UpdateFields", ".uno:UpdateAllIndexes", ".uno:UpdateAll"):
            try:
                dispatcher.executeDispatch(frame, command, "", 0, ())
            except Exception:
                pass
    except Exception:
        pass


def main():
    if len(sys.argv) != 7:
        print("usage: lo_update_fields.py INPUT.docx OUTPUT.docx|- OUTPUT.pdf|- PROFILE_DIR PORT SOFFICE", file=sys.stderr)
        return 2

    source, target_docx, target_pdf, profile_dir, port, soffice = sys.argv[1:]
    profile = Path(profile_dir)
    profile.mkdir(parents=True, exist_ok=True)

    proc = subprocess.Popen(
        [
            soffice,
            "--headless",
            "--nologo",
            "--nodefault",
            "--nofirststartwizard",
            "--nolockcheck",
            f"-env:UserInstallation={profile.resolve().as_uri()}",
            f"--accept=socket,host=127.0.0.1,port={port};urp;StarOffice.ComponentContext",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    doc = None
    desktop = None
    try:
        ctx = connect(port)
        desktop = ctx.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", ctx)
        doc = desktop.loadComponentFromURL(
            file_url(source),
            "_blank",
            0,
            (
                prop("Hidden", True),
                prop("ReadOnly", False),
                prop("UpdateDocMode", 3),
            ),
        )
        if doc is None:
            raise RuntimeError("LibreOffice could not open source document")

        update_document(doc, desktop, ctx)
        if target_docx != "-":
            doc.storeAsURL(
                file_url(target_docx),
                (
                    prop("FilterName", "Office Open XML Text"),
                    prop("Overwrite", True),
                ),
            )
        if target_pdf != "-":
            doc.storeToURL(
                file_url(target_pdf),
                (
                    prop("FilterName", "writer_pdf_Export"),
                    prop("Overwrite", True),
                ),
            )
        return 0
    finally:
        if doc is not None:
            try:
                doc.close(True)
            except Exception:
                try:
                    doc.dispose()
                except Exception:
                    pass
        if desktop is not None:
            try:
                desktop.terminate()
            except Exception:
                pass
        try:
            proc.terminate()
            proc.wait(timeout=10)
        except Exception:
            try:
                proc.kill()
            except Exception:
                pass


if __name__ == "__main__":
    sys.exit(main())
]=]
    local f = io.open(path, "w")
    if not f then return false end
    f:write(script)
    f:close()
    return true
end

local function finalize_with_libreoffice(path, config, log, opts)
    local soffice = command_exists("libreoffice") or command_exists("soffice")
    if not soffice then
        log.warn("[ABNT-LO] LibreOffice not found; skipping LibreOffice finalization for %s", path)
        return false
    end
    local python = find_uno_python()
    if not python then
        log.warn("[ABNT-LO] No Python executable with UNO support found; skipping LibreOffice finalization for %s", path)
        return false
    end

    local temp_dir = make_temp_dir()
    if not temp_dir then
        log.warn("[ABNT-LO] Could not create temporary directory; skipping LibreOffice finalization for %s", path)
        return false
    end

    local script_path = temp_dir .. "/lo_update_fields.py"
    local profile_dir = temp_dir .. "/lo-profile"
    local updated_docx_path = temp_dir .. "/updated.docx"
    local target_docx = opts.update_docx and updated_docx_path or "-"
    local target_pdf = opts.export_pdf and pdf_output_path(path, config) or "-"
    local port = tostring(23000 + (os.time() % 20000))

    if not write_field_update_script(script_path) then
        remove_tree(temp_dir)
        log.warn("[ABNT-LO] Could not write LibreOffice helper script; skipping %s", path)
        return false
    end

    if target_pdf ~= "-" then
        ensure_parent_dir(target_pdf)
    end

    local cmd = table.concat({
        shell_quote(python),
        shell_quote(script_path),
        shell_quote(path),
        shell_quote(target_docx),
        shell_quote(target_pdf),
        shell_quote(profile_dir),
        shell_quote(port),
        shell_quote(soffice),
    }, " ")

    local ok = os.execute(cmd)
    local success = ok == true or ok == 0

    if success and opts.update_docx then
        if file_exists(updated_docx_path) and replace_file(updated_docx_path, path) then
            log.info("[ABNT-FIELDS] Updated DOCX fields in place: %s", path)
        else
            success = false
            log.warn("[ABNT-FIELDS] LibreOffice did not produce updated DOCX for %s", path)
        end
    end

    if success and opts.export_pdf then
        if file_exists(target_pdf) then
            log.info("[ABNT-PDF] Generated LibreOffice PDF: %s", target_pdf)
        else
            success = false
            log.warn("[ABNT-PDF] LibreOffice did not produce PDF for %s", path)
        end
    end

    remove_tree(temp_dir)

    if not success then
        log.warn("[ABNT-LO] LibreOffice finalization failed for %s", path)
    end
    return success
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
        else
            local update_docx = field_update_enabled(config)
            local export_pdf = pdf_export_enabled(config)
            if update_docx or export_pdf then
                local lo_ok, lo_err = pcall(finalize_with_libreoffice, path, config, log, {
                    update_docx = update_docx,
                    export_pdf = export_pdf,
                })
                if not lo_ok then
                    log.warn("[ABNT-LO] LibreOffice finalization failed for %s: %s", path, tostring(lo_err))
                end
            end
        end
    end
end

return M
