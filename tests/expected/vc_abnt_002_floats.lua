-- Test oracle for VC-ABNT-002: LOF/LOT PAGEREF Anchors
-- Verifies that:
--   1. LOF and LOT generate PAGEREF fields with non-empty anchors
--   2. Every PAGEREF anchor has a matching bookmark in the document
--   3. Float captions appear in the rendered output

return function(actual_doc, helpers)
    helpers.strip_tracking_spans(actual_doc)
    helpers.options.ignore_data_pos = true

    local errors = {}
    local function err(msg) table.insert(errors, msg) end

    if not actual_doc or not actual_doc.blocks or #actual_doc.blocks < 1 then
        return false, "Document has no blocks"
    end

    -- Collect PAGEREF anchors and bookmark names from the AST
    local pageref_anchors = {}
    local bookmark_names = {}
    local empty_pagerefs = 0

    actual_doc:walk({
        RawBlock = function(rb)
            local fmt = rb.format or ""
            local text = rb.text or ""

            -- Collect PAGEREF anchors from OOXML LOF/LOT entries
            if fmt == "openxml" then
                for anchor in text:gmatch('PAGEREF%s+([^%s\\]+)') do
                    table.insert(pageref_anchors, anchor)
                    if anchor == "" or anchor == '""' then
                        empty_pagerefs = empty_pagerefs + 1
                    end
                end
            end

            -- Collect bookmark names from speccompiler markers
            -- (these become <w:bookmarkStart> in DOCX via the docx filter)
            if fmt == "speccompiler" then
                local bm_name = text:match("^bookmark%-start:%d+:(.+)$")
                if bm_name then
                    bookmark_names[bm_name] = true
                end
            end
        end
    })

    -- 1. LOF and LOT must generate PAGEREF entries
    if #pageref_anchors == 0 then
        err("No PAGEREF fields found in OOXML RawBlocks - LOF/LOT did not generate entries")
    end

    -- 2. No empty anchors (causes "Error: Reference source not found")
    if empty_pagerefs > 0 then
        err(string.format(
            "%d PAGEREF field(s) have empty anchors (causes 'Error: Reference source not found' in Word)",
            empty_pagerefs
        ))
    end

    -- 3. Expect at least 2 valid PAGEREFs (1 figure + 1 table from test doc)
    if #pageref_anchors - empty_pagerefs < 2 then
        err(string.format("Expected at least 2 valid PAGEREF entries, got %d",
            #pageref_anchors - empty_pagerefs))
    end

    -- 4. Every PAGEREF anchor must have a matching bookmark in the document
    -- This catches the real bug: LOF/LOT references point to anchors that
    -- don't exist as bookmarks, causing "Error: Reference source not found"
    local missing_bookmarks = {}
    for _, anchor in ipairs(pageref_anchors) do
        if anchor ~= "" and not bookmark_names[anchor] then
            table.insert(missing_bookmarks, anchor)
        end
    end
    if #missing_bookmarks > 0 then
        err(string.format(
            "%d PAGEREF anchor(s) have no matching bookmark: %s",
            #missing_bookmarks,
            table.concat(missing_bookmarks, ", ")
        ))
    end

    -- 5. Verify float captions appear in the document text
    local text = pandoc.utils.stringify(actual_doc)
    local expected_captions = {
        "Imagem de teste para LOF",
        "Tabela de teste para LOT",
    }
    for _, caption in ipairs(expected_captions) do
        if not text:find(caption, 1, true) then
            err("Missing float caption in output: " .. caption)
        end
    end

    if #errors > 0 then
        return false, "LOF/LOT PAGEREF validation failed:\n  - " .. table.concat(errors, "\n  - ")
    end
    return true, nil
end
