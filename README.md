# specc-abnt

While [SpecCompiler](https://github.com/SpecIR/SpecCompiler) was developed for technical documentation, it works surprisingly well for academic writing such as papers and thesis. This model provides the ABNT-compliant structure and styling needed for Brazilian academic *monographies*.

## Quick Start

Install SpecCompiler (if not already installed):

```bash
curl -fsSL https://raw.githubusercontent.com/SpecIR/SpecCompiler/main/scripts/install.sh | bash
```

```bash
git clone https://github.com/SpecIR/specc-abnt.git
cd specc-abnt
bash scripts/docker_install.sh
```

## Usage

In your `project.yaml`:

```yaml
template: abnt
style: academico
```

See the [examples/](examples/) directory for a complete monograph example — the built DOCX is attached to every [release](https://github.com/SpecIR/specc-abnt/releases) (published automatically on each push to main).

## Use as a template

This repository doubles as a template for writing your own ABNT document with automatic DOCX publishing:

1. Fork it (or "Use this template" on GitHub).
2. Write your document in a directory containing a `project.yaml` (the example in `examples/` is the default).
3. Push to `main` — the [Publish Document workflow](.github/workflows/publish-document.yml) builds the DOCX with the ready-made `ghcr.io/specir/specc-abnt` image (no Docker build in your fork) and attaches it to a GitHub release.

To point the workflow at your own document, edit `PROJECT_DIR` at the top of `.github/workflows/publish-document.yml`.

## Output formats

The ABNT model customizes **DOCX** and **LaTeX** output: `filters/{docx,latex}.lua`
plus `postprocessors/{docx,latex}.lua` translate the format-agnostic SpecCompiler IR
into ABNT-conformant OOXML and TeX — cover, title page, pre-textual sections, and
numbered floats whose cross-references resolve (in LaTeX via `\phantomsection\label`
anchors that match the `\hyperref` targets).

**HTML** is intentionally not customized here: an ABNT document built to HTML falls
back to SpecCompiler's generic `default` HTML filter, which produces a valid document
but without the ABNT-specific cover/title-page styling. ABNT targets print-oriented
formats (DOCX for review, LaTeX for PDF); ABNT-specific HTML styling is future work.

## Canonical source

This repository is the canonical source for the ABNT model. A copy is also bundled inside SpecCompiler at `SpecCompiler/models/abnt/` for convenience, but it must be considered read-only — do not edit it directly. Any change to the ABNT model lands here first; the bundled copy is refreshed from this repository on demand. Editing the bundled copy directly causes drift between the two trees and forces a manual reconciliation later.

## Customizing DOCX Output

ABNT standards are notoriously strict about formatting -- margins, font sizes, spacing, heading styles, page numbering, and different formatting rules for different sections. This makes specc-abnt a good reference for anyone building custom SpecCompiler models that need fine-grained control over DOCX output.

The key extension points are:

- `filters/docx.lua` -- OOXML-level transformations (page breaks, section properties, numbering)
- `postprocessors/docx.lua` -- post-processing of the final DOCX (page numbering, table formatting)
- `styles/academico/preset.lua` -- page geometry, fonts, spacing, and margins
