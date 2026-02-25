---MATH_INLINE - Inline Math proxy (ABNT)
---Provides on_render_Code handler for inline_handlers.lua dispatch.
---The default model registers the view type and pipeline handler;
---this module only exposes the render function under the ABNT module path.

local default_math = require("models.default.types.views.math_inline")

local M = {}

-- No M.view: MATH_INLINE is already registered in DB by the default model.
-- Proxy handler with unique name so pipeline doesn't reject as duplicate.
-- Only on_render_Code is needed; on_initialize runs via the default handler.
M.handler = {
    name = "abnt_math_inline_proxy",
    prerequisites = { "spec_views" },
    on_render_Code = default_math.handler.on_render_Code,
}

return M
