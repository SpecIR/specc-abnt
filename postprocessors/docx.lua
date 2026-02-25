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
local ndjson = require("infra.logger")

local M = {}

-- ============================================================================
-- Section Type Detection (Pre-textual vs Textual)
-- ============================================================================

-- Pre-textual styles: unnumbered elements before the main content
-- These sections should use roman numeral page numbering (i, ii, iii)
local PRETEXTUAL_STYLES = {
    ["UnnumberedHeading"] = true,
    ["TOCHeading"] = true,
    ["Dedication"] = true,
    ["Epigraph"] = true,
}

-- Textual styles: numbered main content sections
-- These sections should use arabic numeral page numbering (1, 2, 3) starting at 1
local TEXTUAL_STYLES = {
    ["Heading1"] = true,
    ["Heading2"] = true,
    ["Heading3"] = true,
    ["Heading4"] = true,
    ["Heading5"] = true,
}

-- ============================================================================
-- Header/Footer XML Templates (ABNT NBR 14724 Page Numbering)
-- ============================================================================

-- XML declaration prefix for standalone header files
local XML_DECLARATION = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'

-- Namespace declarations for OOXML header elements
local HDR_NAMESPACES = {
    ["xmlns:w"] = "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
    ["xmlns:r"] = "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
}

---Build the PAGE field runs (begin/instrText/separate/value/end).
---@return table[] Array of w:r elements for a PAGE field
local function build_page_field_runs()
    return {
        xml.node("w:r", {}, {xml.node("w:fldChar", {["w:fldCharType"] = "begin"})}),
        xml.node("w:r", {}, {xml.node("w:instrText", {["xml:space"] = "preserve"}, {xml.text(" PAGE ")})}),
        xml.node("w:r", {}, {xml.node("w:fldChar", {["w:fldCharType"] = "separate"})}),
        xml.node("w:r", {}, {xml.node("w:t", {}, {xml.text("1")})}),
        xml.node("w:r", {}, {xml.node("w:fldChar", {["w:fldCharType"] = "end"})}),
    }
end

