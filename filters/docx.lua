---ABNT DOCX filter for SpecDown.
---Converts semantic elements to ABNT-specific OOXML.
---
---Features:
---  - Converts RawBlock("specdown", "page-break") to OOXML page break
---  - Converts RawBlock("specdown", "vertical-space:NNNN") to OOXML spacing (twips)
---  - Converts semantic Div classes to ABNT styles:
---    - cover-* -> Cover page styles (CoverInstitution, CoverTitle, etc.)
---    - titlepage-* -> Title page styles (TitlePageAuthor, TitlePageTitle, etc.)
---    - dedication -> Dedication style
---    - epigraph -> BlockText style (Epigraph)
---    - unnumbered-heading -> UnnumberedHeading style
---    - bottom-aligned -> Wraps content in table with vAlign=bottom
---
---@module models.abnt.filters.docx
---@author SpecDown Team
---@license MIT

local xml = require("infra.format.xml")

local M = {}

-- ============================================================================
-- OOXML DOM Construction Helpers
-- ============================================================================

---Build field code run sequence (begin, instrText, separate, placeholder, end).
---@param instr string Field instruction text (e.g., " SEQ Figure \\* ARABIC ")
---@param placeholder string|nil Placeholder text (default "1")
---@return table Array of xml nodes
local function build_field_code(instr, placeholder)
    placeholder = placeholder or "1"
    return {
        xml.node("w:r", {}, {xml.node("w:fldChar", {["w:fldCharType"] = "begin"})}),
        xml.node("w:r", {}, {xml.node("w:instrText", {["xml:space"] = "preserve"}, {xml.text(instr)})}),
        xml.node("w:r", {}, {xml.node("w:fldChar", {["w:fldCharType"] = "separate"})}),
        xml.node("w:r", {}, {xml.node("w:t", {}, {xml.text(placeholder)})}),
        xml.node("w:r", {}, {xml.node("w:fldChar", {["w:fldCharType"] = "end"})}),
    }
end

---Append all elements from an array into a target array.
---@param target table Target array
---@param source table Source array of elements to append
local function append_all(target, source)
    for _, v in ipairs(source) do
        table.insert(target, v)
    end
end

---Generate page break OOXML.
---@param break_type string|nil Break type: "next" (default), "odd", "even"
---@return string OOXML
local function ooxml_page_break(break_type)
    break_type = break_type or "next"

    if break_type == "odd" or break_type == "even" then
        -- Section break for odd/even page start
        -- Uses sectPr with type oddPage/evenPage
        -- MUST include full page properties for Word/LibreOffice to correctly insert blank pages
        -- A4: 11906 x 16838 twips; Margins: 3cm top, 2cm bottom/right, 3cm left
        -- Note: LibreOffice may not fully support oddPage, so this is best-effort
        local sect_type = break_type == "odd" and "oddPage" or "evenPage"
        -- OOXML element order per spec: type, pgSz, pgMar, cols, docGrid
        return xml.serialize_element(xml.node("w:p", {}, {
            xml.node("w:pPr", {}, {
                xml.node("w:sectPr", {}, {
                    xml.node("w:type", {["w:val"] = sect_type}),
                    xml.node("w:pgSz", {["w:w"] = "11906", ["w:h"] = "16838", ["w:orient"] = "portrait"}),
                    xml.node("w:pgMar", {
                        ["w:top"] = "1701", ["w:right"] = "1134", ["w:bottom"] = "1134",
                        ["w:left"] = "1701", ["w:header"] = "709", ["w:footer"] = "709",
                        ["w:gutter"] = "0",
                    }),
                    xml.node("w:cols", {["w:space"] = "708"}),
                    xml.node("w:docGrid", {["w:linePitch"] = "360"}),
                })
            })
        }))
    else
        -- Regular page break with zero spacing
        -- Include pPr to prevent default paragraph spacing from affecting layout
        return xml.serialize_element(xml.node("w:p", {}, {
            xml.node("w:pPr", {}, {
                xml.node("w:spacing", {
                    ["w:before"] = "0",
                    ["w:after"] = "0",
                    ["w:line"] = "240",
                    ["w:lineRule"] = "auto",
                })
            }),
            xml.node("w:r", {}, {
                xml.node("w:br", {["w:type"] = "page"})
            })
        }))
    end
end

---Generate vertical space OOXML.
---@param twips number Spacing in twips
---@return string OOXML
local function ooxml_vertical_space(twips)
    return xml.serialize_element(xml.node("w:p", {}, {
        xml.node("w:pPr", {}, {
            xml.node("w:spacing", {["w:before"] = tostring(twips)})
        })
    }))
