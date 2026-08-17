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
    local float_list_entries = 0
    local legacy_toc1_entries = 0
    local hyphen_separators = 0
    local en_dash_separators = 0

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
                for _ in text:gmatch('<w:pStyle w:val="FloatListEntry"') do
                    float_list_entries = float_list_entries + 1
                end
                for _ in text:gmatch('<w:pStyle w:val="TOC1"') do
                    legacy_toc1_entries = legacy_toc1_entries + 1
                end
                for _ in text:gmatch('Figura%s+%d+%s+%-%s+') do
                    hyphen_separators = hyphen_separators + 1
                end
                for _ in text:gmatch('Tabela%s+%d+%s+%-%s+') do
                    hyphen_separators = hyphen_separators + 1
                end
                for _ in text:gmatch('Figura%s+%d+%s+–%s+') do
                    en_dash_separators = en_dash_separators + 1
                end
                for _ in text:gmatch('Tabela%s+%d+%s+–%s+') do
                    en_dash_separators = en_dash_separators + 1
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

    -- 4. LOF/LOT use their own non-indented, non-bold paragraph style.  TOC1
    -- inherits heading formatting and Normal's first-line indent in ABNT.
    if float_list_entries ~= #pageref_anchors then
        err(string.format(
            "Expected every PAGEREF entry to use FloatListEntry, got %d of %d",
            float_list_entries, #pageref_anchors))
    end
    if legacy_toc1_entries > 0 then
        err(string.format("Found %d LOF/LOT entries still using TOC1", legacy_toc1_entries))
    end
    if hyphen_separators > 0 then
        err(string.format("Found %d LOF/LOT labels using hyphen instead of en dash", hyphen_separators))
    end
    if en_dash_separators ~= #pageref_anchors then
        err(string.format(
            "Expected every LOF/LOT label to use an en dash, got %d of %d",
            en_dash_separators, #pageref_anchors))
    end

    -- 5. Every PAGEREF anchor must have a matching bookmark in the document
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

    -- 6. Verify float captions appear in the document text
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