---Build a header with page number field (for even/odd textual pages).
---@param alignment string Justification value ("left" or "right")
---@return string Complete header XML with XML declaration
local function build_page_number_header(alignment)
    local children = {
        xml.node("w:pPr", {}, {
            xml.node("w:pStyle", {["w:val"] = "Header"}),
            xml.node("w:jc", {["w:val"] = alignment}),
        }),
    }
    for _, r in ipairs(build_page_field_runs()) do
        children[#children + 1] = r
    end
    local hdr = xml.node("w:hdr", HDR_NAMESPACES, {
        xml.node("w:p", {}, children)
    })
    return XML_DECLARATION .. xml.serialize_element(hdr)
end

---Build an empty header (no page number, just Header style).
---Used for first pages and pre-textual even pages.
---@return string Complete header XML with XML declaration
local function build_empty_header()
    local hdr = xml.node("w:hdr", HDR_NAMESPACES, {
        xml.node("w:p", {}, {
            xml.node("w:pPr", {}, {
                xml.node("w:pStyle", {["w:val"] = "Header"}),
            }),
        })
    })
    return XML_DECLARATION .. xml.serialize_element(hdr)
end

-- ============================================================================
-- Page Size Fix (Empty sectPr from Pandoc default reference.docx)
-- ============================================================================

-- A4 dimensions in twips
local A4_WIDTH_TWIPS = 11906
local A4_HEIGHT_TWIPS = 16838

---Fix empty sectPr elements to include A4 page size.
---Pandoc's default reference.docx contains empty <w:sectPr/> elements that
---cause LibreOffice to use system defaults (US Letter) during PDF export.
---This function replaces empty sectPr with proper A4 page size settings.
---@param content string document.xml content
---@param log table Logger instance
---@return string Modified content
local function fix_empty_sectpr(content, log)
    local count = 0

    -- Replace empty self-closing sectPr with A4 page size
    local replacement = xml.serialize_element(xml.node("w:sectPr", {}, {
        xml.node("w:pgSz", {["w:w"] = tostring(A4_WIDTH_TWIPS), ["w:h"] = tostring(A4_HEIGHT_TWIPS)})
    }))

    content, count = content:gsub('<w:sectPr%s*/>', replacement)

    if count > 0 then
        log.debug(string.format('[ABNT-PAGESZ] Fixed %d empty sectPr with A4 page size', count))
    end

    return content
end

-- ============================================================================
-- Table Formatting (IBGE Three-Line Style for Tables, Closed for Quadros)
-- ============================================================================

---Create ABNT table borders (IBGE three-line style for Tabelas).
---Per ABNT NBR 14724:2011 / IBGE presentation norms:
---  - Top horizontal line (toprule)
---  - Header separator line (midrule) - added to header cells
---  - Bottom horizontal line (bottomrule)
---  - NO vertical lines or internal horizontal lines
---@return table XML node for w:tblBorders
local function create_tabela_borders()
    return xml.node("w:tblBorders", {}, {
        xml.node("w:top", {["w:val"]="single", ["w:sz"]="8", ["w:space"]="0", ["w:color"]="000000"}),
        xml.node("w:left", {["w:val"]="nil"}),
        xml.node("w:bottom", {["w:val"]="single", ["w:sz"]="8", ["w:space"]="0", ["w:color"]="000000"}),
        xml.node("w:right", {["w:val"]="nil"}),
        xml.node("w:insideH", {["w:val"]="nil"}),
        xml.node("w:insideV", {["w:val"]="nil"})
    })
end

---Create ABNT quadro borders (closed on all sides).
---Per ABNT NBR 14724:2011, quadros have closed borders on all sides.
---@return table XML node for w:tblBorders
local function create_quadro_borders()
    return xml.node("w:tblBorders", {}, {
        xml.node("w:top", {["w:val"]="single", ["w:sz"]="4", ["w:space"]="0", ["w:color"]="000000"}),
        xml.node("w:left", {["w:val"]="single", ["w:sz"]="4", ["w:space"]="0", ["w:color"]="000000"}),
        xml.node("w:bottom", {["w:val"]="single", ["w:sz"]="4", ["w:space"]="0", ["w:color"]="000000"}),
        xml.node("w:right", {["w:val"]="single", ["w:sz"]="4", ["w:space"]="0", ["w:color"]="000000"}),
        xml.node("w:insideH", {["w:val"]="single", ["w:sz"]="4", ["w:space"]="0", ["w:color"]="000000"}),
        xml.node("w:insideV", {["w:val"]="single", ["w:sz"]="4", ["w:space"]="0", ["w:color"]="000000"})
    })
end

---Create header cell bottom border (midrule for IBGE tables).
---@return table XML node for w:tcBorders
local function create_header_cell_border()
    return xml.node("w:tcBorders", {}, {
        xml.node("w:bottom", {["w:val"]="single", ["w:sz"]="4", ["w:space"]="0", ["w:color"]="000000"})
    })
end

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

---Apply ABNT IBGE three-line style to a data table.
---@param tbl table Table node
---@param log table Logger instance
---@return number shading_removed Count of shading elements removed
local function apply_ibge_style(tbl, log)
    local tblPr = xml.find_child(tbl, "w:tblPr")
    if not tblPr then
        tblPr = xml.node("w:tblPr")
        xml.insert_child(tbl, tblPr, 1)
    end

    -- Set table to full page width (100% = 5000 in OOXML pct scale)
    xml.replace_child(tblPr, "w:tblW", xml.node("w:tblW", {
        ["w:w"] = "5000",
        ["w:type"] = "pct"
    }))

    -- Apply IBGE three-line borders
    xml.replace_child(tblPr, "w:tblBorders", create_tabela_borders())

    local shading_removed = 0

    -- Process header rows - add midrule border
    local rows = xml.find_by_name(tbl, "w:tr")
    for _, tr in ipairs(rows) do
        local trPr = xml.find_child(tr, "w:trPr")
        if trPr then
            local tblHeader = xml.find_child(trPr, "w:tblHeader")
            if tblHeader then
                -- This is a header row - process cells
                local cells = xml.find_children(tr, "w:tc")
                for _, tc in ipairs(cells) do
                    local tcPr = xml.find_child(tc, "w:tcPr")
                    if not tcPr then
                        tcPr = xml.node("w:tcPr")
                        xml.insert_child(tc, tcPr, 1)
                    end

                    -- Remove any header shading (Pandoc blue D9E2F3 or gray E0E0E0)
                    local shd = xml.find_child(tcPr, "w:shd")
                    if shd then
                        xml.remove_child(tcPr, shd)
                        shading_removed = shading_removed + 1
                    end

                    -- Add header cell bottom border (midrule)
                    xml.replace_child(tcPr, "w:tcBorders", create_header_cell_border())
                end
            end
        end
    end

    -- Fix paragraph properties inside table (zero indent)
    local paras = xml.find_by_name(tbl, "w:p")
    for _, p in ipairs(paras) do
        local pPr = xml.find_child(p, "w:pPr")
        if not pPr then
            pPr = xml.node("w:pPr")
            xml.insert_child(p, pPr, 1)
        end
        xml.replace_child(pPr, "w:ind", xml.node("w:ind", {
            ["w:firstLine"]="0", ["w:left"]="0", ["w:right"]="0"
        }))
    end

    return shading_removed
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
    local shading_removed = 0

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
                    -- This is a data table - apply IBGE style
                    shading_removed = shading_removed + apply_ibge_style(node, log)
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
    if shading_removed > 0 then
        log.debug('[ABNT-TABLES] Removed blue header shading from %d cell(s)', shading_removed)
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
---Only applies to actual listing floats (Caption → SourceCode → Source pattern),
---not to regular code blocks used inline.
---@param content string document.xml content
---@param log table Logger instance
---@return string Modified content
function M.fix_listings(content, log)
    local doc = xml.parse(content)
    if not doc or not doc.root then
        ndjson.warning('[ABNT-LISTINGS] Failed to parse document.xml')
        return content
    end

    local listing_count = 0
    local float_count = 0

    -- Get document body
    local body = xml.find_child(doc.root, "w:body")
    if not body then
        ndjson.warning('[ABNT-LISTINGS] Could not find w:body')
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
        ndjson.info(string.format('[ABNT-LISTINGS] Applied box borders to %d paragraph(s) in %d listing float(s)', listing_count, float_count))
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

-- ============================================================================
-- Heading Numbering
-- ============================================================================

---Build a single heading numbering level.
---For ABNT, markdown ## (Heading2) is the main section level, so:
---  Heading2 → ilvl=0 (1, 2, 3)
---  Heading3 → ilvl=1 (1.1, 1.2)
---  Heading4 → ilvl=2 (1.1.1)
---  Heading5 → ilvl=3 (1.1.1.1)
---@param ilvl number Level index (0-based)
---@param style string Paragraph style name (e.g., "Heading2")
---@param text_fmt string OOXML level text format (e.g., "%1", "%1.%2")
---@return table XML element node for w:lvl
local function build_numbering_level(ilvl, style, text_fmt)
    return xml.node("w:lvl", {["w:ilvl"] = tostring(ilvl)}, {
        xml.node("w:start", {["w:val"] = "1"}),
        xml.node("w:numFmt", {["w:val"] = "decimal"}),
        xml.node("w:pStyle", {["w:val"] = style}),
        xml.node("w:lvlText", {["w:val"] = text_fmt}),
        xml.node("w:lvlJc", {["w:val"] = "left"}),
        xml.node("w:pPr", {}, {
            xml.node("w:ind", {["w:left"] = "0", ["w:firstLine"] = "0"})
        }),
    })
end

---Build the ABNT heading numbering abstractNum definition.
---@return string Serialized XML for the abstractNum element
local function build_heading_numbering()
    return xml.serialize_element(xml.node("w:abstractNum", {
        ["w:abstractNumId"] = "0",
        ["xmlns:w"] = "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
    }, {
        xml.node("w:multiLevelType", {["w:val"] = "multilevel"}),
        build_numbering_level(0, "Heading2", "%1"),
        build_numbering_level(1, "Heading3", "%1.%2"),
        build_numbering_level(2, "Heading4", "%1.%2.%3"),
        build_numbering_level(3, "Heading5", "%1.%2.%3.%4"),
    }))
end

---Merge ABNT heading numbering into numbering.xml.
---@param content string numbering.xml content
---@param log table Logger instance
---@return string Modified content
function M.merge_heading_numbering(content, log)
    -- Check if numbering.xml exists
    if not content or content == '' then
        log.debug('[ABNT-NUMBERING] No numbering.xml, creating new')
        return [[<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
]] .. build_heading_numbering() .. [[
<w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num>
</w:numbering>]]
    end

    -- Check if we already have heading numbering
    if content:match('w:pStyle%s+w:val="Heading1"') then
        log.debug('[ABNT-NUMBERING] Heading numbering already present')
        return content
    end

    -- Insert our abstractNum and num before closing tag
    -- Use function replacement to avoid % being interpreted as capture reference
    local numbering_xml = build_heading_numbering()
    local replacement = numbering_xml .. '\n<w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num>\n</w:numbering>'
    local modified = content:gsub('</w:numbering>', function() return replacement end)

    log.debug('[ABNT-NUMBERING] Merged ABNT heading numbering definition')
    return modified
end

---Add numPr to heading paragraphs in document.xml.
---Maps heading styles to numbering levels:
---  Heading1 → ilvl=0 (numbered as 1, 2, 3) - Main chapters/sections
---  Heading2 → ilvl=1 (numbered as 1.1, 1.2)
---  Heading3 → ilvl=2 (numbered as 1.1.1)
---  Heading4 → ilvl=3 (numbered as 1.1.1.1)
---  Heading5 → ilvl=4 (numbered as 1.1.1.1.1)
---Pre-textual elements use UnnumberedHeading style and are not numbered.
---@param content string document.xml content
---@param log table Logger instance
---@return string Modified content
function M.add_heading_numbering(content, log)
    local doc = xml.parse(content)
    if not doc or not doc.root then
        log.warn('[ABNT-NUMBERING] Failed to parse document.xml')
        return content
    end

    -- Map heading styles to ilvl for ABNT numbering
    local heading_levels = {
        ["Heading1"] = 0,  -- Main chapters (1, 2, 3)
        ["Heading2"] = 1,  -- Sections (1.1, 1.2)
        ["Heading3"] = 2,  -- Subsections (1.1.1)
        ["Heading4"] = 3,  -- Sub-subsections (1.1.1.1)
        ["Heading5"] = 4   -- Sub-sub-subsections (1.1.1.1.1)
    }

    local numbered_count = 0
    local paras = xml.find_by_name(doc.root, "w:p")

    for _, p in ipairs(paras) do
        local pPr = xml.find_child(p, "w:pPr")
        if pPr then
            local pStyle = xml.find_child(pPr, "w:pStyle")
            if pStyle then
                local style_id = xml.get_attr(pStyle, "w:val")
                local ilvl = heading_levels[style_id]

                if ilvl and not xml.find_child(pPr, "w:numPr") then
                    -- Add numbering reference
                    local numPr = xml.node("w:numPr", {}, {
                        xml.node("w:ilvl", {["w:val"] = tostring(ilvl)}),
                        xml.node("w:numId", {["w:val"] = "1"})
                    })
                    xml.add_child(pPr, numPr)
                    numbered_count = numbered_count + 1
                end
            end
        end
    end

    if numbered_count > 0 then
        log.debug('[ABNT-NUMBERING] Added numbering to %d heading(s)', numbered_count)
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
-- Header File Creation
-- ============================================================================

---Create header XML files in the word/ directory.
---This hook is called by the docx postprocessor to create additional parts.
---@param temp_dir string Path to the unpacked DOCX directory
---@param log table Logger instance
---@param config table|nil Configuration
function M.create_additional_parts(temp_dir, log, config)
    local word_dir = temp_dir .. "/word"

    -- Write header files
    -- header1: Even pages with page numbers (textual sections)
    -- header2: Odd pages with page numbers (textual sections)
    -- header3: First page empty (used for first page of any section)
    -- header4: Even pages empty (pre-textual sections - no page numbers)
    local headers = {
        {file = "header1.xml", content = build_page_number_header("left"), desc = "even page (with page number)"},
        {file = "header2.xml", content = build_page_number_header("right"), desc = "odd page (with page number)"},
        {file = "header3.xml", content = build_empty_header(), desc = "first page (empty)"},
        {file = "header4.xml", content = build_empty_header(), desc = "even page (empty, pre-textual)"},
    }

    for _, h in ipairs(headers) do
        local path = word_dir .. "/" .. h.file
        local f = io.open(path, "w")
        if f then
            f:write(h.content)
            f:close()
            log.debug('[ABNT-HEADERS] Created %s (%s header)', h.file, h.desc)
        else
            log.warn('[ABNT-HEADERS] Failed to create %s', h.file)
        end
    end
end

---Extract header relationship IDs from document.xml.rels content.
---@param rels_content string document.xml.rels content
---@return table|nil Table with header1_id, header2_id, header3_id, header4_id or nil
local function extract_header_ids(rels_content)
    local ids = {}

    for id, target in rels_content:gmatch('Id="(rId%d+)"%s+Target="(header%d%.xml)"') do
        if target == "header1.xml" then
            ids.header1 = id
        elseif target == "header2.xml" then
            ids.header2 = id
        elseif target == "header3.xml" then
            ids.header3 = id
        elseif target == "header4.xml" then
            ids.header4 = id
        end
    end

    if ids.header1 and ids.header2 and ids.header3 and ids.header4 then
        return ids
    end
    return nil
end

---Detect if a paragraph style is a numbered heading (textual content).
---ABNT textual sections use Heading1-5 styles which are numbered.
---Uses the TEXTUAL_STYLES lookup table for consistency.
---@param style_id string The w:pStyle value
---@return boolean true if this is a numbered heading style
local function is_textual_heading(style_id)
    return style_id and TEXTUAL_STYLES[style_id] == true
end

---Detect if a paragraph style is a pre-textual heading (unnumbered content).
---Uses the PRETEXTUAL_STYLES lookup table for section detection.
---@param style_id string The w:pStyle value
---@return boolean true if this is a pre-textual heading style
local function is_pretextual_heading(style_id)
    return style_id and PRETEXTUAL_STYLES[style_id] == true
end

---Find the position of the first textual heading in the document.
---Textual headings are Heading1-5 (numbered sections).
---Pre-textual elements use UnnumberedHeading or no heading at all.
---@param content string document.xml content
---@return number|nil Start position of the paragraph containing first textual heading
local function find_first_textual_heading_position(content)
    -- Find all paragraphs with pStyle
    -- We need to find the first one that has Heading1, Heading2, etc.
    local search_start = 1
    while true do
        -- Find next paragraph
        local p_start, p_end = content:find("<w:p[%s>]", search_start)
        if not p_start then break end

        -- Find the end of this paragraph
        local p_close = content:find("</w:p>", p_end)
        if not p_close then break end

        -- Extract paragraph content
        local para_content = content:sub(p_start, p_close + 5)

        -- Check if it has a heading style
        local style_val = para_content:match('<w:pStyle%s+w:val="([^"]+)"')
        if style_val and is_textual_heading(style_val) then
            return p_start
        end

        search_start = p_close + 1
    end
    return nil
end

-- Standard A4 page margin attributes used across all section types
local A4_MARGINS = {
    ["w:top"] = "1701", ["w:right"] = "1134", ["w:bottom"] = "1134",
    ["w:left"] = "1701", ["w:header"] = "709", ["w:footer"] = "709", ["w:gutter"] = "0",
}

---Create section properties XML for pre-textual section (roman numerals).
---Uses header3 (first/empty) and header4 (even/empty) for no visible page numbers.
---Page numbering uses lowercase roman numerals (i, ii, iii) starting at 1.
---@param ids table Header relationship IDs
---@return string Section properties XML
local function create_pretextual_section(ids)
    -- Pre-textual section: empty headers (no visible page numbers)
    -- header3 = first page (empty)
    -- header4 = even pages (empty)
    -- header3 also used as default (odd) - empty
    -- Page numbering: lowercase roman numerals starting at 1
    return xml.serialize_element(xml.node("w:sectPr", {}, {
        xml.node("w:headerReference", {["w:type"] = "even", ["r:id"] = ids.header4}),
        xml.node("w:headerReference", {["w:type"] = "default", ["r:id"] = ids.header3}),
        xml.node("w:headerReference", {["w:type"] = "first", ["r:id"] = ids.header3}),
        xml.node("w:pgSz", {["w:w"] = "11906", ["w:h"] = "16838"}),
        xml.node("w:pgMar", A4_MARGINS),
        xml.node("w:pgNumType", {["w:fmt"] = "lowerRoman", ["w:start"] = "1"}),
        xml.node("w:cols", {["w:space"] = "708"}),
        xml.node("w:titlePg"),
        xml.node("w:docGrid", {["w:linePitch"] = "360"}),
    }))
end

---Create section properties XML for textual section (with page numbers).
---Uses header1 (even with page) and header2 (odd with page).
---Page numbering uses decimal (arabic) numerals starting at 1.
---@param ids table Header relationship IDs
---@return string Section properties XML
local function create_textual_section(ids)
    -- Textual section: headers with page numbers
    -- header1 = even pages (page number left)
    -- header2 = odd pages (page number right) - used as default
    -- header3 = first page (empty)
    -- Page numbering: decimal (arabic) starting at 1
    return xml.serialize_element(xml.node("w:sectPr", {}, {
        xml.node("w:headerReference", {["w:type"] = "even", ["r:id"] = ids.header1}),
        xml.node("w:headerReference", {["w:type"] = "default", ["r:id"] = ids.header2}),
        xml.node("w:headerReference", {["w:type"] = "first", ["r:id"] = ids.header3}),
        xml.node("w:pgSz", {["w:w"] = "11906", ["w:h"] = "16838"}),
        xml.node("w:pgMar", A4_MARGINS),
        xml.node("w:pgNumType", {["w:fmt"] = "decimal", ["w:start"] = "1"}),
        xml.node("w:cols", {["w:space"] = "708"}),
        xml.node("w:titlePg"),
        xml.node("w:docGrid", {["w:linePitch"] = "360"}),
    }))
end

---Create section properties XML for positioned float section breaks.
---Similar to textual section but WITHOUT w:start to continue page numbering.
---Supports both portrait and landscape orientations.
---@param ids table Header relationship IDs
---@param orientation string "portrait" or "landscape"
---@return string Section properties XML
local function create_positioned_float_section(ids, orientation)
    local pg_size_attrs
    if orientation == "landscape" then
        -- A4 landscape: width and height swapped
        pg_size_attrs = {["w:w"] = "16838", ["w:h"] = "11906", ["w:orient"] = "landscape"}
    else
        -- A4 portrait
        pg_size_attrs = {["w:w"] = "11906", ["w:h"] = "16838"}
    end

    -- Same as textual section but WITHOUT w:start to continue numbering
    return xml.serialize_element(xml.node("w:sectPr", {}, {
        xml.node("w:headerReference", {["w:type"] = "even", ["r:id"] = ids.header1}),
        xml.node("w:headerReference", {["w:type"] = "default", ["r:id"] = ids.header2}),
        xml.node("w:headerReference", {["w:type"] = "first", ["r:id"] = ids.header3}),
        xml.node("w:pgSz", pg_size_attrs),
        xml.node("w:pgMar", A4_MARGINS),
        xml.node("w:pgNumType", {["w:fmt"] = "decimal"}),
        xml.node("w:cols", {["w:space"] = "708"}),
        xml.node("w:type", {["w:val"] = "nextPage"}),
        xml.node("w:docGrid", {["w:linePitch"] = "360"}),
    }))
end

---Fix positioned float section breaks by replacing minimal sectPr with full sectPr.
---Finds marker comments <!-- specdown:sectPr:orientation --> and replaces the
---adjacent minimal sectPr paragraph with a full sectPr including header references.
---Also scales images within landscape sections to fit the content area.
---@param content string document.xml content
---@param ids table Header relationship IDs
---@param log table Logger instance
---@return string Modified content
local function fix_positioned_float_sections(content, ids, log)
    local sect_count = 0
    local img_count = 0

    -- Landscape A4 content area in EMUs (after margins)
    -- Page: 297mm × 210mm
    -- Margins: left 30mm, right 20mm, top 30mm, bottom 20mm
    -- Content width: 297-30-20 = 247mm = 8,892,000 EMUs
    -- Content height: 210-30-20 = 160mm, minus caption ~20mm = ~140mm = 5,040,000 EMUs
    local LANDSCAPE_CONTENT_WIDTH_EMU = 8892000
    local LANDSCAPE_CONTENT_HEIGHT_EMU = 5040000

    -- Pattern to find our marker + minimal sectPr paragraph
    -- The marker is: <!-- specdown:sectPr:ORIENTATION -->
    -- Followed by: <w:p><w:pPr><w:sectPr>..minimal..</w:sectPr></w:pPr></w:p>
    local sect_pattern = '<!%-%- specdown:sectPr:(%w+) %-%-><w:p>%s*<w:pPr>%s*<w:sectPr>.-</w:sectPr>%s*</w:pPr>%s*</w:p>'

    -- First pass: track positions of landscape sectPr
    local landscape_positions = {}
    local search_pos = 1
    while true do
        local start_pos, end_pos, orientation = content:find('<!%-%- specdown:sectPr:(%w+) %-%->.-</w:sectPr>%s*</w:pPr>%s*</w:p>', search_pos)
        if not start_pos then break end
        if orientation == "landscape" then
            table.insert(landscape_positions, {start_pos = start_pos, end_pos = end_pos})
        end
        search_pos = end_pos + 1
    end

    -- Second pass: scale images that appear just before landscape sectPr markers
    -- An image is "just before" if it's within 2000 characters before the marker
    for _, pos in ipairs(landscape_positions) do
        local search_start = math.max(1, pos.start_pos - 5000)
        local region = content:sub(search_start, pos.start_pos)

        -- Find the last wp:extent in this region and scale it
        local last_extent_start, last_extent_end, cx, cy = nil, nil, nil, nil
        local ext_search = 1
        while true do
            local s, e, w, h = region:find('<wp:extent%s+cx="(%d+)"%s+cy="(%d+)"', ext_search)
            if not s then break end
            last_extent_start, last_extent_end, cx, cy = s + search_start - 1, e + search_start - 1, tonumber(w), tonumber(h)
            ext_search = e + 1
        end

        if cx and cy and cx > 0 and cy > 0 then
            -- Calculate scale factors to fit both width and height
            local scale_w = LANDSCAPE_CONTENT_WIDTH_EMU / cx
            local scale_h = LANDSCAPE_CONTENT_HEIGHT_EMU / cy
            -- Use the smaller scale to fit within both dimensions
            local scale = math.min(scale_w, scale_h)
            if scale > 1 then  -- Only scale up, not down
                local new_cx = math.floor(cx * scale)
                local new_cy = math.floor(cy * scale)

                -- Also find and scale the a:ext element (same dimensions)
                local old_extent = string.format('<wp:extent cx="%d" cy="%d"', cx, cy)
                local new_extent = string.format('<wp:extent cx="%d" cy="%d"', new_cx, new_cy)

                local old_aext = string.format('<a:ext cx="%d" cy="%d"', cx, cy)
                local new_aext = string.format('<a:ext cx="%d" cy="%d"', new_cx, new_cy)

                -- Replace in the content (only first occurrence near this position)
                local before = content:sub(1, search_start - 1)
                local after = content:sub(pos.start_pos)
                local middle = content:sub(search_start, pos.start_pos - 1)

                middle = middle:gsub(old_extent:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"), new_extent, 1)
                middle = middle:gsub(old_aext:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"), new_aext, 1)

                content = before .. middle .. after
                img_count = img_count + 1
            end
        end
    end

    -- Third pass: replace minimal sectPr with full sectPr
    content = content:gsub(sect_pattern, function(orientation)
        sect_count = sect_count + 1
        local full_sect = create_positioned_float_section(ids, orientation)
        -- Wrap in paragraph like the original
        return string.format('<w:p><w:pPr>%s</w:pPr></w:p>', full_sect)
    end)

    if sect_count > 0 then
        log.debug('[ABNT-SECTION] Fixed ' .. sect_count .. ' positioned float section break(s) with header references')
    end
    if img_count > 0 then
        log.debug('[ABNT-SECTION] Scaled ' .. img_count .. ' image(s) to fit landscape content area')
    end

    return content
end

---Inject section break before the first textual heading paragraph.
---Section breaks in OOXML are placed in the LAST paragraph of the section
---(inside its w:pPr), not the first paragraph of the new section.
---@param content string document.xml content
---@param textual_pos number Position of first textual heading paragraph
---@param pretextual_sect string Pre-textual section properties XML
---@param log table Logger instance
---@return string Modified content
local function inject_section_break(content, textual_pos, pretextual_sect, log)
    -- Find the paragraph BEFORE the textual heading
    -- We need to insert sectPr into the last paragraph of pre-textual content

    -- Search backwards from textual_pos to find the previous </w:p>
    local prev_p_end = nil
    local search_pos = textual_pos - 1
    while search_pos > 0 do
        local found = content:sub(1, search_pos):match(".*</w:p>()")
        if found then
            prev_p_end = found - 1  -- Position right after </w:p>
            break
        end
        search_pos = search_pos - 100
    end

    if not prev_p_end then
        log.warn('[ABNT-SECTION] Could not find paragraph before textual content')
        return content
    end

    -- Find the start of this previous paragraph
    local prev_p_start = content:sub(1, prev_p_end):match(".*()<w:p[%s>]")
    if not prev_p_start then
        log.warn('[ABNT-SECTION] Could not find start of previous paragraph')
        return content
    end

    -- Extract the previous paragraph
    local prev_para = content:sub(prev_p_start, prev_p_end)

    -- Check if paragraph already has w:pPr
    local has_pPr = prev_para:match("<w:pPr>")

    local modified_para
    if has_pPr then
        -- Insert sectPr inside existing pPr (at the end, before </w:pPr>)
        modified_para = prev_para:gsub("</w:pPr>", pretextual_sect .. "</w:pPr>")
    else
        -- Add pPr with sectPr after <w:p> or <w:p ...>
        modified_para = prev_para:gsub("(<w:p[^>]*>)", "%1<w:pPr>" .. pretextual_sect .. "</w:pPr>")
    end

    -- Replace the paragraph in content
    local before = content:sub(1, prev_p_start - 1)
    local after = content:sub(prev_p_end + 1)
    content = before .. modified_para .. after

    log.debug('[ABNT-SECTION] Injected section break before first textual heading')
    return content
end

---Replace only the LAST <w:sectPr>...</w:sectPr> in the document body.
---This avoids the bug where Lua's non-greedy `.-` in
---`<w:sectPr>.-</w:sectPr>` would match from the FIRST opening tag
---across multiple sectPr elements to the LAST closing tag, destroying
---all content between mid-document section breaks and the body-level sectPr.
---@param content string document.xml content
---@param new_sectpr string Replacement sectPr XML
---@return string Modified content
---@return boolean true if replacement was made
local function replace_body_sectpr(content, new_sectpr)
    -- Find the last <w:sectPr> or <w:sectPr ...> in the document
    local last_start = nil
    local pos = 1
    while true do
        -- Match both <w:sectPr> and <w:sectPr ...> (with attributes)
        local s = content:find("<w:sectPr[>%s]", pos)
        if not s then break end
        last_start = s
        pos = s + 1
    end

    if not last_start then return content, false end

    -- Find the closing </w:sectPr> after the last opening
    local end_tag = "</w:sectPr>"
    local end_pos = content:find(end_tag, last_start, true)
    if not end_pos then return content, false end

    local before = content:sub(1, last_start - 1)
    local after = content:sub(end_pos + #end_tag)
    return before .. new_sectpr .. after, true
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
    local ids = extract_header_ids(rels_content)

    if not ids then
        log.warn('[ABNT-SECTION] Could not find all header rIds (need header1-4), skipping section injection')
        return content
    end

    -- Fix positioned float section breaks (landscape pages, etc.)
    -- This must happen first so those sections get proper header references
    content = fix_positioned_float_sections(content, ids, log)

    -- Find where textual content starts (first Heading1-5)
    local textual_pos = find_first_textual_heading_position(content)

    if textual_pos then
        -- Document has both pre-textual and textual sections
        -- 1. Inject section break before first textual heading (ends pre-textual section)
        local pretextual_sect = create_pretextual_section(ids)
        content = inject_section_break(content, textual_pos, pretextual_sect, log)

        -- 2. Find and update the FIRST positioned float sectPr to start at page 1
        -- This ensures textual content uses decimal starting at 1, not continuing from pre-textual
        local first_float_sect_pattern = '<w:sectPr>%s*<w:headerReference[^>]+/>%s*<w:headerReference[^>]+/>%s*<w:headerReference[^>]+/>%s*<w:pgSz[^>]+/>%s*<w:pgMar[^>]+/>%s*<w:pgNumType w:fmt="decimal"/>'
        local replacement = function(match)
            -- Add start="1" to the first positioned float sectPr
            return match:gsub('<w:pgNumType w:fmt="decimal"/>', '<w:pgNumType w:fmt="decimal" w:start="1"/>')
        end
        content = content:gsub(first_float_sect_pattern, replacement, 1)  -- Only first occurrence
        log.debug('[ABNT-SECTION] Set first positioned float sectPr to start page numbering at 1')

        -- 3. Set the final (body) section to textual (with page numbers, no restart)
        -- Create a textual section that CONTINUES numbering (no start attribute)
        local textual_sect_continue = xml.serialize_element(xml.node("w:sectPr", {}, {
            xml.node("w:headerReference", {["w:type"] = "even", ["r:id"] = ids.header1}),
            xml.node("w:headerReference", {["w:type"] = "default", ["r:id"] = ids.header2}),
            xml.node("w:headerReference", {["w:type"] = "first", ["r:id"] = ids.header3}),
            xml.node("w:pgSz", {["w:w"] = "11906", ["w:h"] = "16838"}),
            xml.node("w:pgMar", A4_MARGINS),
            xml.node("w:pgNumType", {["w:fmt"] = "decimal"}),
            xml.node("w:cols", {["w:space"] = "708"}),
            xml.node("w:titlePg"),
            xml.node("w:docGrid", {["w:linePitch"] = "360"}),
        }))

        -- Replace the body-level sectPr (the LAST sectPr in the document)
        local replaced
        content, replaced = replace_body_sectpr(content, textual_sect_continue)
        if replaced then
            log.debug('[ABNT-SECTION] Replaced body sectPr with textual section (continues numbering)')
        else
            -- No sectPr found - insert before </w:body>
            content = content:gsub('</w:body>', textual_sect_continue .. '</w:body>')
            log.debug('[ABNT-SECTION] Injected body sectPr with textual section (continues numbering)')
        end

        log.debug('[ABNT-SECTION] Created sections: pre-textual (roman) + textual (decimal from 1)')
    else
        -- No textual headings found - treat entire document as textual
        -- (This handles documents that are all textual content)
        local textual_sect = create_textual_section(ids)

        local replaced
        content, replaced = replace_body_sectpr(content, textual_sect)
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
-- Bibliography Styling
-- ============================================================================

---Apply Reference style to bibliography entries (paragraphs after refs bookmark).
---Citeproc generates bibliography as regular paragraphs inside the #refs div,
---which becomes a bookmark in OOXML. This function finds those paragraphs and
---applies the Reference paragraph style.
---@param content string document.xml content
---@param log table Logger instance
---@return string Modified content
function M.fix_bibliography(content, log)
    local doc = xml.parse(content)
    if not doc or not doc.root then
        log.warn('[ABNT-BIBLIOGRAPHY] Failed to parse document.xml')
        return content
    end

    -- Find bookmarkStart with name="refs"
    local refs_bookmark = nil
    local bookmarks = xml.find_by_name(doc.root, "w:bookmarkStart")
    for _, bm in ipairs(bookmarks) do
        local name = xml.get_attr(bm, "w:name")
        if name == "refs" then
            refs_bookmark = bm
            break
        end
    end

    if not refs_bookmark then
        log.debug('[ABNT-BIBLIOGRAPHY] No refs bookmark found, skipping bibliography styling')
        return content
    end

    local refs_id = xml.get_attr(refs_bookmark, "w:id")
    if not refs_id then
        log.warn('[ABNT-BIBLIOGRAPHY] refs bookmark has no id')
        return content
    end

    -- Find corresponding bookmarkEnd
    local body = xml.find_child(doc.root, "w:body")
    if not body then
        return content
    end

    local kids = body.kids or {}
    local refs_start_idx = nil
    local refs_end_idx = nil

    -- Find indices of refs bookmark range
    for i, node in ipairs(kids) do
        if node.type == "element" then
            if node.name == "w:bookmarkStart" or node.name == "bookmarkStart" then
                if xml.get_attr(node, "w:name") == "refs" then
                    refs_start_idx = i
                end
            elseif node.name == "w:bookmarkEnd" or node.name == "bookmarkEnd" then
                if xml.get_attr(node, "w:id") == refs_id then
                    refs_end_idx = i
                    break
                end
            elseif (node.name == "w:p" or node.name == "p") and refs_start_idx then
                -- Check if this paragraph contains the bookmarkStart
                local nested_bm = xml.find_by_name(node, "w:bookmarkStart")
                for _, nbm in ipairs(nested_bm) do
                    if xml.get_attr(nbm, "w:name") == "refs" then
                        refs_start_idx = i
                        break
                    end
                end
                -- Check for bookmarkEnd inside paragraph
                local nested_end = xml.find_by_name(node, "w:bookmarkEnd")
                for _, ne in ipairs(nested_end) do
                    if xml.get_attr(ne, "w:id") == refs_id then
                        refs_end_idx = i
                        break
                    end
                end
            end
        end
    end

    if not refs_start_idx then
        -- Try to find bookmark inside a paragraph
        for i, node in ipairs(kids) do
            if node.type == "element" and (node.name == "w:p" or node.name == "p") then
                local nested_bm = xml.find_by_name(node, "w:bookmarkStart")
                for _, nbm in ipairs(nested_bm) do
                    if xml.get_attr(nbm, "w:name") == "refs" then
                        refs_start_idx = i
                        break
                    end
                end
                if refs_start_idx then break end
            end
        end
    end

    if not refs_start_idx then
        log.debug('[ABNT-BIBLIOGRAPHY] Could not find refs bookmark position')
        return content
    end

    -- Style all paragraphs after refs bookmark (until bookmarkEnd or end of document)
    local styled_count = 0
    local end_idx = refs_end_idx or #kids

    for i = refs_start_idx + 1, end_idx do
        local node = kids[i]
        if node and node.type == "element" and (node.name == "w:p" or node.name == "p") then
            local pPr = xml.find_child(node, "w:pPr")
            if not pPr then
                pPr = xml.node("w:pPr")
                xml.insert_child(node, pPr, 1)
            end

            -- Check if already has a pStyle (skip if it's a heading or special style)
            local existing_style = xml.find_child(pPr, "w:pStyle")
            if existing_style then
                local style_val = xml.get_attr(existing_style, "w:val")
                -- Skip headings and special styles
                if style_val and (style_val:match("^Heading") or style_val == "UnnumberedHeading" or style_val == "Caption" or style_val == "Source") then
                    goto continue
                end
            end

            -- Apply Reference style
            xml.replace_child(pPr, "w:pStyle", xml.node("w:pStyle", {["w:val"] = "Reference"}))
            styled_count = styled_count + 1
        end
        ::continue::
    end

    if styled_count > 0 then
        log.debug('[ABNT-BIBLIOGRAPHY] Applied Reference style to %d bibliography entry(s)', styled_count)
    end

    return xml.serialize(doc)
end

-- ============================================================================
-- Main Hook Functions (called by docx postprocessor)
-- ============================================================================

---Process document.xml with ABNT-specific modifications.
---@param content string document.xml content
---@param config table Configuration
---@param log table Logger instance
---@param rels_content string|nil document.xml.rels content (for header rIds)
---@return string Modified content
function M.process_document(content, config, log, rels_content)
    -- Apply ABNT table formatting (IBGE three-line style for tables, closed for quadros)
    content = M.fix_tables(content, log)

    -- Apply box borders to code listings (quadros)
    content = M.fix_listings(content, log)

    -- Center-align figures
    content = M.fix_figures(content, log)

    -- Apply Reference style to bibliography entries
    content = M.fix_bibliography(content, log)

    -- Add heading numbering references
    content = M.add_heading_numbering(content, log)

    -- Inject section properties with header references
    if rels_content then
        content = M.inject_final_section(content, log, rels_content)
    end

    return content
end

---Process styles.xml with ABNT-specific modifications.
---@param content string styles.xml content
---@param log table Logger instance
---@param config table|nil Configuration
---@return string Modified content
function M.process_styles(content, log, config)
    -- Fix code block styles
    content = M.fix_code_styles(content, log)

    return content
end

---Process numbering.xml with ABNT heading numbering.
---@param content string numbering.xml content
---@param log table Logger instance
---@return string Modified content
function M.process_numbering(content, log)
    return M.merge_heading_numbering(content, log)
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
    local modified = content

    -- Header content type override entries
    local header_overrides = {
        '<Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml" />',
        '<Override PartName="/word/header2.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml" />',
        '<Override PartName="/word/header3.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml" />',
        '<Override PartName="/word/header4.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml" />',
    }

    local added = 0
    for _, override in ipairs(header_overrides) do
        local part_name = override:match('PartName="([^"]+)"')
        if not modified:match(part_name:gsub("/", "/"):gsub("%.", "%%.")) then
            modified = modified:gsub('</Types>', override .. '\n</Types>')
            added = added + 1
        end
    end

    if added > 0 then
        log.debug('[ABNT-CONTENT-TYPES] Added %d header content type(s)', added)
    end

    return modified
end

---Process document.xml.rels to add header relationships.
---@param content string document.xml.rels content
---@param log table Logger instance
---@return string Modified content
function M.process_rels(content, log)
    local modified = content

    -- Find the highest existing rId number
    local max_id = 0
    for id in modified:gmatch('Id="rId(%d+)"') do
        local num = tonumber(id)
        if num and num > max_id then
            max_id = num
        end
    end

    -- Header relationship entries (use consecutive IDs after max)
    -- header1: Even pages with page numbers (textual)
    -- header2: Odd pages with page numbers (textual)
    -- header3: First page empty
    -- header4: Even pages empty (pre-textual)
    local header_rels = {
        {id = max_id + 1, target = "header1.xml"},
        {id = max_id + 2, target = "header2.xml"},
        {id = max_id + 3, target = "header3.xml"},
        {id = max_id + 4, target = "header4.xml"},
    }

    local added = 0
    for _, rel in ipairs(header_rels) do
        if not modified:match('Target="' .. rel.target .. '"') then
            local rel_xml = string.format(
                '<Relationship Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Id="rId%d" Target="%s" />',
                rel.id, rel.target
            )
            modified = modified:gsub('</Relationships>', rel_xml .. '\n</Relationships>')
            added = added + 1
        end
    end

    if added > 0 then
        log.debug('[ABNT-RELS] Added %d header relationship(s)', added)
    end

    return modified
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