end

-- A4 dimensions in twips for positioned floats
local A4_WIDTH = 11906
local A4_HEIGHT = 16838

-- Page margins in twips (matching preset.lua)
local MARGIN_TOP = 1701    -- 3cm
local MARGIN_BOTTOM = 1134 -- 2cm

---Generate OOXML paragraph with absolute positioning from page bottom.
---Uses w:framePr to position content at a fixed distance from page bottom.
---@param twips_from_bottom number Distance from bottom margin in twips
---@return string OOXML paragraph with frame positioning
local function ooxml_position_from_bottom(twips_from_bottom)
    -- Calculate position from page top
    -- position = page_height - bottom_margin - distance_from_bottom
    local position_from_top = A4_HEIGHT - MARGIN_BOTTOM - twips_from_bottom
    return xml.serialize_element(xml.node("w:p", {}, {
        xml.node("w:pPr", {}, {
            xml.node("w:framePr", {
                ["w:vAnchor"] = "page",
                ["w:hAnchor"] = "margin",
                ["w:xAlign"] = "center",
                ["w:y"] = tostring(position_from_top),
                ["w:wrap"] = "none",
            }),
            xml.node("w:jc", {["w:val"] = "center"}),
        })
    }))
end

---Generate OOXML paragraph with absolute positioning from page top.
---Uses w:framePr to position content at a fixed distance from page top.
---@param twips_from_top number Distance from top margin in twips
---@return string OOXML paragraph with frame positioning
local function ooxml_position_from_top(twips_from_top)
    -- Position from page top = top_margin + offset
    local position_from_page_top = MARGIN_TOP + twips_from_top
    return xml.serialize_element(xml.node("w:p", {}, {
        xml.node("w:pPr", {}, {
            xml.node("w:framePr", {
                ["w:vAnchor"] = "page",
                ["w:hAnchor"] = "margin",
                ["w:xAlign"] = "center",
                ["w:y"] = tostring(position_from_page_top),
                ["w:wrap"] = "none",
            }),
            xml.node("w:jc", {["w:val"] = "center"}),
        })
    }))
end

---Generate OOXML for section break with orientation change.
---Used for position="p" landscape pages.
---@param orientation string "portrait" or "landscape"
---@return string OOXML section break paragraph
local function ooxml_section_break_orientation(orientation)
    local w, h
    local pgSz_attrs
    if orientation == "landscape" then
        w = A4_HEIGHT
        h = A4_WIDTH
        pgSz_attrs = {["w:w"] = tostring(w), ["w:h"] = tostring(h), ["w:orient"] = "landscape"}
    else
        w = A4_WIDTH
        h = A4_HEIGHT
        pgSz_attrs = {["w:w"] = tostring(w), ["w:h"] = tostring(h)}
    end

    -- Include marker comment for postprocessor to replace with full sectPr including headers
    -- The postprocessor will inject headerReference, pgMar, etc. to preserve page numbers
    local sectPr_xml = xml.serialize_element(xml.node("w:p", {}, {
        xml.node("w:pPr", {}, {
            xml.node("w:sectPr", {}, {
                xml.node("w:pgSz", pgSz_attrs),
                xml.node("w:pgNumType", {["w:fmt"] = "decimal"}),
                xml.node("w:type", {["w:val"] = "nextPage"}),
            })
        })
    }))
    -- Prepend marker comment for postprocessor
    return string.format("<!-- specdown:sectPr:%s -->", orientation) .. sectPr_xml
end

---Generate styled paragraph OOXML.
---@param text string Text content
---@param style string Style ID
---@return string OOXML
local function ooxml_styled_para(text, style)
    return xml.serialize_element(xml.node("w:p", {}, {
        xml.node("w:pPr", {}, {
            xml.node("w:pStyle", {["w:val"] = style})
        }),
        xml.node("w:r", {}, {
            xml.node("w:t", {}, {xml.text(text)})
        })
    }))
end

