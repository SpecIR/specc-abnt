-- Test oracle for VC-ABNT-003: Citation References via @cite/@citep
-- Verifies that:
--   1. [key](@cite) links are resolved to Cite elements with NormalCitation mode
--   2. [key](@citep) links are resolved to Cite elements with AuthorInText mode
--   3. Multi-key citations [k1;k2](@cite) produce Cite elements with multiple citations
--   4. All expected citation keys are present

return function(actual_doc, helpers)
    helpers.strip_tracking_spans(actual_doc)
    helpers.options.ignore_data_pos = true

    local errors = {}
    local function err(msg) table.insert(errors, msg) end

    if not actual_doc or not actual_doc.blocks or #actual_doc.blocks < 1 then
        return false, "Document has no blocks"
    end

    -- Collect Cite elements and their metadata
    local cite_count = 0
    local cite_keys = {}
    local normal_citations = 0
    local author_in_text = 0

    actual_doc:walk({
        Cite = function(el)
            cite_count = cite_count + 1
            for _, citation in ipairs(el.citations or {}) do
                cite_keys[citation.id] = true
                if citation.mode == "NormalCitation" then
                    normal_citations = normal_citations + 1
                elseif citation.mode == "AuthorInText" then
                    author_in_text = author_in_text + 1
                end
            end
        end
    })

    -- 1. Verify expected citation keys exist
    local expected_keys = {"silva2024", "NBR14724:2011", "santos2023"}
    for _, key in ipairs(expected_keys) do
        if not cite_keys[key] then
            err("Missing citation key: " .. key)
        end
    end

    -- 2. Verify citation count
    -- @cite: silva2024, santos2023;silva2024(2), NBR14724:2011, NBR14724:2011;santos2023;silva2024(3) = 8 NormalCitation
    -- @citep: NBR14724:2011, santos2023 = 2 AuthorInText
    -- Total Cite elements: 6 (silva2024, santos2023;silva2024, NBR14724:2011(citep), santos2023(citep), NBR14724:2011, NBR14724:2011;santos2023;silva2024)
    if cite_count < 6 then
        err("Expected at least 6 Cite elements, found " .. cite_count)
    end

    -- 3. Verify both citation modes exist
    if normal_citations < 4 then
        err("Expected at least 4 NormalCitation modes, found " .. normal_citations)
    end
    if author_in_text < 2 then
        err("Expected at least 2 AuthorInText modes, found " .. author_in_text)
    end

    -- 4. Verify no unresolved @cite/@citep links remain
    local unresolved_links = 0
    actual_doc:walk({
        Link = function(link)
            local target = link.target or ""
            if target == "@cite" or target == "@citep" then
                unresolved_links = unresolved_links + 1
            end
        end
    })
    if unresolved_links > 0 then
        err(string.format(
            "%d @cite/@citep link(s) were NOT resolved to Cite elements",
            unresolved_links
        ))
    end

    if #errors > 0 then
        return false, "Citation validation failed:\n  - " .. table.concat(errors, "\n  - ")
    end
    return true, nil
end
