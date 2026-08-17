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

The image includes LibreOffice and Python UNO, so builds can update DOCX
fields (Word's **Ctrl+A**, **F9** equivalent) and export a PDF after that
update pass out of the box — there is no separate LibreOffice image variant.

## Local image republish

To update the published container without changing CI, repack the existing GHCR
image with the ABNT model from this checkout:

```bash
bash scripts/repack_published_image.sh --push
```

The script pulls `ghcr.io/specir/specc-abnt:latest`, overwrites
`/opt/speccompiler/models/abnt` inside the image, rebuilds the image locally,
and pushes it only when `--push` is set.

## Usage

In your `project.yaml`:

```yaml
template: abnt
style: academico

# Optional; requires LibreOffice in the runtime image/installation.
docx:
  update_fields: true
  export_pdf: true
```

See the [examples/](examples/) directory for a complete monograph example — the built DOCX/PDF artifacts are attached to every [release](https://github.com/SpecIR/specc-abnt/releases) (published automatically on each push to main). The latest LibreOffice-generated PDF is also published at <https://specir.github.io/specc-abnt/monografia.pdf>.

## Use as a template

This repository doubles as a template for writing your own ABNT document with automatic DOCX/PDF publishing:

1. Fork it (or "Use this template" on GitHub).
2. Write your document in a directory containing a `project.yaml` (the example in `examples/` is the default).
3. Push to `main` — the [Publish Document workflow](.github/workflows/publish-document.yml) builds the DOCX/PDF with the ready-made `ghcr.io/specir/specc-abnt:latest` image (no Docker build in your fork), attaches them to a GitHub release, and publishes the PDF to GitHub Pages.

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

If `docx.update_fields: true` is set, the postprocessor opens the DOCX in
LibreOffice, updates fields/indexes, and saves the same DOCX path in place. If
`docx.export_pdf: true` is also set, it writes a PDF next to the DOCX after the
update pass. LibreOffice ships in the image; on native installs without
LibreOffice/UNO these options are skipped with a warning.

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
