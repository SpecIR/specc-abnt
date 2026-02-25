---ABNT Chart type override.
---Configures CHART as a separate counter group with Portuguese caption.
---
---In ABNT, charts (Gráficos) have their own numbering separate from figures.
---This overrides the default which groups CHART with FIGURE.
---
---@module abnt.chart
---@author SpecDown Team
---@license MIT

local M = {}

M.float = {
    id = "CHART",
    long_name = "Gráfico",
    description = "Gráfico ECharts renderizado para PNG",
    caption_format = "Gráfico",   -- Portuguese caption prefix
    counter_group = "CHART",      -- Separate counter from FIGURE
    aliases = { "echarts", "echart" },
    needs_external_render = true,
}

return M
