## APPENDIX: Referência Rápida de Sintaxe

### Atributos do Documento

    > institution: Nome da Instituição
    
    > author: Nome do Autor
    
    > title: Título do Trabalho

### Figuras

    ```fig:id{caption="Legenda" source="Fonte" width="400" height="300"}
    caminho/imagem.jpg
    ```

### Diagramas PlantUML

    ```puml:id{caption="Título do diagrama" width="600"}
    @startuml
    ...
    @enduml
    ```

### Gráficos com Query

    ```chart:id{query="nome_da_view" caption="Título" width="800" height="500"}
    { ...configuração ECharts... }
    ```

### Atributos de Dimensões e Fonte

Aplicáveis a `fig:`, `puml:`, `chart:`:

- `width`: Largura (px, %, cm, in)
- `height`: Altura (px, %, cm, in)
- `source`: Fonte — texto, `@citação`, ou omitido → "Elaborado pelo autor"

### Tabelas (list-table)

    ```list-table:id{caption="Título" source="Fonte"}
    > header-rows: 1
    > aligns: l,c,r
    * - Col1
      - Col2
    * - Valor1
      - Valor2
    ```

### Tabelas (CSV)

    ```csv:id{caption="Título" source="Fonte"}
    Col1,Col2,Col3
    Val1,Val2,Val3
    ```

### Quadros

    ```listing:id{caption="Título" source="Fonte"}
    Conteúdo textual do quadro
    ```

### Citações

    [chave](@cite)              — Citação entre parênteses
    [chave](@citep)             — Citação no texto
    [chave1;chave2](@cite)      — Múltiplas citações

### Notas de Rodapé

    Texto com nota[^id].     — Referência inline

    [^id]: Conteúdo da nota de rodapé.

### Referências Cruzadas

    Figura [fig:id](#)
    Tabela [table:id](#)
    Quadro [listing:id](#)

### Siglas

    `sigla: Termo Completo (SIGLA)`

### Inclusão de Arquivos

Use `include` para compor um documento a partir de vários arquivos Markdown. Os
caminhos são relativos ao arquivo que contém a diretiva:

    ```include
    chapters/introducao.md
    chapters/figuras-ilustracoes.md
    chapters/referencias.md
    chapters/apendice-sintaxe.md
    ```

O conteúdo incluído participa da mesma estrutura lógica do documento: cabeçalhos,
figuras, tabelas, citações, siglas e referências cruzadas são processados em conjunto.

### Configuração (project.yaml)

    # Template e tipos
    template: abnt
    type_file: ../dist/db/seed.sql

    # Arquivos fonte
    doc_files:
      - monografia.md

    # Saída
    output_dir: build/
    output_formats: [docx]

    # Estilos DOCX
    docx:
      preset: academico
      reference_doc: ../dist/reference.docx

    # Bibliografia (citeproc); o estilo CSL é fornecido pelo modelo ABNT.
    bibliography: references.bib
