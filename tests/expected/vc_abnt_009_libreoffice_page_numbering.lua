-- Test oracle for VC-ABNT-009: pre-textual page numbering survives finalization
--
-- Builds the ABNT template with docx.update_fields + docx.export_pdf enabled and
-- inspects the OOXML of the artifact that actually ships: the DOCX the ABNT
-- postprocessor produced and LibreOffice then re-saved in place.
--
-- ABNT NBR 14724 numbers pre-textual pages in lower-case roman numerals and
-- leaves those pages unnumbered (the count shows only from the textual part on),
-- so the pre-textual section must carry pgNumType lowerRoman with headers that
-- hold no PAGE field, and the textual section must carry decimal with a
-- page-numbered header.
--
-- Regression guarded: when Pandoc's reference.docx ended the body with a
-- self-closing <w:sectPr/> (3.1.x, stock Ubuntu 24.04), replace_body_sectpr
-- overwrote the injected pre-textual section break instead. The pre-textual
-- pages then numbered in arabic, showed page numbers, and the body section fell
-- back to Letter page setup.

local A4_WIDTH, A4_HEIGHT = "11906", "16838"
local ABNT_LEFT, ABNT_RIGHT = "1701", "1134"

---Split document.xml into its <w:sectPr> elements, self-closing form included.
local function each_sectpr(doc_xml)
    local sections = {}
    local pos = 1
    while true do
        local start = doc_xml:find("<w:sectPr[>/%s]", pos)
        if not start then break end

        local _, finish = doc_xml:find("^<w:sectPr[^>]*/>", start)
        local self_closing = finish ~= nil
        if not finish then
            _, finish = doc_xml:find("</w:sectPr>", start)
        end
        if not finish then break end

        table.insert(sections, {
            xml = doc_xml:sub(start, finish),
            self_closing = self_closing,
        })
        pos = finish + 1
    end
    return sections
end

---Map header relationship ids to their part names.
local function header_targets(rels_xml)
    local targets = {}
    for rel in (rels_xml or ""):gmatch("<Relationship[^>]->") do
        local id = rel:match('Id="([^"]+)"')
        local target = rel:match('Target="([^"]+)"')
        if id and target and rel:find("/header", 1, true) then
            targets[id] = "word/" .. target:gsub("^/", "")
        end
    end
    return targets
end

