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

See the [examples/](examples/) directory for a complete [monograph example](https://github.com/SpecIR/specc-abnt/raw/refs/heads/word/monografia.docx).

## Canonical source

This repository is the canonical source for the ABNT model. A copy is also bundled inside SpecCompiler at `SpecCompiler/models/abnt/` for convenience, but it must be considered read-only — do not edit it directly. Any change to the ABNT model lands here first; the bundled copy is refreshed from this repository on demand. Editing the bundled copy directly causes drift between the two trees and forces a manual reconciliation later.

## Customizing DOCX Output

ABNT standards are notoriously strict about formatting -- margins, font sizes, spacing, heading styles, page numbering, and different formatting rules for different sections. This makes specc-abnt a good reference for anyone building custom SpecCompiler models that need fine-grained control over DOCX output.

The key extension points are:

- `filters/docx.lua` -- OOXML-level transformations (page breaks, section properties, numbering)
- `postprocessors/docx.lua` -- post-processing of the final DOCX (page numbering, table formatting)
- `styles/academico/preset.lua` -- page geometry, fonts, spacing, and margins
