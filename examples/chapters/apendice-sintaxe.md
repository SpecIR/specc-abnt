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

### Gráficos

    ```chart:id{query="nome_da_view" caption="Título" width="800" height="500"}
    { ...configuração ECharts... }
    ```

    ```chart:id{generator="gauss" mean="0" sigma="1" caption="Título" height="5cm"}
    { ...configuração ECharts... }
    ```

- `query`: consulta uma view SQL sobre o banco do documento
- `generator` (ou `view`): invoca um módulo Lua de `types/views/`

### Atributos de Dimensões e Fonte

Aplicáveis a `fig:`, `puml:`, `chart:`:

- `width`: Largura (px, %, cm, in)
- `height`: Altura (px, %, cm, in)
- `source`: Fonte — texto, `@citação`, ou omitido → "Elaborado pelo autor"

### Tabelas (dados numéricos)

    ```csv:id{caption="Título" source="Fonte"}
    Col1,Col2,Col3
    Val1,Val2,Val3
    ```

    ```list-table-t:id{caption="Título" source="Fonte"}
    > header-rows: 1
    > aligns: l,r
    * - Coluna
      - Valor
    * - Norte
      - 150
    ```

Renderiza com bordas abertas nas laterais (estilo IBGE) e legenda `Tabela N`.

### Quadros (informação textual)

    ```list-table:id{caption="Título" source="Fonte"}
    > header-rows: 1
    > aligns: l,c,l
    * - Col1
      - Col2
      - Col3
    * - Valor1
      - Valor2
      - Valor3
    ```

    ```csv-q:id{caption="Título" source="Fonte"}
    Termo,Definição
    Tabela,Dados numéricos
    ```

Renderiza com grade completa e legenda `Quadro N`.

Parâmetros de `list-table` (linhas iniciadas por `>`):

- `header-rows`: número de linhas de cabeçalho
- `aligns`: alinhamento por coluna — `l`, `c`, `r`
- `widths`: larguras relativas das colunas

### Listagens (código e texto preformatado)

    ```listing:id{caption="Título" source="Fonte"}
    Conteúdo textual, sem realce de sintaxe
    ```

    ```src.c:id{caption="Título" source="Fonte"}
    int main(void) { return 0; }
    ```

Renderiza com moldura e legenda `Listagem N`.

### Equações

    `math: a^2 + b^2 = c^2`          — inline

    ```math:id{caption="Título"}
    x = (-b +- sqrt(b^2 - 4ac)) / (2a)
    ```

### Citações

    [chave](@cite)              — Citação entre parênteses
    [chave](@citep)             — Citação no texto
    [chave1;chave2](@cite)      — Múltiplas citações

### Notas de Rodapé

    Texto com nota[^id].     — Referência inline

    [^id]: Conteúdo da nota de rodapé.

### Referências Cruzadas

    [fig:id](#)          → Figura N
    [csv:id](#)          → Tabela N
    [list-table:id](#)   → Quadro N
    [listing:id](#)      → Listagem N
    [math:id](#)         → Equação N
    [chart:id](#)        → Gráfico N
    [puml:id](#)         → Figura N

O prefixo pode ser qualquer alias do tipo. Referências não resolvidas
interrompem o build.

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

    project:
      code: MONOGRAFIA_EXAMPLE
      name: Exemplo de Monografia ABNT

    template: abnt
    style: academico
    output_dir: build/

    doc_files:
      - monografia.md

    # Bibliografia (citeproc); o estilo CSL é fornecido pelo modelo ABNT.
    bibliography: references.bib

    outputs:
      - format: docx
        path: "{spec_id}.docx"

    docx:
      update_fields: true   # atualiza sumário e listas ao gerar
      export_pdf: true      # exporta PDF via LibreOffice

### Seções Pré-textuais Automáticas

Basta declarar o cabeçalho; o conteúdo é gerado na compilação:

    ## Sumário
    ## Lista de Figuras
    ## Lista de Tabelas
    ## Lista de Quadros
    ## Lista de Listagens
    ## Lista de Abreviaturas e Siglas