return function(actual_doc, helpers)
    local errors = {}
    local function err(msg) table.insert(errors, msg) end

    if not actual_doc or #actual_doc.blocks < 1 then
        return false, "Document AST should have blocks"
    end

    local build_dir = helpers.build_dir .. "/"
    local suite_dir = helpers.suite_dir .. "/"
    local test_name = "vc_abnt_009_libreoffice_page_numbering"
    local docx_path = build_dir .. test_name .. ".docx"
    local pdf_path = build_dir .. test_name .. ".pdf"
    local docx_db = build_dir .. "docx_abnt_pgnum.db"

    os.remove(pdf_path)
    os.remove(docx_db)

    local engine = require("core.engine")
    local ok, gen_err = pcall(engine.run_project, {
        project = { code = "TEST_ABNT_PGNUM", name = "ABNT pre-textual page numbering" },
        template = "abnt",
        style = "academico",
        files = { suite_dir .. test_name .. ".md" },
        output_dir = build_dir,
        output_format = "docx",
        outputs = {{ format = "docx", path = docx_path }},
        db_file = docx_db,
        docx = { update_fields = true, export_pdf = true },
        logging = { level = "WARN" },
    })
    if not ok then
        return false, "DOCX generation failed: " .. tostring(gen_err)
    end

    local docx_helpers = require("docx_helpers")
    if not docx_helpers.is_valid_docx(docx_path) then
        return false, "Finalized file is not a valid DOCX archive: " .. docx_path
    end

    local doc_xml = docx_helpers.get_document_xml(docx_path) or ""
    local rels = header_targets(docx_helpers.extract_from_docx(
        docx_path, "word/_rels/document.xml.rels"))
    local sections = each_sectpr(doc_xml)

    if #sections < 2 then
        return false, string.format(
            "Expected a pre-textual and a textual section, found %d sectPr element(s)", #sections)
    end

    -- Every section keeps A4 page setup and ABNT margins. A section that lost
    -- its properties silently falls back to the Letter default.
    local pretextual, textual = nil, nil
    for index, section in ipairs(sections) do
        if section.self_closing then
            err(string.format("section %d is an empty <w:sectPr/> (page setup lost)", index))
        else
            local w, h = section.xml:match('<w:pgSz[^>]-w:w="(%d+)"[^>]-w:h="(%d+)"')
            if not w then
                h, w = section.xml:match('<w:pgSz[^>]-w:h="(%d+)"[^>]-w:w="(%d+)"')
            end
            if w ~= A4_WIDTH or h ~= A4_HEIGHT then
                err(string.format("section %d page size is %sx%s, expected A4 %sx%s",
                    index, tostring(w), tostring(h), A4_WIDTH, A4_HEIGHT))
            end

            local left = section.xml:match('<w:pgMar[^>]-w:left="(%d+)"')
            local right = section.xml:match('<w:pgMar[^>]-w:right="(%d+)"')
            if left ~= ABNT_LEFT or right ~= ABNT_RIGHT then
                err(string.format("section %d margins are left=%s right=%s, expected %s/%s",
                    index, tostring(left), tostring(right), ABNT_LEFT, ABNT_RIGHT))
            end
        end

        local fmt = section.xml:match('<w:pgNumType[^>]-w:fmt="([^"]+)"')
        if fmt == "lowerRoman" then
            pretextual = pretextual or section
        elseif fmt == "decimal" then
            textual = section
        end
    end

    if not pretextual then
        err("no section numbers its pages in lowerRoman (pre-textual numbering lost)")
    else
        if not pretextual.xml:match('<w:pgNumType[^>]-w:start="1"') then
            err("the lowerRoman section does not restart page numbering at 1")
        end

        -- Pre-textual pages are counted but not shown, so their headers carry
        -- no PAGE field.
        for rid in pretextual.xml:gmatch('<w:headerReference[^>]-r:id="([^"]+)"') do
            local part = rels[rid]
            local header = part and docx_helpers.extract_from_docx(docx_path, part)
            if header and header:find("PAGE", 1, true) then
                err(string.format(
                    "pre-textual header %s shows a page number; those pages must be unnumbered",
                    part))
            end
        end
    end

    if not textual then
        err("no section numbers its pages in decimal (textual numbering lost)")
    else
        local numbered = false
        for rid in textual.xml:gmatch('<w:headerReference[^>]-r:id="([^"]+)"') do
            local part = rels[rid]
            local header = part and docx_helpers.extract_from_docx(docx_path, part)
            if header and header:find("PAGE", 1, true) then
                numbered = true
            end
        end
        if not numbered then
            err("the decimal section has no header showing a page number")
        end
    end

    -- The field update ran: the TOC repeats the textual chapter titles.
    local introducao_runs = 0
    for _ in doc_xml:gmatch("<w:t[^>]*>[^<]*Introducao") do
        introducao_runs = introducao_runs + 1
    end
    if introducao_runs < 2 then
        err(string.format(
            "expected 'Introducao' in the heading and the populated TOC (>=2 runs), got %d",
            introducao_runs))
    end

    local pdf = io.open(pdf_path, "rb")
    if not pdf then
        err("LibreOffice PDF was not created: " .. pdf_path)
    else
        local magic = pdf:read(5)
        pdf:close()
        if magic ~= "%PDF-" then
            err("exported file is not a PDF: " .. pdf_path)
        end
    end

    if #errors > 0 then
        return false, "ABNT page numbering check failed:\n  - " .. table.concat(errors, "\n  - ")
    end
    return true
end
