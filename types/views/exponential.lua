---Exponential Decay view type module.
---Handles `exp:` inline code syntax for generating exponential decay curves.
---
---Syntax:
---  `exp:`                           - Default exponential (lambda=1, offset=0)
---  `exp: lambda=0.5 offset=1`       - Custom parameters
---  `exp: xmin=0 xmax=10 n=100`      - Custom range and points
---
---Parameters:
---  lambda: decay constant (default: 1.0)
---  offset: y-axis offset (default: 0)
---  xmin: minimum x value (default: 0)
---  xmax: maximum x value (default: 5)
---  points/n: number of points (default: 61)
---
---Returns ECharts dataset format for charts, or summary for inline use.
---
---Uses the unified INITIALIZE -> TRANSFORM -> EMIT pattern:
---  - INITIALIZE: Not needed (computes at emit time)
---  - TRANSFORM: Not needed (computes at emit time)
---  - EMIT: Compute curve, return data
---
---@module exponential

local schema = {
    id = "EXPONENTIAL",
    long_name = "Exponential Decay",
    description = "Exponential decay curve: f(x) = e^(-lambda*x) + offset",
    inline_prefix = "exp",
    aliases = { "exponential" },
}

-- ============================================================================
-- Parsing
-- ============================================================================

---Parse exponential parameters from syntax.
---@param text string Parameter text after "exp:"
---@return table params Parsed parameters
local function parse_params(text)
    local params = {}
    if not text or text == "" then
        return params
    end

    for key, value in text:gmatch("(%w+)%s*=%s*([%d%.%-]+)") do
        local num = tonumber(value)
        if num then
            if key == "lambda" then
                params.lambda = num
            elseif key == "offset" then
                params.offset = num
            elseif key == "xmin" then
                params.xmin = num
            elseif key == "xmax" then
                params.xmax = num
            elseif key == "points" or key == "n" then
                params.points = math.floor(num)
            end
        end
    end

    return params
end

local prefix_matcher = require("pipeline.shared.prefix_matcher")
local match_exp_code = prefix_matcher.from_decl(schema)

-- ============================================================================
-- Data Generation
-- ============================================================================

---Calculate the exponential decay value.
---@param x number Input value
---@param lambda number Decay constant
---@param offset number Y-axis offset
---@return number y Function value at x
local function exponential_curve(x, lambda, offset)
    return math.exp(-lambda * x) + offset
end

---Generate exponential decay curve data.
---@param dctx table Data context with subject.params
---@return table dataset ECharts dataset format {source = {{header}, {x, y}, ...}}
local function dataset(dctx)
    local params = dctx.subject.params or {}
    local lambda = params.lambda or 1.0
    local offset = params.offset or 0
    local xmin = params.xmin or 0
    local xmax = params.xmax or 5
    local points = params.points or 61

    local source = { {"x", "y"} }
    local step = (xmax - xmin) / (points - 1)

    for i = 0, points - 1 do
        local x = xmin + i * step
        local y = exponential_curve(x, lambda, offset)
        x = math.floor(x * 1000 + 0.5) / 1000
        y = math.floor(y * 10000 + 0.5) / 10000
        table.insert(source, {x, y})
    end

    return { source = source }
end

-- ============================================================================
-- Hooks
-- ============================================================================

return {
    kind = "view",
    schema = schema,
    hooks = {
        ---EMIT: Render inline Code elements with exp: syntax.
        ---For inline use, returns a text summary of the parameters.
        ---For chart use (via view="exp" attribute), dataset() is called directly.
        render = function(ctx)
            local code = ctx.subject.element
            local rest = match_exp_code(code.text or "")
            if rest == nil then return nil end

            local params = parse_params(rest)

            if not pandoc then
                return nil
            end

            local lambda = params.lambda or 1.0
            local offset = params.offset or 0
            local text = string.format("e^(-%.2g·x) + %.2g", lambda, offset)

            return { pandoc.Str(text) }
        end,
        dataset = dataset,
    },
}