---Generate styled paragraph with absolute positioning from page bottom.
---Uses w:framePr to position content at a fixed distance from page bottom.
---@param text string The text content
---@param style string The paragraph style name
---@param twips_from_bottom number Distance from bottom margin in twips
---@return string OOXML
local function ooxml_styled_para_positioned(text, style, twips_from_bottom)
    -- Calculate position from page top
    -- position = page_height - bottom_margin - distance_from_bottom
    local position_from_top = A4_HEIGHT - MARGIN_BOTTOM - twips_from_bottom
    return xml.serialize_element(xml.node("w:p", {}, {
        xml.node("w:pPr", {}, {
            xml.node("w:pStyle", {["w:val"] = style}),
            xml.node("w:framePr", {
                ["w:vAnchor"] = "page",
                ["w:hAnchor"] = "margin",
                ["w:xAlign"] = "center",
                ["w:y"] = tostring(position_from_top),
                ["w:wrap"] = "none",
            }),
        }),
        xml.node("w:r", {}, {
            xml.node("w:t", {}, {xml.text(text)})
        })
    }))
end

---Generate table wrapper start for vertical alignment (vAlign workaround).
---NOTE: sectPr vAlign doesn't work in LibreOffice/OnlyOffice/Google Docs.
---This uses a full-height table cell with vAlign=bottom as workaround.
---@param height number Table row height in twips (default: 13700)
---@return string OOXML table start
local function ooxml_table_valign_start(height)
    -- Default 13700 twips (~9.5 inches) for ABNT A4 page
    -- Content area is ~14003 twips (with 30mm top, 20mm bottom margins)
    -- Leave ~300 twips for page break paragraph overhead
    height = height or 13700

    -- Build border children for table borders (all nil)
    local tbl_border_names = {"w:top", "w:left", "w:bottom", "w:right", "w:insideH", "w:insideV"}
    local tbl_border_children = {}
    for _, bname in ipairs(tbl_border_names) do
        table.insert(tbl_border_children, xml.node(bname, {["w:val"] = "nil"}))
    end

    -- Build border children for cell borders (all nil)
    local cell_border_names = {"w:top", "w:left", "w:bottom", "w:right"}
    local cell_border_children = {}
    for _, bname in ipairs(cell_border_names) do
        table.insert(cell_border_children, xml.node(bname, {["w:val"] = "nil"}))
    end

    -- This function returns PARTIAL XML (opening tags only).
    -- The matching ooxml_table_valign_end() closes the tags.
    -- We build the full structure but serialize only the opening portion.
    -- To maintain the open/close pattern, we use string concatenation of serialized fragments.
    local tblPr = xml.serialize_element(xml.node("w:tblPr", {}, {
        xml.node("w:tblW", {["w:w"] = "5000", ["w:type"] = "pct"}),
        xml.node("w:tblBorders", {}, tbl_border_children),
        xml.node("w:tblCellMar", {}, {
            xml.node("w:top", {["w:type"] = "dxa", ["w:w"] = "57"}),
            xml.node("w:left", {["w:type"] = "dxa", ["w:w"] = "108"}),
            xml.node("w:bottom", {["w:type"] = "dxa", ["w:w"] = "57"}),
            xml.node("w:right", {["w:type"] = "dxa", ["w:w"] = "108"}),
        }),
    }))
    local trPr = xml.serialize_element(xml.node("w:trPr", {}, {
        xml.node("w:trHeight", {["w:val"] = tostring(height), ["w:hRule"] = "exact"}),
    }))
    local tcPr = xml.serialize_element(xml.node("w:tcPr", {}, {
        xml.node("w:tcW", {["w:w"] = "5000", ["w:type"] = "pct"}),
        xml.node("w:vAlign", {["w:val"] = "bottom"}),
        xml.node("w:tcBorders", {}, cell_border_children),
    }))

    return "<w:tbl>" .. tblPr .. "<w:tr>" .. trPr .. "<w:tc>" .. tcPr
end

---Close vertical alignment table.
---@return string OOXML table end tags
local function ooxml_table_valign_end()
    return '</w:tc></w:tr></w:tbl>'
end

-- ============================================================================
-- Semantic Class Mappings
-- ============================================================================

