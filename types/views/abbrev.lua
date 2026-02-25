---Abbreviation view for ABNT.
---Wraps the default model's abbrev handler to enable inline sigla rendering.
---Without this file, the inline_handlers dispatcher cannot find the ABBREV
---handler for the ABNT model, and `sigla:` codes pass through unrendered.
---
---@module abnt.types.views.abbrev

local default_abbrev = require("models.default.types.views.abbrev")

local M = {}

-- Re-export the view definition (the type loader needs this)
M.view = default_abbrev.view

-- Expose handler with on_render_Code for the inline_handlers dispatcher.
-- Do NOT re-export on_initialize/on_transform (already handled by default model).
-- Use a different handler name to avoid duplicate registration.
M.handler = {
    name = "abnt_abbrev_handler",
    prerequisites = {"abbrev_handler"},
    on_render_Code = default_abbrev.handler.on_render_Code,
}

-- Re-export list generation functions (used by sigla_list)
M.get_list = default_abbrev.get_list
M.generate_list_ooxml = default_abbrev.generate_list_ooxml

return M
