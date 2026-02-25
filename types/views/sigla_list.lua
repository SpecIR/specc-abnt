---Sigla List (Abbreviation List) view for ABNT.
---Generates a list of abbreviations used in the document.
---
---@module abnt.types.views.sigla_list
---@author SpecDown Team
---@license MIT

local M = {}

M.view = {
    id = "SIGLA_LIST",
    long_name = "List of Abbreviations",
    description = "Abbreviation list for ABNT academic documents",
    inline_prefix = "sigla_list",
    materializer_type = "abbrev_list",
    view_subtype_ref = "ABBREV"
}

---Generate abbreviation list OOXML.
---Delegates to the default model's abbrev view's list generator.
---@param data DataManager
---@param spec_id string Specification identifier
---@param options table|nil View options
---@return string|nil OOXML content
function M.generate(data, spec_id, options)
    -- Use the default model's abbrev view for list generation
    local ok, abbrev = pcall(require, "models.default.types.views.abbrev")
    if ok and abbrev and abbrev.generate_list_ooxml then
        return abbrev.generate_list_ooxml(data, spec_id)
    end

    -- Fallback: return placeholder if abbrev module not available
    return '<w:p><w:r><w:t>[Nenhuma sigla encontrada]</w:t></w:r></w:p>'
end

return M