---Map of semantic class names to ABNT styles.
---uppercase = true means text will be uppercased before rendering.
local SEMANTIC_CLASS_MAP = {
    -- Cover page elements
    -- position_from_bottom: absolute position in twips from bottom margin
    ["cover-institution"] = { style = "CoverInstitution", uppercase = true },
    ["cover-department"]  = { style = "CoverDepartment", uppercase = false },
    ["cover-title"]       = { style = "CoverTitle", uppercase = true },
    ["cover-subtitle"]    = { style = "CoverSubtitle", uppercase = false },
    ["cover-author"]      = { style = "CoverAuthor", uppercase = false },
    ["cover-nature"]      = { style = "CoverNature", uppercase = false },
    ["cover-advisor"]     = { style = "CoverAdvisor", uppercase = false },
    -- Position city at ~0.76 inches from bottom (1100 twips)
    ["cover-location"]    = { style = "CoverLocation", uppercase = false, position_from_bottom = 1100 },
    -- Position year at ~0.42 inches from bottom (600 twips)
    ["cover-year"]        = { style = "CoverYear", uppercase = false, position_from_bottom = 600 },

    -- Title page elements
    ["titlepage-author"]      = { style = "TitlePageAuthor", uppercase = false },
    ["titlepage-title"]       = { style = "TitlePageTitle", uppercase = true },
    ["titlepage-subtitle"]    = { style = "TitlePageSubtitle", uppercase = false },
    ["titlepage-nature"]      = { style = "TitlePageNature", uppercase = false },
    ["titlepage-institution"] = { style = "TitlePageInstitution", uppercase = false },
    ["titlepage-advisor"]     = { style = "TitlePageAdvisor", uppercase = false },
    -- Position city at ~0.76 inches from bottom (1100 twips) - same as cover
    ["titlepage-location"]    = { style = "TitlePageLocation", uppercase = false, position_from_bottom = 1100 },
    -- Position year at ~0.42 inches from bottom (600 twips) - same as cover
    ["titlepage-year"]        = { style = "TitlePageYear", uppercase = false, position_from_bottom = 600 },

    -- Pre-textual elements
    ["dedication"]         = { style = "Dedication", uppercase = false },
    ["epigraph"]           = { style = "Epigraph", uppercase = false },
    ["unnumbered-heading"] = { style = "UnnumberedHeading", uppercase = false },
    ["toc-heading"]        = { style = "TOCHeading", uppercase = false },
}

-- ============================================================================
-- Helper Functions
-- ============================================================================

---Get content from an element, handling both Pandoc objects (.content) and raw tables (.c).
---@param elem table Pandoc element or raw JSON table
---@return table|nil content The content array or nil
local function get_content(elem)
    if elem.content then
        return elem.content  -- Pandoc object accessor
    elseif elem.c then
        -- Raw table from pandoc.json.decode
        -- Div/Span/etc have c = [Attr, content], Para/Plain have c = [inlines]
        if type(elem.c) == "table" then
            -- Check if first element is an attr tuple [id, classes, attrs]
            local first = elem.c[1]
            if type(first) == "table" and type(first[1]) == "string" and type(first[2]) == "table" then
                -- It's [Attr, content], return content (second element)
                return elem.c[2]
            else
                -- It's just [inlines/blocks]
                return elem.c
            end
        end
    end
    return nil
end

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
            -- Try to get nested content (Span, Emph, Strong, Link, etc.)
            local nested = get_content(inline)
            if nested then
                table.insert(parts, extract_text(nested))
            end
        end
    end
    return table.concat(parts)
end

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
            -- Handle blockquotes (for epigraph quotes)
            -- BlockQuote.content is a Blocks list in Pandoc
            -- Note: with commonmark_x+sourcepos, blocks may be wrapped in Divs
            local bq_content = block.content
            if bq_content then
                for _, inner in ipairs(bq_content) do
                    if inner.t == "Para" or inner.t == "Plain" then
                        local inner_content = get_content(inner)
                        if inner_content then
                            table.insert(parts, extract_text(inner_content))
                        end
                    elseif inner.t == "Div" then
                        -- sourcepos wraps blocks in Divs - extract from nested
                        local nested_text = extract_div_text(inner)
                        if #nested_text > 0 then
                            table.insert(parts, nested_text)
                        end
                    end
                end
            end
        elseif block.t == "Div" then
            -- Recursively extract from nested divs
            local nested_text = extract_div_text(block)
            if #nested_text > 0 then
                table.insert(parts, nested_text)
            end
        end
    end
    return table.concat(parts, "\n")
end

local function parse_marker(text)
    local marker_type, value = text:match("^([^:]+):?(.*)$")
    return marker_type, (value ~= "" and value or nil)
end

