-- Test oracle for VC-ABNT-004: Appendix & Annex Heading Styles
-- Verifies that:
--   1. Appendix section exists and uses custom-style "AppendixHeading" (NOT Heading1)
--   2. Annex section exists and uses custom-style "AnnexHeading" (NOT Heading1)
--   3. Page breaks exist before appendix and annex sections

return function(actual_doc, helpers)
    helpers.strip_tracking_spans(actual_doc)
    helpers.options.ignore_data_pos = true

    local errors = {}
    local function err(msg) table.insert(errors, msg) end

    if not actual_doc or not actual_doc.blocks or #actual_doc.blocks < 1 then
        return false, "Document has no blocks"
    end

    -- Track what we find
    local found_appendix_element = false
    local found_annex_element = false
    local appendix_has_correct_style = false
    local annex_has_correct_style = false
    local appendix_has_wrong_style = false
    local annex_has_wrong_style = false
    local page_breaks_before_appendix = 0
    local page_breaks_before_annex = 0

    -- Walk position tracking: count page breaks as we go
    local page_break_counter = 0
    local passed_appendix = false

    -- Helper: check if element has a specific custom-style
    local function get_style(el)
        return (el.attr and el.attr.attributes and el.attr.attributes["custom-style"]) or ""
    end

    -- Helper: check if text matches appendix patterns
    local function is_appendix_text(text)
        local upper = text:upper()
        return upper:find("DADOS COMPLEMENTARES") ~= nil
    end

    -- Helper: check if text matches annex patterns
    local function is_annex_text(text)
        local upper = text:upper()
        return upper:find("NORMAS CONSULTADAS") ~= nil
    end

    actual_doc:walk({
        RawBlock = function(rb)
            local fmt = rb.format or ""
            local text = rb.text or ""
            if fmt == "speccompiler" and text:match("page%-break") then
                page_break_counter = page_break_counter + 1
            end
        end,

        -- Check Headers for appendix/annex content
        Header = function(h)
            local text = pandoc.utils.stringify(h)
            local style = get_style(h)

            -- Check for appendix (by style or by specific content text)
            if style == "AppendixHeading" or is_appendix_text(text) then
                found_appendix_element = true
                if style == "AppendixHeading" then
                    appendix_has_correct_style = true
                end
                if style == "Heading1" or style == "Heading 1" or style == "" then
                    appendix_has_wrong_style = true
                end
                if not passed_appendix then
                    page_breaks_before_appendix = page_break_counter
                    passed_appendix = true
                end
            end

            -- Check for annex (by style or by specific content text)
            if style == "AnnexHeading" or is_annex_text(text) then
                found_annex_element = true
                if style == "AnnexHeading" then
                    annex_has_correct_style = true
                end
                if style == "Heading1" or style == "Heading 1" or style == "" then
                    annex_has_wrong_style = true
                end
                page_breaks_before_annex = page_break_counter
            end
        end,

        -- Check Divs for appendix/annex content (correct rendering wraps in Divs)
        Div = function(div)
            local text = pandoc.utils.stringify(div)
            local style = get_style(div)

            -- Check for appendix (by style or by specific content text)
            if style == "AppendixHeading" or is_appendix_text(text) then
                found_appendix_element = true
                if style == "AppendixHeading" then
                    appendix_has_correct_style = true
                end
                if not passed_appendix then
                    page_breaks_before_appendix = page_break_counter
                    passed_appendix = true
                end
            end

            -- Check for annex (by style or by specific content text)
            if style == "AnnexHeading" or is_annex_text(text) then
                found_annex_element = true
                if style == "AnnexHeading" then
                    annex_has_correct_style = true
                end
                page_breaks_before_annex = page_break_counter
            end
        end
    })

    -- 1. Verify appendix section exists
    if not found_appendix_element then
        err("No appendix section found (expected Div with custom-style=AppendixHeading or text matching DADOS COMPLEMENTARES)")
    end

    -- 2. Verify appendix uses AppendixHeading style
    if found_appendix_element and not appendix_has_correct_style then
        if appendix_has_wrong_style then
            err("Appendix heading uses Heading1 style instead of AppendixHeading - "
                .. "appendix sections must use custom-style=\"AppendixHeading\"")
        else
            err("Appendix heading does not have custom-style=\"AppendixHeading\" attribute")
        end
    end

    -- 3. Verify annex section exists
    if not found_annex_element then
        err("No annex section found (expected Div with custom-style=AnnexHeading or text matching NORMAS CONSULTADAS)")
    end

    -- 4. Verify annex uses AnnexHeading style
    if found_annex_element and not annex_has_correct_style then
        if annex_has_wrong_style then
            err("Annex heading uses Heading1 style instead of AnnexHeading - "
                .. "annex sections must use custom-style=\"AnnexHeading\"")
        else
            err("Annex heading does not have custom-style=\"AnnexHeading\" attribute")
        end
    end

    -- 5. Verify page breaks exist before appendix and annex sections
    if found_appendix_element and page_breaks_before_appendix < 1 then
        err("No page break found before appendix section")
    end
    if found_annex_element and page_breaks_before_annex < 1 then
        err("No page break found before annex section")
    end

    if #errors > 0 then
        return false, "Appendix/Annex style validation failed:\n  - " .. table.concat(errors, "\n  - ")
    end
    return true, nil
end
