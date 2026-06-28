-- Test oracle for VC-ABNT-008: section titles colliding with chapter types.
--
-- ABNT reclassifies chapters by title ("Introducao" -> INTRODUCTION,
-- "Conclusao"/"Consideracoes Finais" -> CONCLUSION). That implicit typing must
-- be LEVEL-AWARE: it applies only at the chapter heading level (H2). A section
-- (H3) whose title happens to match a chapter alias must stay SECTION, not be
-- promoted to a chapter type (which previously rendered it as a Heading1
-- chapter, corrupting numbering).
--
-- Guards:
--   H2 "Introducao"           -> INTRODUCTION  (chapter typing still works)
--   H2 "Conclusao"            -> CONCLUSION     (chapter typing still works)
--   H3 "Consideracoes Finais" -> NOT CONCLUSION (the regression)
--   H3 "Introducao"           -> NOT INTRODUCTION (the regression)

return function(actual_doc, helpers)
    if not actual_doc or #actual_doc.blocks < 1 then
        return false, "Pipeline produced no output"
    end

    local sqlite = require("lsqlite3")
    if not helpers.db_file then
        return false, "helpers.db_file not provided by runner"
    end

    local db = sqlite.open(helpers.db_file)
    local errors = {}
    local function err(msg) table.insert(errors, msg) end

    -- title (normalized) + level -> type_ref
    local function type_of(title, level)
        local t
        local stmt = db:prepare(
            "SELECT type_ref FROM spec_objects WHERE title_text = ? AND level = ? LIMIT 1")
        stmt:bind_values(title, level)
        if stmt:step() == sqlite.ROW then t = stmt:get_value(0) end
        stmt:finalize()
        return t
    end

    -- Chapter-level typing must still resolve (H2).
    if type_of("Introducao", 2) ~= "INTRODUCTION" then
        err("H2 'Introducao' should be INTRODUCTION, got " .. tostring(type_of("Introducao", 2)))
    end
    if type_of("Conclusao", 2) ~= "CONCLUSION" then
        err("H2 'Conclusao' should be CONCLUSION, got " .. tostring(type_of("Conclusao", 2)))
    end

    -- Section-level titles must NOT be promoted to chapter types (the bug).
    local cf = type_of("Consideracoes Finais", 3)
    if cf == "CONCLUSION" then
        err("H3 'Consideracoes Finais' was mis-typed as CONCLUSION (promoted to chapter)")
    end
    local intro3 = type_of("Introducao", 3)
    if intro3 == "INTRODUCTION" then
        err("H3 'Introducao' was mis-typed as INTRODUCTION (promoted to chapter)")
    end

    db:close()

    if #errors > 0 then
        return false, "Section/chapter title-collision test failed:\n  - "
            .. table.concat(errors, "\n  - ")
    end
    return true, nil
end
