-- Test oracle for VC-ABNT-001: Document Structure & Page Breaks
-- Verifies that:
--   1. Pre-textual elements have page-break markers between them
--   2. Cover page renders semantic Divs (cover-title, cover-author, etc.)
--   3. All major ABNT object types are present in the rendered output

return function(actual_doc, helpers)
    helpers.strip_tracking_spans(actual_doc)
    helpers.options.ignore_data_pos = true

    local errors = {}
    local function err(msg) table.insert(errors, msg) end

    if not actual_doc or not actual_doc.blocks or #actual_doc.blocks < 1 then
        return false, "Document has no blocks"
    end

    -- 1. Count page-break RawBlocks
    local page_breaks = 0
    local cover_divs = {}
    local header_ids = {}

    actual_doc:walk({
        RawBlock = function(rb)
            local fmt = rb.format or ""
            local text = rb.text or ""
            if fmt == "speccompiler" and text:match("page%-break") then
                page_breaks = page_breaks + 1
            end
        end,
        Header = function(h)
            if h.identifier and h.identifier ~= "" then
                table.insert(header_ids, h.identifier)
            end
        end,
        Div = function(div)
            local classes = div.classes or {}
            for _, c in ipairs(classes) do
                if c:match("^cover%-") or c:match("^titlepage%-") then
                    cover_divs[c] = true
                end
            end
        end
    })

    -- 2. Verify CAPA rendered semantic cover Divs
    if not next(cover_divs) then
        err("CAPA: no cover-* or titlepage-* semantic Divs found (spec attributes not resolved)")
    end

    -- 3. Verify textual sections exist (PIDs like INTRODUCTION-001, DEVELOPMENT-001, etc.)
    local expected_pids = {
        { pattern = "INTRODUCTION", label = "Introduction" },
        { pattern = "DEVELOPMENT",  label = "Development"  },
        { pattern = "CONCLUSION",   label = "Conclusion"   },
    }
    for _, expected in ipairs(expected_pids) do
        local found = false
        for _, id in ipairs(header_ids) do
            if id:upper():find(expected.pattern) then
                found = true
                break
            end
        end
        if not found then
            err("Missing section: " .. expected.label .. " (no header ID matching " .. expected.pattern .. ")")
        end
    end

    -- 4. Verify page breaks between elements
    -- Expected: capa(1) + dedicatoria(1) + resumo(1) + abstract(1)
    --         + introducao(1) + desenvolvimento(1) + conclusao(1) + referencias(1)
    if page_breaks < 5 then
        err(string.format("Expected at least 5 page-break markers, got %d", page_breaks))
    end

    -- 5. Verify document has substantial rendered content
    if #actual_doc.blocks < 10 then
        err(string.format("Expected at least 10 blocks in rendered doc, got %d", #actual_doc.blocks))
    end

    if #errors > 0 then
        return false, "Structure validation failed:\n  - " .. table.concat(errors, "\n  - ")
    end
    return true, nil
end