---Generate OOXML for bookmark as a zero-content paragraph.
---Pandoc's DOCX writer drops standalone bookmarkStart/End elements,
---so we wrap both in a single empty paragraph to ensure they survive.
---The bookmark is a point bookmark (start+end at same location),
---which is sufficient for PAGEREF (page number lookup) and hyperlink anchors.
---@param bm_id number Bookmark ID
---@param bm_name string Bookmark name
---@return string OOXML paragraph containing bookmark
local function ooxml_bookmark_paragraph(bm_id, bm_name)
    return xml.serialize_element(xml.node("w:p", {}, {
        xml.node("w:pPr", {}, {
            xml.node("w:spacing", {["w:before"] = "0", ["w:after"] = "0", ["w:line"] = "20", ["w:lineRule"] = "exact"}),
            xml.node("w:rPr", {}, {
                xml.node("w:sz", {["w:val"] = "2"}),
            }),
        }),
        xml.node("w:bookmarkStart", {
            ["w:id"] = tostring(bm_id),
            ["w:name"] = bm_name,
        }),
        xml.node("w:bookmarkEnd", {
            ["w:id"] = tostring(bm_id),
        }),
    }))
end

---Generate OOXML caption paragraph with SEQ field.
---@param prefix string Caption prefix (e.g., "Figura", "Tabela")
---@param seq_name string SEQ field name
---@param separator string Separator after number (e.g., ":", "-")
---@param caption string Caption text
---@param style string Paragraph style
---@param keep_with_next boolean|nil If true, adds keepNext to prevent orphaning
---@return string OOXML caption paragraph
local function ooxml_caption(prefix, seq_name, separator, caption, style, keep_with_next)
    local pPr_children = {
        xml.node("w:pStyle", {["w:val"] = style}),
    }
    if keep_with_next then
        table.insert(pPr_children, xml.node("w:keepNext"))
    end

    local children = {
        xml.node("w:pPr", {}, pPr_children),
        -- Prefix run (e.g., "Figura ")
        xml.node("w:r", {}, {
            xml.node("w:t", {["xml:space"] = "preserve"}, {xml.text(prefix .. " ")}),
        }),
    }

    -- SEQ field code runs
    append_all(children, build_field_code(" SEQ " .. seq_name .. " \\* ARABIC "))

    -- Separator and caption text
    table.insert(children, xml.node("w:r", {}, {
        xml.node("w:t", {["xml:space"] = "preserve"}, {xml.text(" " .. separator .. " " .. caption)}),
    }))

    return xml.serialize_element(xml.node("w:p", {}, children))
end

---Generate OOXML for numbered equation using tab-stop layout.
---Uses a single paragraph with center tab (equation) and right tab (number).
---This is the traditional academic approach - no table constraints.
---@param omml string OMML math content
---@param seq_name string SEQ field name
---@param number string|number Equation number
---@param identifier string|nil Bookmark identifier
---@return string OOXML for numbered equation
local function ooxml_numbered_equation(omml, seq_name, number, identifier)
    local bookmark_start_xml = ""
    local bookmark_end_xml = ""

    if identifier and identifier ~= "" then
        local bm_id = 0
        for i = 1, #identifier do
            bm_id = (bm_id * 31 + identifier:byte(i)) % 100000
        end
        bm_id = bm_id + 1
        bookmark_start_xml = xml.serialize_element(xml.node("w:bookmarkStart", {
            ["w:id"] = tostring(bm_id),
            ["w:name"] = identifier,
        }))
        bookmark_end_xml = xml.serialize_element(xml.node("w:bookmarkEnd", {
            ["w:id"] = tostring(bm_id),
        }))
    end

    -- Tab-stop approach: center tab at ~50% (4680 twips), right tab at 100% (9360 twips)
    -- Standard US Letter/A4 text width is ~6.5" = 9360 twips
    -- Equation centered via center tab, number right-aligned via right tab
    local children = {
        xml.node("w:pPr", {}, {
            xml.node("w:tabs", {}, {
                xml.node("w:tab", {["w:val"] = "center", ["w:pos"] = "4680"}),
                xml.node("w:tab", {["w:val"] = "right", ["w:pos"] = "9360"}),
            }),
        }),
        -- Tab to center position
        xml.node("w:r", {}, {xml.node("w:tab")}),
        -- Pre-formed OMML content
        xml.raw(omml),
        -- Tab to right position
        xml.node("w:r", {}, {xml.node("w:tab")}),
        -- Bookmark start (pre-formed OOXML, may be empty)
        xml.raw(bookmark_start_xml),
        -- Opening parenthesis
        xml.node("w:r", {}, {xml.node("w:t", {}, {xml.text("(")})}),
    }

    -- SEQ field code runs
    append_all(children, build_field_code(
        " SEQ " .. seq_name .. " \\* ARABIC ",
        tostring(number or "1")
    ))

    -- Closing parenthesis and bookmark end
    table.insert(children, xml.node("w:r", {}, {xml.node("w:t", {}, {xml.text(")")})}))
    table.insert(children, xml.raw(bookmark_end_xml))

    return xml.serialize_element(xml.node("w:p", {}, children))
