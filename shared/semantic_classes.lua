---Semantic-class string constants for ABNT (NBR 14724:2011).
---
---Single source of truth for the Div/Span class names that emitter objects stamp
---onto pre-textual content and that the docx/latex filters key their
---SEMANTIC_CLASS_MAP tables off of. Keeping the literals here means a rename
---changes one place and stays in sync across producers and consumers -- it can't
---silently lose styling.
---
---The string VALUES are byte-identical to the literals they replace; this is a
---pure rename-to-constant with zero behaviour change.
---
---@module abnt.shared.semantic_classes

return {
    -- Cover page elements
    COVER_INSTITUTION  = "cover-institution",
    COVER_DEPARTMENT   = "cover-department",
    COVER_TITLE        = "cover-title",
    COVER_SUBTITLE     = "cover-subtitle",
    COVER_AUTHOR       = "cover-author",
    COVER_NATURE       = "cover-nature",
    COVER_ADVISOR      = "cover-advisor",
    COVER_IMAGE_TITLE  = "cover-image-title",
    COVER_IMAGE_AUTHOR = "cover-image-author",
    COVER_ICMC_TITLE   = "cover-icmc-title",
    COVER_ICMC_AUTHOR  = "cover-icmc-author",
    COVER_LOCATION     = "cover-location",
    COVER_YEAR         = "cover-year",

    -- Title page elements
    TITLEPAGE_AUTHOR      = "titlepage-author",
    TITLEPAGE_TITLE       = "titlepage-title",
    TITLEPAGE_SUBTITLE    = "titlepage-subtitle",
    TITLEPAGE_NATURE      = "titlepage-nature",
    TITLEPAGE_INSTITUTION = "titlepage-institution",
    TITLEPAGE_ADVISOR     = "titlepage-advisor",
    TITLEPAGE_LOCATION    = "titlepage-location",
    TITLEPAGE_YEAR        = "titlepage-year",

    -- Pre-textual elements
    DEDICATION         = "dedication",
    EPIGRAPH           = "epigraph",
    UNNUMBERED_HEADING = "unnumbered-heading",
    TOC_HEADING        = "toc-heading",
}
