---SIGLA - Inline acronym/abbreviation definition and tracking (ABNT)
---Syntax: `sigla: Full Meaning Text (ABBREV)`
---Renders as: "Full Meaning Text (ABBREV)" on first occurrence
---Stores in specview_data table for list generation via `select: sigla_list`

local M = { name = "sigla" }

M.object = {
    id = "SIGLA",
    long_name = "Sigla",
    description = "Inline acronym/abbreviation definition and tracking",
    inline = true,
    inline_syntax = "sigla",
    transformers = {
        { syntax = "sigla", module = "models.abnt.types.objects.sigla" }
    }
}

-- ============================================================================
-- Utility Functions
-- ============================================================================

---Parse sigla syntax: "Full Meaning Text (ABBREV)"
---@param text string
---@return string|nil meaning, string|nil sigla
local function parse_sigla(text)
    if not text or text == "" then
        return nil, nil
    end

    local meaning, sigla = text:match("^(.-)%s*%(([^)]+)%)%s*$")

    if meaning and sigla and meaning ~= "" and sigla ~= "" then
        meaning = meaning:match("^%s*(.-)%s*$")
        sigla = sigla:match("^%s*(.-)%s*$")
        return meaning, sigla
    end

    return nil, nil
end

-- ============================================================================
-- Render Phase
-- ============================================================================

---Process inline code during render phase
---@param code table The inline code element
---@param ctx table Pipeline context
---@return table|nil Array of inline elements
function M.on_render_Code(code, ctx)
    local text = code.text or ""
    local reference = text:match("^sigla:%s*(.+)$")
    if not reference then return nil end

    local log = ctx.log or { debug = function() end, warn = function() end, error = function() end }
    log.debug("sigla_handler: processing reference=%s", reference)

    local meaning, sigla = parse_sigla(reference)

    if not meaning or not sigla then
        log.warn("Invalid sigla syntax: %s (expected \"Meaning (SIGLA)\")", reference)
        return nil
    end

    log.debug("sigla_handler: meaning=%s, sigla=%s", meaning, sigla)

    -- Insert into database using Plugin API
    if ctx.api then
        local root_path = ctx.root_path or ctx.current_root or ""
        if type(root_path) == "table" then
            root_path = root_path.path or root_path[1] or tostring(root_path)
        end
        root_path = tostring(root_path)

        local from_file = ctx.from_file or ""
        if type(from_file) == "table" then
            from_file = from_file.path or from_file[1] or ""
        end
        from_file = tostring(from_file)

        -- Get next sequence and insert using Plugin API (generic specview_data)
        local next_seq = ctx.api:get_next_specview_seq(root_path, "sigla")
        local insert_ok = ctx.api:upsert_specview_data({
            root_path = root_path,
            from_file = from_file,
            kind = "sigla",
            key = sigla,
            value = meaning,
            insertion_seq = next_seq
        })

        if insert_ok then
            log.debug("sigla_handler: stored sigla=%s, seq=%d", sigla, next_seq)
        end
    end

    -- Render as plain text
    local output_text = meaning .. " (" .. sigla .. ")"
    return { pandoc.Str(output_text) }
end

---Code function (legacy interface)
---@param code_elem table
---@param reference string
---@param context table
---@return table|nil
function M.Code(code_elem, reference, context)
    local db_handler = context.db_handler or (package.loaded["specmark"] and package.loaded["specmark"].db_handler)
    local log = context.log or (package.loaded["specmark"] and package.loaded["specmark"].log) or {
        debug = function() end,
        warn = function() end,
        error = function() end
    }
    local PluginAPI = require("core.extensions.plugin_api")

    local ctx = {
        db = db_handler,
        api = db_handler and PluginAPI.new(db_handler, nil, log) or nil,
        log = log,
        root_path = context.root_path,
        current_root = context.current_root,
        from_file = context.from_file
    }

    local fake_code = { text = "sigla: " .. reference }
    return M.on_render_Code(fake_code, ctx)
end

return M
