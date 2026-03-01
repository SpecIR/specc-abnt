---ABNT OOXML Post-processor for SpecDown v2.
---Modifies DOCX files after Pandoc generation to apply ABNT-specific formatting.
---
---This includes:
---  - Table formatting (IBGE three-line style per ABNT NBR 14724:2011)
---  - Figure centering
---  - Code block styling
---  - Heading numbering
---
---@module abnt.ooxml.postprocess
---@author SpecDown Team
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
            { ilvl = 1, start = "1", num_fmt = "decimal", lvl_text = "%1.%2", suffix = "space", pstyle = "Heading2", restart_level = 1 },
            { ilvl = 2, start = "1", num_fmt = "decimal", lvl_text = "%1.%2.%3", suffix = "space", pstyle = "Heading3", restart_level = 2 },
            { ilvl = 3, start = "1", num_fmt = "decimal", lvl_text = "%1.%2.%3.%4", suffix = "space", pstyle = "Heading4", restart_level = 3 },
            { ilvl = 4, start = "1", num_fmt = "decimal", lvl_text = "%1.%2.%3.%4.%5", suffix = "space", pstyle = "Heading5", restart_level = 4 },
        }
    },
}

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

    -- Apply Reference style to bibliography entries
    content = bibliography_formatter.format_bibliography(content, ABNT_BIB_CONFIG, log)

    -- Add heading numbering references
    content = heading_numberer.apply_numbering(content, ABNT_HEADING_MAP, log)

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
function M.process_content_types(content, log)
    return header_builder.register_content_types(content, ABNT_HEADER_PARTS, log)
end

---Process document.xml.rels to add header relationships.
---@param content string document.xml.rels content
---@param log table Logger instance
---@return string Modified content
function M.process_rels(content, log)
    local result = header_builder.register_relationships(content, ABNT_HEADER_PARTS, log)
    return result
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
    local docx_config = config.docx or config
    -- For ABNT, we use the default DOCX postprocessor which loads this module
    -- as a template-specific handler
    local default_pp = require("models.default.postprocessors.docx")
    return default_pp.postprocess(path, template, log, docx_config)
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