end

---Get attribute value from Div.
---@param div pandoc.Div The div
---@param attr_name string Attribute name
---@return string|nil Attribute value
local function get_attr(div, attr_name)
    if div.attr and div.attr.attributes then
        return div.attr.attributes[attr_name]
    end
    return nil
end

local function has_class(div, class_name)
    for _, c in ipairs(div.classes or {}) do
        if c == class_name then return true end
    end
    return false
end

-- ============================================================================
-- Block Handlers
-- ============================================================================

local function convert_specdown_block(block, log)
    local text = block.text

    -- Handle bookmark-start:ID:NAME
    -- Combines start+end into a single paragraph (Pandoc drops standalone bookmark elements)
    local bm_id, bm_name = text:match("^bookmark%-start:(%d+):(.+)$")
    if bm_id and bm_name then
        return pandoc.RawBlock("openxml", ooxml_bookmark_paragraph(tonumber(bm_id), bm_name))
    end

    -- Handle bookmark-end:ID (already combined with bookmark-start above)
    local end_id = text:match("^bookmark%-end:(%d+)$")
    if end_id then
        return {}  -- Remove - handled in bookmark-start
    end

    -- Handle math-omml:OMML (for DOCX output)
    local omml = text:match("^math%-omml:(.+)$")
    if omml then
        return pandoc.RawBlock("openxml", omml)
    end

    -- Handle math-mathml:MATHML (skip for DOCX - we prefer OMML)
    if text:match("^math%-mathml:") then
        return {}  -- Remove - DOCX uses OMML
    end

    -- Parse simple markers
    local marker_type, value = parse_marker(text)

    if marker_type == "page-break" then
        -- value can be "odd", "even", or nil (default "next")
        return pandoc.RawBlock("openxml", ooxml_page_break(value))
    elseif marker_type == "vertical-space" then
        local twips = tonumber(value) or 1440
        return pandoc.RawBlock("openxml", ooxml_vertical_space(twips))
    elseif marker_type == "position-from-bottom" then
        -- Absolute position from page bottom (for city/year on cover)
        local twips = tonumber(value) or 1440
        return pandoc.RawBlock("openxml", ooxml_position_from_bottom(twips))
    elseif marker_type == "position-from-top" then
        -- Absolute position from page top (for title on cover)
        local twips = tonumber(value) or 4320
        return pandoc.RawBlock("openxml", ooxml_position_from_top(twips))
    elseif marker_type == "section-break-before" then
        -- Section break with orientation for position="p"
        local orientation = value or "portrait"
        return pandoc.RawBlock("openxml", ooxml_section_break_orientation(orientation))
    elseif marker_type == "section-break-after" then
        -- Section break back to portrait after float page
        local orientation = value or "portrait"
        return pandoc.RawBlock("openxml", ooxml_section_break_orientation(orientation))
    elseif marker_type == "float-position-start" then
        -- Pass through to postprocessor as OOXML comment marker
        return pandoc.RawBlock("openxml",
            string.format('<!-- specdown:float-position-start:%s -->', value or "h:FIGURE"))
    elseif marker_type == "float-position-end" then
        -- End marker for postprocessor
        return pandoc.RawBlock("openxml", '<!-- specdown:float-position-end -->')
    else
        if log then log.debug('[FILTER/DOCX/ABNT] Unknown marker: %s', text) end
        return {}  -- Remove unknown markers
    end
end

---UTF-8 aware uppercase function.
---Uses pandoc.text.upper() if available, falls back to string.upper().
---@param text string Text to uppercase
---@return string Uppercased text
local function utf8_upper(text)
    -- pandoc is a global when running as Pandoc filter
    local pandoc_global = rawget(_G, "pandoc")
    if pandoc_global and pandoc_global.text and pandoc_global.text.upper then
        return pandoc_global.text.upper(text)
    end
    return text:upper()
end

