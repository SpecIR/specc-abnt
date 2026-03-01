-- Test oracle for VC-ABNT-006: Dedication & Epigraph Content
-- Verifies that:
--   1. Dedication content is present in the AST (not blank)
--   2. Epigraph content is present in the AST (not blank)
--   3. Both are wrapped in appropriate container Divs

return function(actual_doc, helpers)
    helpers.strip_tracking_spans(actual_doc)
    helpers.options.ignore_data_pos = true

    local errors = {}
    local function err(msg) table.insert(errors, msg) end

    if not actual_doc or not actual_doc.blocks or #actual_doc.blocks < 1 then
        return false, "Document has no blocks"
    end

    -- Track what we find
    local found_dedication_div = false
    local found_epigraph_div = false
    local dedication_text = ""
    local epigraph_text = ""
    local found_bottom_aligned = false

    actual_doc:walk({
        Div = function(div)
            local classes = div.classes or {}
            local text = pandoc.utils.stringify(div)

            for _, c in ipairs(classes) do
                if c == "dedication" then
                    found_dedication_div = true
                    dedication_text = text
                elseif c == "epigraph" then
                    found_epigraph_div = true
                    epigraph_text = text
                elseif c == "bottom-aligned" then
                    found_bottom_aligned = true
                    -- Check if this bottom-aligned div contains dedication or epigraph
                    for _, inner_class in ipairs(classes) do
                        if inner_class == "dedication" then
                            found_dedication_div = true
                            dedication_text = text
                        elseif inner_class == "epigraph" then
                            found_epigraph_div = true
                            epigraph_text = text
                        end
                    end
                    -- Also check inner divs
                    div:walk({
                        Div = function(inner_div)
                            for _, ic in ipairs(inner_div.classes or {}) do
                                if ic == "dedication" then
                                    found_dedication_div = true
                                    dedication_text = pandoc.utils.stringify(inner_div)
                                elseif ic == "epigraph" then
                                    found_epigraph_div = true
                                    epigraph_text = pandoc.utils.stringify(inner_div)
                                end
                            end
                        end
                    })
                end
            end
        end
    })

    -- 1. Verify dedication div exists
    if not found_dedication_div then
        err("No Div with class 'dedication' found in AST")
    end

    -- 2. Verify dedication has content
    if found_dedication_div and (#dedication_text == 0 or not dedication_text:find("familia")) then
        err("Dedication div exists but does not contain expected text ('familia'), got: '"
            .. dedication_text:sub(1, 80) .. "'")
    end

    -- 3. Verify epigraph div exists
    if not found_epigraph_div then
        err("No Div with class 'epigraph' found in AST")
    end

    -- 4. Verify epigraph has content
    if found_epigraph_div and (#epigraph_text == 0 or not epigraph_text:find("persistencia")) then
        err("Epigraph div exists but does not contain expected text ('persistencia'), got: '"
            .. epigraph_text:sub(1, 80) .. "'")
    end

    -- 5. Verify bottom-aligned container is used
    if not found_bottom_aligned then
        err("No Div with class 'bottom-aligned' found — dedication/epigraph should use bottom alignment")
    end

    if #errors > 0 then
        return false, "Pre-textual content validation failed:\n  - " .. table.concat(errors, "\n  - ")
    end
    return true, nil
end
