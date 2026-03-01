-- Test oracle for VC-ABNT-005: Appendix & Annex ABNT Lettering
-- Verifies that:
--   1. Appendices use "APÊNDICE A – Title" format with letter numbering
--   2. Annexes use "ANEXO A – Title" format with letter numbering
--   3. Multiple appendices/annexes get sequential letters (A, B, ...)

return function(actual_doc, helpers)
    helpers.strip_tracking_spans(actual_doc)
    helpers.options.ignore_data_pos = true

    local errors = {}
    local function err(msg) table.insert(errors, msg) end

    if not actual_doc or not actual_doc.blocks or #actual_doc.blocks < 1 then
        return false, "Document has no blocks"
    end

    -- Collect appendix and annex headings in order
    local appendix_headings = {}
    local annex_headings = {}

    actual_doc:walk({
        Div = function(div)
            local style = (div.attr and div.attr.attributes
                and div.attr.attributes["custom-style"]) or ""
            local text = pandoc.utils.stringify(div)

            if style == "AppendixHeading" then
                appendix_headings[#appendix_headings + 1] = text
            elseif style == "AnnexHeading" then
                annex_headings[#annex_headings + 1] = text
            end
        end,
        Header = function(h)
            local style = (h.attr and h.attr.attributes
                and h.attr.attributes["custom-style"]) or ""
            local text = pandoc.utils.stringify(h)

            if style == "AppendixHeading" then
                appendix_headings[#appendix_headings + 1] = text
            elseif style == "AnnexHeading" then
                annex_headings[#annex_headings + 1] = text
            end
        end
    })

    -- 1. Verify we found exactly 2 appendices
    if #appendix_headings ~= 2 then
        err(string.format("Expected 2 AppendixHeading elements, found %d", #appendix_headings))
    end

    -- 2. Verify we found exactly 2 annexes
    if #annex_headings ~= 2 then
        err(string.format("Expected 2 AnnexHeading elements, found %d", #annex_headings))
    end

    -- Helper: case-insensitive plain find (handles Unicode properly)
    local function ifind(text, pattern)
        return text:find(pattern, 1, true) ~= nil
    end

    -- 3. Verify first appendix contains "APÊNDICE A" and user title
    if #appendix_headings >= 1 then
        local t = appendix_headings[1]
        if not (ifind(t, "APÊNDICE A") or ifind(t, "APENDICE A")) then
            err("First appendix heading should contain 'APÊNDICE A', got: " .. t)
        end
        if not ifind(t, "Primeiro") then
            err("First appendix heading should contain user title 'Primeiro', got: " .. t)
        end
    end

    -- 4. Verify second appendix contains "APÊNDICE B" and user title
    if #appendix_headings >= 2 then
        local t = appendix_headings[2]
        if not (ifind(t, "APÊNDICE B") or ifind(t, "APENDICE B")) then
            err("Second appendix heading should contain 'APÊNDICE B', got: " .. t)
        end
        if not ifind(t, "Segundo") then
            err("Second appendix heading should contain user title 'Segundo', got: " .. t)
        end
    end

    -- 5. Verify first annex contains "ANEXO A" and user title
    if #annex_headings >= 1 then
        local t = annex_headings[1]
        if not ifind(t, "ANEXO A") then
            err("First annex heading should contain 'ANEXO A', got: " .. t)
        end
        if not ifind(t, "Primeiro") then
            err("First annex heading should contain user title 'Primeiro', got: " .. t)
        end
    end

    -- 6. Verify second annex contains "ANEXO B" and user title
    if #annex_headings >= 2 then
        local t = annex_headings[2]
        if not ifind(t, "ANEXO B") then
            err("Second annex heading should contain 'ANEXO B', got: " .. t)
        end
        if not ifind(t, "Segundo") then
            err("Second annex heading should contain user title 'Segundo', got: " .. t)
        end
    end

    if #errors > 0 then
        return false, "Appendix/Annex lettering validation failed:\n  - " .. table.concat(errors, "\n  - ")
    end
    return true, nil
end