---Convert styled semantic div to OOXML.
---@param div table Pandoc Div
---@param log table|nil Logger
---@return table|nil RawBlock or nil
local function convert_styled_div(div, log)
    for _, class in ipairs(div.classes) do
        local mapping = SEMANTIC_CLASS_MAP[class]
        if mapping then
            local text = extract_div_text(div)
            if log then
                log.debug('[FILTER/DOCX/ABNT] %s -> %s', class, mapping.style)
            end
            if mapping.uppercase then
                text = utf8_upper(text)
            end
            -- Use positioned version if position_from_bottom is specified
            if mapping.position_from_bottom then
                return pandoc.RawBlock("openxml",
                    ooxml_styled_para_positioned(text, mapping.style, mapping.position_from_bottom))
            else
                return pandoc.RawBlock("openxml", ooxml_styled_para(text, mapping.style))
            end
        end
    end
    return nil
end

---Convert speccompiler-caption Div to OOXML.
---@param div pandoc.Div The caption div
---@return pandoc.RawBlock OOXML caption
local function convert_caption_div(div)
    local seq_name = get_attr(div, "seq-name") or "Figure"
    local prefix = get_attr(div, "prefix") or "Figure"
    local separator = get_attr(div, "separator") or ":"
    local style = get_attr(div, "style") or "Caption"

    -- Extract caption text from Div content
    local caption = pandoc.utils.stringify(div.content)

    -- ABNT: captions are above floats, so use keepNext to prevent orphaning
    return pandoc.RawBlock("openxml", ooxml_caption(prefix, seq_name, separator, caption, style, true))
end

---Convert speccompiler-numbered-equation Div to OOXML.
---@param div pandoc.Div The equation div
---@return pandoc.RawBlock|nil OOXML numbered equation
local function convert_equation_div(div)
    local seq_name = get_attr(div, "seq-name") or "Equation"
    local number = get_attr(div, "number") or "1"
    local identifier = get_attr(div, "identifier") or ""

    -- Extract OMML from nested RawBlock
    -- Note: RawBlock handler runs BEFORE Div handler in Pandoc filters.
    -- So the math-omml:... block may already be converted to openxml format.
    local omml = ""
    for _, block in ipairs(div.content) do
        if block.t == "RawBlock" then
            if block.format == "specdown" then
                -- Original format - extract OMML content after prefix
                local content = block.text:match("^math%-omml:(.+)$")
                if content then
                    omml = content
                    break
                end
            elseif block.format == "openxml" then
                -- Already converted by RawBlock handler - use directly if it's OMML
                if block.text:match("^<m:oMath") then
                    omml = block.text
                    break
                end
            end
        end
    end

    if omml == "" then
        return {}  -- No math content - remove
    end

    return pandoc.RawBlock("openxml", ooxml_numbered_equation(omml, seq_name, number, identifier))
end

---Convert speccompiler-table Div (unwrap content).
---@param div pandoc.Div The table div
---@return table Content blocks
local function convert_table_div(div)
    return div.content
end

---Convert speccompiler-positioned-float Div.
---Wraps content with position markers for postprocessor to convert to anchored OOXML.
---@param div pandoc.Div The positioned float div
---@return table Content blocks with position markers
local function convert_positioned_float_div(div)
    local position = get_attr(div, "data-position") or "h"
    local orientation = get_attr(div, "data-orientation")
    local float_type = get_attr(div, "data-float-type") or "FIGURE"

    local result = {}

    -- For position="p" (isolated page), add section breaks to create isolated page
    -- OOXML sectPr applies to content BEFORE it, so we need:
    -- 1. Portrait sectPr to close preceding section (before the float)
    -- 2. Float content
    -- 3. Target orientation sectPr to make the float page have that orientation (after the float)
    -- The content after will be in a new section whose properties come from the next sectPr in the document.
    if position == "p" then
        -- Close the preceding section as portrait
        table.insert(result, pandoc.RawBlock("openxml", ooxml_section_break_orientation("portrait")))
    end

    -- Add marker indicating float position for postprocessor (directly as OOXML comment)
    table.insert(result, pandoc.RawBlock("openxml",
        string.format('<!-- specdown:float-position-start:%s:%s -->', position, float_type)))

    -- Include the float content
    for _, block in ipairs(div.content) do
        table.insert(result, block)
    end

    -- End position marker (directly as OOXML comment)
    table.insert(result, pandoc.RawBlock("openxml", '<!-- specdown:float-position-end -->'))

    -- For position="p", add section break to make the float section have target orientation
    -- Note: We only add ONE sectPr here (not two) to avoid creating an empty page.
    -- The content after the float will be in a new section whose properties are
    -- determined by the next sectPr in the document flow (or the final document sectPr).
    if position == "p" then
        local orient = orientation or "portrait"
        -- Make this float section have the target orientation
        table.insert(result, pandoc.RawBlock("openxml", ooxml_section_break_orientation(orient)))
    end

    return result
