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

## Opening the generated document (update fields)

Everything that auto-numbers in the DOCX is driven by Word fields: the
**Sumário** (table of contents), the **Lista de Figuras / Tabelas**, and the
figure/table/section numbers in captions and cross-references. Word shows the
*cached* value of a field until it is recalculated, so a freshly built file can
open with empty lists or with every caption showing "1".

After opening the DOCX, update all fields once:

1. Select the whole document — **Ctrl+A**.
2. Update fields — **F9**. If a dialog appears for the table of contents, choose
   **Update entire table**.

This populates the Sumário and the lists and renumbers the figures, tables, and
sections. (In LibreOffice Writer the equivalent is **Tools ▸ Update ▸ Update
All**.)

## Output formats

The ABNT model customizes **DOCX** output: `filters/{docx}.lua`
plus `postprocessors/{docx}.lua` translate the format-agnostic SpecCompiler IR
into ABNT-conformant OOXML and TeX — cover, title page, pre-textual sections, and numbered floats whose cross-references resolve.

## Customizing DOCX Output

ABNT standards are notoriously strict about formatting -- margins, font sizes, spacing, heading styles, page numbering, and different formatting rules for different sections. This makes specc-abnt a good reference for anyone building custom SpecCompiler models that need fine-grained control over DOCX output.

The key extension points are:

- `filters/docx.lua` -- OOXML-level transformations (page breaks, section properties, numbering)
- `postprocessors/docx.lua` -- post-processing of the final DOCX (page numbering, table formatting)
- `styles/academico/preset.lua` -- page geometry, fonts, spacing, and margins
