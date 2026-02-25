---Language utilities for ABNT object types.
---
---The ABNT model uses Portuguese (pt-BR) as the default document language.
---This is set in config.lua and applies to all content unless explicitly overridden.
---
---Object types that need a different language (e.g., English abstract) can
---override using this helper.
---
---Usage in object types:
---
---  -- For content that uses document default (most cases):
---  -- No special handling needed, content inherits document language
---
---  -- For content that overrides language (e.g., abstract):
---  local lang = require("models.abnt.types.shared.lang")
---
---  function M.body(ctx)
---      -- Auto-detect from title
---      local styled_div = lang.auto_styled_div(blocks, ctx.spec_object.title_text)
---      return { styled_div }
---  end

local M = {}

-- ============================================================================
-- Configuration
-- ============================================================================

local config = require("models.abnt.config")

-- ============================================================================
-- Document Default Language
-- ============================================================================

---Default document language for ABNT (from config.lua)
---Most content uses this - only override for bilingual sections.
M.DOCUMENT_DEFAULT = config.language.default

-- ============================================================================
-- Language Constants
-- ============================================================================

---@class LangConfig
---@field code string BCP-47 language code (e.g., "pt-BR", "en-US")
---@field style string|nil Style name with correct w:lang attribute (nil = use document default)

-- Get style from config or use fallback
local function get_style(code, fallback)
    local styles = config.language.styles
    return styles and styles[code] or fallback
end

---Portuguese (Brazil) - Document default for ABNT
---Content using this doesn't need explicit styling (inherits from document)
M.PT_BR = {
    code = "pt-BR",
    style = get_style("pt-BR", "Resumo"),
}

---English (US) - For abstracts and bilingual content
M.EN_US = {
    code = "en-US",
    style = get_style("en-US", "Abstract"),
}

---Spanish (Spain)
M.ES_ES = {
    code = "es-ES",
    style = get_style("es-ES", nil),
}

---French (France)
M.FR_FR = {
    code = "fr-FR",
    style = get_style("fr-FR", nil),
}

---Default language for ABNT documents (Portuguese)
M.DEFAULT = M.PT_BR

-- ============================================================================
-- Language Detection
-- ============================================================================

---Language detection patterns
---@type table<string, LangConfig>
local DETECTION_PATTERNS = {
    -- English patterns
    ["abstract"] = M.EN_US,
    ["summary"] = M.EN_US,
    ["keywords"] = M.EN_US,

    -- Portuguese patterns (default)
    ["resumo"] = M.PT_BR,
    ["palavras%-chave"] = M.PT_BR,

    -- Spanish patterns
    ["resumen"] = M.ES_ES,

    -- French patterns
    ["r[ée]sum[ée]"] = M.FR_FR,
}

---Detect language from text content.
---Scans text for language-specific keywords and returns the matching language.
---@param text string|nil Text to analyze (usually section title)
---@return LangConfig language Detected language or DEFAULT
function M.detect(text)
    if not text then return M.DEFAULT end

    local lower = text:lower()

    for pattern, lang in pairs(DETECTION_PATTERNS) do
        if lower:match(pattern) then
            return lang
        end
    end

    return M.DEFAULT
end

---Check if text indicates English content.
---@param text string|nil Text to check
---@return boolean True if English detected
function M.is_english(text)
    local detected = M.detect(text)
    return detected.code == M.EN_US.code
end

---Check if text indicates Portuguese content.
---@param text string|nil Text to check
---@return boolean True if Portuguese detected
function M.is_portuguese(text)
    local detected = M.detect(text)
    return detected.code == M.PT_BR.code
end

---Check if detected language differs from document default.
---Use this to determine if explicit language styling is needed.
---@param text string|nil Text to check
---@return boolean True if language differs from document default
function M.needs_override(text)
    local detected = M.detect(text)
    return detected.code ~= M.DOCUMENT_DEFAULT
end

-- ============================================================================
-- Styled Content Helpers
-- ============================================================================

---Create a Div with language-appropriate custom-style.
---Only applies styling if language differs from document default.
---@param blocks table Array of Pandoc blocks
---@param lang LangConfig Language configuration (e.g., M.PT_BR, M.EN_US)
---@param force boolean|nil Force style even for document default language
---@return pandoc.Div|table Styled div or original blocks
function M.styled_div(blocks, lang, force)
    lang = lang or M.DEFAULT

    -- If language matches document default and not forced, return blocks as-is
    -- (they inherit document language automatically)
    if not force and lang.code == M.DOCUMENT_DEFAULT then
        return pandoc.Div(blocks)  -- Plain div, inherits document language
    end

    -- Apply explicit language style for overrides
    if lang.style then
        return pandoc.Div(blocks, pandoc.Attr("", {}, {["custom-style"] = lang.style}))
    end

    -- No style defined for this language, return plain div
    return pandoc.Div(blocks)
end

---Create a styled Div with auto-detected language.
---Automatically determines if language override is needed.
---@param blocks table Array of Pandoc blocks
---@param title_text string|nil Title text for language detection
---@return pandoc.Div Styled div with detected language style (if override needed)
function M.auto_styled_div(blocks, title_text)
    local detected = M.detect(title_text)
    -- Force styling for detected language (abstract needs explicit style)
    return M.styled_div(blocks, detected, true)
end

---Get the style name for a given language.
---@param lang LangConfig Language configuration
---@return string Style name
function M.get_style(lang)
    return lang and lang.style or M.DEFAULT.style
end

---Get the BCP-47 language code.
---@param lang LangConfig Language configuration
---@return string Language code (e.g., "pt-BR")
function M.get_code(lang)
    return lang and lang.code or M.DEFAULT.code
end

---Get the document default language code.
---This is the language set in config.lua.
---@return string Language code (e.g., "pt-BR")
function M.get_document_default()
    return M.DOCUMENT_DEFAULT
end

---Set the document default language.
---Call this if you need to change from the config default.
---@param code string BCP-47 language code
function M.set_document_default(code)
    M.DOCUMENT_DEFAULT = code
end

---Get a LangConfig by language code.
---@param code string BCP-47 language code (e.g., "pt-BR", "en-US")
---@return LangConfig|nil Language configuration or nil if not found
function M.by_code(code)
    if code == M.PT_BR.code then return M.PT_BR end
    if code == M.EN_US.code then return M.EN_US end
    if code == M.ES_ES.code then return M.ES_ES end
    if code == M.FR_FR.code then return M.FR_FR end
    return nil
end

return M