end

---Convert bottom-aligned container div.
---Wraps child content in a table with vAlign=bottom.
---@param div table Pandoc Div with "bottom-aligned" class
---@param log table|nil Logger
---@return table Array of blocks
local function convert_bottom_aligned_div(div, log)
    if log then
        log.debug('[FILTER/DOCX/ABNT] Processing bottom-aligned container')
    end

    local blocks = {}

    -- Start table wrapper
    table.insert(blocks, pandoc.RawBlock("openxml", ooxml_table_valign_start()))

    -- Process child divs - convert styled ones to OOXML
    for _, child in ipairs(div.content) do
        if child.t == "Div" then
            local converted = convert_styled_div(child, log)
            if converted then
                table.insert(blocks, converted)
            else
                -- Keep non-styled divs as-is (will be processed by Pandoc)
                table.insert(blocks, child)
            end
        else
            table.insert(blocks, child)
        end
    end

    -- End table wrapper
    table.insert(blocks, pandoc.RawBlock("openxml", ooxml_table_valign_end()))

    return blocks
end

-- ============================================================================
-- Public API
-- ============================================================================

function M.apply(doc, config, log)
    -- NOTE: title/author/date metadata suppression is now handled in assembler.lua

    return doc:walk({
        RawBlock = function(block)
            if block.format == "specdown" or block.format == "speccompiler" then
                return convert_specdown_block(block, log)
            end
            return block
        end,

        Div = function(div)
            -- Handle specdown special Divs first
            if has_class(div, "speccompiler-caption") then
                return convert_caption_div(div)
            elseif has_class(div, "speccompiler-numbered-equation") then
                return convert_equation_div(div)
            elseif has_class(div, "speccompiler-table") then
                return convert_table_div(div)
            elseif has_class(div, "speccompiler-positioned-float") then
                return convert_positioned_float_div(div)
            end

            -- Handle bottom-aligned container (before styled divs)
            if has_class(div, "bottom-aligned") then
                return convert_bottom_aligned_div(div, log)
            end

            -- Handle styled divs
            local converted = convert_styled_div(div, log)
            return converted or div
        end,

        -- Replace .ext placeholder with .docx in cross-document links
        Link = function(link)
            if link.target then
                link.target = link.target:gsub("%.ext#", ".docx#")
                link.target = link.target:gsub("%.ext$", ".docx")
            end
            return link
        end
    })
end

-- ============================================================================
-- Native Pandoc Filter Table (for --lua-filter usage)
-- ============================================================================
-- When used via pandoc --lua-filter, FORMAT is set and we return filter table.
-- When used via Writer.load_filter().apply(), we return M module.

-- FORMAT is only set when running as a native Pandoc filter
if FORMAT then
    return {{
        RawBlock = function(block)
            if block.format == "specdown" or block.format == "speccompiler" then
                return convert_specdown_block(block, nil)
            end
            return block
        end,

        RawInline = function(inline)
            if inline.format == "specdown" or inline.format == "speccompiler" then
                local text = inline.text
                -- Handle inline-math-omml
                local inline_omml = text:match("^inline%-math%-omml:(.+)$")
                if inline_omml then
                    return pandoc.RawInline("openxml", inline_omml)
                end
                -- Skip inline-math-mathml for DOCX
                if text:match("^inline%-math%-mathml:") then
                    return {}
                end
                -- Handle view content
                local view_name, view_content = text:match("^view:([^:]+):(.+)$")
                if view_name and view_content then
                    return pandoc.RawInline("openxml", view_content)
                end
                return {}
            end
            return inline
        end,

        Div = function(div)
            if has_class(div, "speccompiler-caption") then
                return convert_caption_div(div)
            elseif has_class(div, "speccompiler-numbered-equation") then
                return convert_equation_div(div)
            elseif has_class(div, "speccompiler-table") then
                return convert_table_div(div)
            elseif has_class(div, "speccompiler-positioned-float") then
                return convert_positioned_float_div(div)
            elseif has_class(div, "bottom-aligned") then
                return convert_bottom_aligned_div(div, nil)
            end
            local converted = convert_styled_div(div, nil)
            return converted or div
        end,

        Link = function(link)
            if link.target then
                link.target = link.target:gsub("%.ext#", ".docx#")
                link.target = link.target:gsub("%.ext$", ".docx")
            end
            return link
        end
    }}
end

return M
