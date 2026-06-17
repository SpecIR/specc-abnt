## Citações e Referências Bibliográficas

O SpecCompiler utiliza Citeproc para processar citações—não o tradicional toolchain BibTeX/Biber do LaTeX. Essa escolha simplifica significativamente o fluxo de trabalho: um único arquivo `.bib` e um estilo CSL são suficientes, sem necessidade de múltiplas compilações ou arquivos auxiliares (`.aux`, `.bbl`, `.blg`, `.bcf`, `.run.xml`). O processamento segue as normas NBR 10520 [NBR10520:2002](@cite) e NBR 6023 [NBR6023:2018](@cite).

### Tipos de Citação

**Citação indireta** (entre parênteses): A referência aparece ao final da frase.

> A formatação de trabalhos acadêmicos deve seguir normas padronizadas [NBR14724:2011](@cite).

**Citação direta** (no texto): O autor faz parte da sentença.

> Segundo [NBR14724:2011](@citep), os trabalhos acadêmicos devem conter elementos pré-textuais, textuais e pós-textuais.

### Múltiplas Citações

Para citar múltiplas obras simultaneamente, separe as chaves com ponto e vírgula:

> Diversos autores tratam da normalização de documentos acadêmicos [NBR14724:2011;NBR6023:2018;NBR10520:2002](@cite).

### Configuração: Citeproc e CSL

O processamento de citações utiliza dois componentes:

1. **Citeproc**: Processador de citações integrado ao Pandoc que converte `[chave](@cite)` em citações formatadas

2. **CSL (Citation Style Language)**: Arquivo XML que define o estilo de formatação das citações

O template ABNT já fornece o estilo de citação (`abnt.csl`, declarado em `models/abnt/config.lua`); o `project.yaml` precisa apenas indicar a bibliografia:

    # Configuração de bibliografia (citeproc)
    bibliography: references.bib
    # csl: opcional — só declare aqui para sobrescrever o estilo do modelo

O arquivo CSL determina:
- Formato da citação no texto: (Autor, ano) vs [Autor, ano]
- Formato das entradas na bibliografia
- Ordenação das referências
- Regras de abreviação (et al.)

O estilo ABNT segue a NBR 10520 [NBR10520:2002](@cite) para citações e NBR 6023 [NBR6023:2018](@cite) para referências.
