-- Test oracle for VC-ABNT-007: @ section cross-references to ABNT textual chapters.
--
-- ABNT reclassifies chapters by title: "Introducao" -> INTRODUCTION,
-- "Desenvolvimento" -> DEVELOPMENT, "Conclusao" -> CONCLUSION. All extend
-- TEXTUAL -> SECTION, so an @-PID section reference (XREF_SEC, target_type_ref
-- = SECTION) must resolve to them through the extends chain, not only to
-- objects whose type is literally SECTION.
--
-- Test cases:
-- TC-01: [ABNT-sec1](@) -> Introducao        (target type INTRODUCTION)
-- TC-02: [ABNT-sec2](@) -> Desenvolvimento   (target type DEVELOPMENT)
-- TC-03: [ABNT-sec3](@) -> Conclusao         (target type CONCLUSION)
-- TC-04: [ABNT-sec2.1-extra](@) -> Subsecao  (target type SECTION, control)
-- TC-05: every resolved @ section link is type_ref = 'XREF_SEC' and not ambiguous

return function(actual_doc, helpers)
    if not actual_doc or #actual_doc.blocks < 1 then
        return false, "Pipeline produced no output"
    end

    local sqlite = require("lsqlite3")
    if not helpers.db_file then
        return false, "helpers.db_file not provided by runner"
    end

    local db = sqlite.open(helpers.db_file)
    if not db then
        return false, "Failed to open pipeline DB: " .. tostring(helpers.db_file)
    end

    local errors = {}
    local function err(msg) table.insert(errors, msg) end

    local relations = {}
    for row in db:nrows([[
        SELECT r.target_text, r.is_ambiguous, r.target_object_id,
               r.link_selector, r.type_ref,
               tobj.pid AS target_pid, tobj.type_ref AS target_type
        FROM spec_relations r
        LEFT JOIN spec_objects tobj ON r.target_object_id = tobj.id
        WHERE r.link_selector = '@'
        ORDER BY r.id
    ]]) do
        table.insert(relations, row)
    end

    local cases = {
        ["ABNT-sec1"]          = "INTRODUCTION",
        ["ABNT-sec2"]          = "DEVELOPMENT",
        ["ABNT-sec3"]          = "CONCLUSION",
        ["ABNT-sec2.1-extra"]  = "SECTION",
    }

    local seen = {}
    for _, r in ipairs(relations) do
        local want = cases[r.target_text]
        if want then
            seen[r.target_text] = true
            if not r.target_object_id then
                err(string.format("%s did not resolve (target_object_id is NULL)", r.target_text))
            else
                if r.target_pid ~= r.target_text then
                    err(string.format("%s resolved to wrong PID %s", r.target_text, tostring(r.target_pid)))
                end
                if r.target_type ~= want then
                    err(string.format("%s resolved to type %s, expected %s",
                        r.target_text, tostring(r.target_type), want))
                end
                if r.type_ref ~= "XREF_SEC" then
                    err(string.format("%s has relation type_ref %s, expected XREF_SEC",
                        r.target_text, tostring(r.type_ref)))
                end
                if r.is_ambiguous ~= 0 then
                    err(string.format("%s should NOT be ambiguous", r.target_text))
                end
            end
        end
    end

    for target in pairs(cases) do
        if not seen[target] then
            err("relation not found: " .. target)
        end
    end

    db:close()

    if #errors > 0 then
        return false, "Textual chapter xref tests failed (" .. #errors ..
            " errors):\n  - " .. table.concat(errors, "\n  - ")
    end
    return true, nil
end
