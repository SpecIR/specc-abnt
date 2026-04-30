# Trabalho Acadêmico

> institution: Specdown Documentation

> faculty: Template ABNT

> department: Guia de Uso

> course: Tutorial Completo

> title: Criando Trabalhos Acadêmicos com Specdown: Guia Prático do Template ABNT

> author: Specdown Team

> advisor: Este documento é auto-demonstrativo

> nature: Documento de exemplo e tutorial que demonstra as funcionalidades do template ABNT do Specdown para criação de trabalhos acadêmicos conforme as normas da ABNT NBR 14724.

> city: Online

> year: 2025

## Capa

## Folha de rosto

## Dedicatória

Este documento é dedicado a todos que buscam uma forma mais simples de criar trabalhos acadêmicos sem abrir mão da conformidade com as normas ABNT.

## Agradecimentos

Agradecemos à comunidade de software livre, especialmente aos desenvolvedores do Pandoc e SQLite, que tornaram possível a criação do Specdown.

## Epígrafe

> "Simplicidade é a sofisticação máxima."
>
> — Leonardo da Vinci

## Resumo

Este documento serve como tutorial e demonstração do template `sigla: Associação Brasileira de Normas Técnicas (ABNT)` do Specdown. Através de uma estrutura auto-referencial, apresenta-se como criar trabalhos acadêmicos em formato Markdown que são automaticamente convertidos para documentos DOCX em conformidade com a NBR 14724 [NBR14724:2011](@cite). São demonstradas as funcionalidades de elementos pré-textuais, textuais e pós-textuais, além de recursos como tabelas, quadros, gráficos baseados em dados, figuras, citações bibliográficas e listas automáticas de siglas, figuras e tabelas.

> Palavras-chave: specdown, ABNT, markdown, trabalhos acadêmicos, NBR 14724.

## Abstract

This document serves as a tutorial and demonstration of the Specdown ABNT template. Through a self-referential structure, it presents how to create academic works in Markdown format that are automatically converted to DOCX documents in compliance with NBR 14724. The functionalities of pre-textual, textual and post-textual elements are demonstrated, as well as features such as tables, frames, data-driven charts, figures, bibliographic citations and automatic lists of abbreviations, figures and tables.

> Keywords: specdown, ABNT, markdown, academic works, NBR 14724.

## Lista de Figuras

## Lista de Tabelas

## Lista de Abreviaturas e Siglas

## Sumário

## Introdução

O Markdown conquistou a escrita acadêmica por sua simplicidade: uma sintaxe minimalista que permite ao autor concentrar-se no conteúdo, não na formatação. Ferramentas como Limarka [limarka](@cite), Quarto [quarto](@cite) e RMarkdown prometem o melhor dos dois mundos—escrever em Markdown, obter documentos academicamente formatados. Porém, há um paradoxo fundamental: quase todas essas ferramentas dependem do `sigla: LaTeX (LTX)` como backend para geração de PDF. O autor escreve em Markdown, mas o "último quilômetro" é sempre LaTeX.

Essa dependência cria uma **abstração vazada**. Quando o documento requer formatação específica—margens ABNT, capas institucionais, fichas catalográficas—o autor é frequentemente forçado a injetar código LaTeX diretamente no Markdown, quebrando a promessa de separação entre conteúdo e apresentação. A necessidade de instalar uma distribuição TeX completa (aproximadamente 4GB) e eventualmente depurar erros crípticos de compilação LaTeX contradiz a simplicidade prometida pelo Markdown.

Há ainda o **problema do formato de saída**. LaTeX é amplamente utilizado na engenharia acadêmica—e praticamente só lá. Periódicos científicos aceitam submissões em Word. Escritórios de transferência tecnológica trabalham com Word. Equipes de P&D em indústria colaboram em Word. O documento que realmente circula, que é revisado por orientadores, avaliado por bancas e arquivado em repositórios institucionais, é quase sempre um arquivo `.docx`. LaTeX produz PDFs elegantes, mas PDFs são destinos finais—não documentos de trabalho.

O `sigla: Specdown (SDN)` propõe uma abordagem diferente: **eliminar completamente o LaTeX da cadeia de produção**. O pipeline Markdown → SQLite → Pandoc → `sigla: Office Open XML (OOXML)` gera documentos DOCX nativos, editáveis, e em conformidade com as normas ABNT—sem dependências pesadas ou conhecimento de LaTeX. Similar em objetivo ao `sigla: abnTeX (ABN)` [abntex2classe](@cite), mas fundamentalmente diferente em implementação.

O Specdown foi projetado originalmente para **engenharia de requisitos**—rastrear requisitos, casos de verificação e decisões de design em projetos de software crítico. Porém, ao tratar normas de publicação científica (como ABNT NBR 14724) como **especificações formais**, o sistema se adapta naturalmente à escrita acadêmica. O mesmo motor que valida rastreabilidade de requisitos valida a estrutura de uma monografia.

Essa convergência reflete uma verdade mais profunda: **documentação e relatórios são faces da mesma moeda**. Uma especificação de requisitos de software e uma dissertação de mestrado compartilham a necessidade de estrutura verificável, referências cruzadas consistentes, e conformidade com normas.

Este documento demonstra, de forma prática, como utilizar o Specdown para criar uma monografia. Cada seção é um exemplo vivo das funcionalidades disponíveis, conforme ilustra a [fig:capybara](#).

```fig:capybara{caption="Capivara descansando - exemplo de figura com legenda" source="Autor"}
capybara.jpg
```

### Por que Specdown?

O ecossistema de ferramentas Markdown para trabalhos acadêmicos—Limarka [limarka](@cite), Quarto [quarto](@cite), RMarkdown—compartilha uma característica comum: todas utilizam LaTeX como backend para geração de PDF. Isso significa que, apesar da simplicidade do Markdown na superfície, o autor ainda precisa de uma distribuição TeX completa instalada, e eventualmente precisará depurar erros de LaTeX quando a abstração "vazar".

O Specdown adota uma abordagem diferente: **não há LaTeX no pipeline**. O [listing:sintaxe-comparacao](#) ilustra a diferença de sintaxe entre LaTeX e Markdown:

```listing:sintaxe-comparacao{caption="Comparação de sintaxe: LaTeX vs Markdown" source="Elaboração própria"}
LATEX                                   MARKDOWN
──────────────────────────────────────────────────────────
\section{Introdução}                    ## Introdução
\textbf{texto em negrito}               **texto em negrito**
\textit{texto em itálico}               *texto em itálico*
\begin{itemize}                         
  \item item 1                          - item 1
  \item item 2                          - item 2
  \item item 3                          - item 3 
\end{itemize}
\begin{figure}[htbp]                   ```fig:id{caption="Legenda"}
  \centering                           imagem.jpg
  \includegraphics{imagem.jpg}         ```
  \caption{Legenda}
\end{figure}
\cite{autor2024}                       [autor2024](@cite)
```

As principais vantagens do Specdown incluem:

1. **Sem dependência LaTeX**: O pipeline utiliza exclusivamente Pandoc e OOXML—nenhuma distribuição TeX necessária
2. **Saída editável e colaborativa**: Diferentemente do PDF (formato de visualização), o DOCX permite controle de alterações, comentários em linha, e revisão por orientadores usando ferramentas familiares (Word, LibreOffice, Google Docs)
3. **Conformidade automática**: Pós-processamento OOXML aplica formatação ABNT (bordas de tabela IBGE, margens, numeração) conforme NBR 14724 [NBR14724:2011](@cite)
4. **Campos nativos**: Sumário, lista de figuras e tabelas usam campos do Word (atualização automática ao abrir o documento)
5. **Banco de dados**: Estrutura do documento em SQLite permite validação semântica e consultas para gráficos
6. **Citações bibliográficas**: Integração com Citeproc para referências no padrão ABNT [NBR6023:2018](@cite)

### Tipagem Forte vs Tipagem Fraca

No LaTeX, `\section{Introdução}` é um comando de formatação—nada impede `\section{Conclusão}` aparecer antes de `\section{Introdução}`. No Markdown puro, `## Introdução` é ainda mais genérico: um cabeçalho sem semântica alguma.

No Specdown, quando você escreve `## Introdução`, o sistema:

1. Reconhece o texto "Introdução" como **alias implícito** do tipo `INTRODUCTION`
2. Verifica que `INTRODUCTION` é **permitido** em especificações `MONOGRAFIA`
3. Valida que aparece **após** elementos pré-textuais
4. Garante que há **exatamente uma** introdução (`max_count: 1`)

Os tipos não são declarados em JSON—cada tipo ABNT é um módulo TypeScript em `types/objects/`, compilado para SQL no build. Por exemplo, o tipo `ABSTRACT` em `types/objects/abstract/schema.ts` define:

- `implicit_aliases`: ["Resumo", "Abstract", "Résumé"]
- `extends`: "PRE_TEXTUAL"
- `attributes`: [{ name: "keywords", type: "string" }]

Especificações bem tipadas não falham em tempo de compilação.

### Extensões ao Markdown

O Markdown original é deliberadamente minimalista—e essa simplicidade tem um custo. A especificação original não contempla tabelas, fórmulas matemáticas, referências cruzadas numeradas, nem figuras com legendas e fontes. Para escrita acadêmica, essas lacunas são críticas.

O Specdown estende o Markdown com sintaxe adicional para suprir essas necessidades:

- **Tabelas**: Sintaxes `list-table:` e `csv:` para tabelas complexas com cabeçalhos e alinhamento
- **Matemática**: Notação AsciiMath (mais legível que LaTeX) para equações inline e em bloco
- **Figuras numeradas**: Blocos `fig:` com legendas, fontes e numeração automática
- **Referências cruzadas**: Links `[type:identificador](#)` que se resolvem para "Figura 1", "Tabela 2", etc.
- **Quadros e listagens**: Blocos `listing:` e `src.<ext>:` para código com moldura ABNT
- **Gráficos**: Blocos `chart:` que consultam o banco de dados para gerar visualizações
- **Diagramas**: Blocos `puml:` para diagramas UML via PlantUML
- **Notas de rodapé**: Sintaxe nativa do Pandoc[^1] para notas de rodapé numeradas automaticamente

[^1]: Notas de rodapé são suportadas nativamente via Pandoc `commonmark_x`. Esta é uma nota de exemplo que aparecerá no rodapé da página.

As seções seguintes demonstram cada uma dessas extensões em uso prático.

### Estrutura deste Documento

Este tutorial segue a estrutura padrão de uma monografia conforme NBR 14724 [NBR14724:2011](@cite):

- **Elementos pré-textuais**: Capa, folha de rosto, resumo, listas, sumário
- **Elementos textuais**: Introdução, desenvolvimento, conclusão
- **Elementos pós-textuais**: Referências, apêndices, anexos

## Figuras e Ilustrações

As figuras são inseridas utilizando blocos de código com o prefixo `fig:` seguido de um identificador único. Os atributos `caption` e `source` definem a legenda e a fonte da ilustração.

### Sintaxe Básica

Para inserir uma figura:

    ```fig:identificador{caption="Legenda da figura" source="Fonte"}
    caminho/para/imagem.jpg
    ```

A legenda é posicionada abaixo da figura, seguida da fonte — conforme exige a ABNT.

### Gráficos

Gráficos são renderizados usando ECharts[^echarts], uma biblioteca de visualização de dados. O corpo do bloco contém a configuração JSON do gráfico, e os dados podem vir de duas fontes:

[^echarts]: Apache ECharts — biblioteca open-source para visualização interativa. Documentação em <https://echarts.apache.org>.

- **`query`**: consulta uma view SQL do banco de dados do documento
- **`generator`**: invoca uma função Lua que gera os dados programaticamente

A [chart:abnt-types](#) demonstra o uso de `query` — os dados vêm diretamente do próprio documento, mostrando a distribuição dos tipos ABNT utilizados nesta monografia:

```chart:abnt-types{query="abnt_types_summary" caption="Tipos ABNT utilizados neste documento"}
{
  "tooltip": {"trigger": "axis", "axisPointer": {"type": "shadow"}},
  "legend": {"data": ["Obrigatório", "Opcional"], "bottom": 0},
  "xAxis": {"type": "category", "axisLabel": {"fontSize": 10, "rotate": 15}},
  "yAxis": {"type": "value", "name": "Qtd"},
  "dataset": {},
  "series": [
    {"type": "bar", "stack": "total", "name": "Obrigatório", "encode": {"x": "category", "y": "obrigatorio_count"}, "itemStyle": {"color": "#5470c6"}},
    {"type": "bar", "stack": "total", "name": "Opcional", "encode": {"x": "category", "y": "opcional_count"}, "itemStyle": {"color": "#91cc75"}}
  ]
}
```

Para o template ABNT, geradores Lua são particularmente úteis para visualizar funções matemáticas — como a [chart:curva-gauss](#), que renderiza a distribuição normal a partir de parâmetros:

```chart:curva-gauss{generator="gaussian" mean="0" sigma="1" xmin="-3" xmax="3" points="61" caption="Distribuição Normal — gerada via Lua"}
{
  "tooltip": {"trigger": "axis"},
  "xAxis": {"type": "value", "name": "x", "min": -3, "max": 3},
  "yAxis": {"type": "value", "name": "f(x)", "min": 0, "max": 0.45},
  "series": [{
    "type": "line",
    "smooth": true,
    "symbol": "none",
    "lineStyle": {"width": 2, "color": "#5470c6"},
    "areaStyle": {"color": {"type": "linear", "x": 0, "y": 0, "x2": 0, "y2": 1, "colorStops": [{"offset": 0, "color": "rgba(84,112,198,0.5)"}, {"offset": 1, "color": "rgba(84,112,198,0.1)"}]}},
    "encode": {"x": "x", "y": "y"}
  }]
}
```

### Diagramas PlantUML

Diagramas `sigla: Unified Modeling Language (UML)` podem ser gerados a partir de código PlantUML. O sistema processa os diagramas em paralelo para melhor desempenho.

A [puml:fluxo-documento](#) ilustra o fluxo básico de criação de um documento:

```puml:fluxo-documento{caption="Fluxo de criação de documento acadêmico"}
@startuml
skinparam backgroundColor #FEFEFE

start
:Escrever conteúdo\nem Markdown;
:Definir metadados\n(título, autor, etc.);
:Executar build;

fork
  :Processar figuras;
fork again
  :Processar tabelas;
fork again
  :Processar citações;
end fork

:Gerar DOCX\nformatado;
stop
@enduml
```

### Atributos Comuns para Elementos Visuais

Os elementos `fig:`, `puml:` e `chart:` suportam atributos adicionais para controle de dimensões e fonte.

#### Dimensões (width e height)

Para controlar o tamanho dos elementos visuais:

    ```fig:exemplo{caption="Figura redimensionada" width="300" height="200"}
    imagem.jpg
    ```

- Valores numéricos são interpretados como pixels: `width="400"` → `400px`
- Unidades CSS são suportadas: `width="50%"`, `width="10cm"`, `height="3in"`
- Se apenas um atributo for informado, o outro é ajustado proporcionalmente (mantendo aspect ratio)
- Para gráficos (`chart:`), os valores padrão são 600×400 pixels
- Ambos os atributos são opcionais

#### Atributo source

O atributo `source` define a fonte da ilustração conforme ABNT:

```csv:source-syntax{caption="Sintaxe do atributo source"}
Sintaxe,Resultado
source="Autor",Fonte: Autor
source="@silva2024",Fonte: (SILVA 2024) — via citeproc
(omitido),Fonte: Elaborado pelo autor
```

- **Texto literal**: Renderiza como "Fonte: {texto}"
- **Citação BibTeX**: `source="@chave"` integra com citeproc, usando a formatação do arquivo CSL
- **Omitido**: Aplica automaticamente "Fonte: Elaborado pelo autor" (padrão ABNT)

Exemplo com citação bibliográfica:

    ```fig:grafico{caption="Dados estatísticos" source="@ibge1993"}
    dados.png
    ```

## Tabelas e Quadros

A ABNT distingue entre **tabelas** e **quadros** — uma distinção importante que o Specdown respeita.

### A Diferença

Conforme as normas de apresentação tabular do `sigla: Instituto Brasileiro de Geografia e Estatística (IBGE)` [ibge1993](@cite):

- **Tabela**: Apresenta dados numéricos/estatísticos. Formatação com bordas abertas nas laterais (sem linhas verticais nas extremidades).
- **Quadro**: Apresenta informações textuais organizadas. Formatação com bordas fechadas em todos os lados.

O [listing:diferenca-tabela-quadro](#) resume estas diferenças:

```listing:diferenca-tabela-quadro{caption="Diferença entre Tabela e Quadro conforme ABNT/IBGE" source="@ibge1993"}
TABELA
- Contém dados numéricos/estatísticos
- Bordas abertas nas laterais
- Linhas horizontais: topo, separador do cabeçalho, base
- Sem linhas verticais nas extremidades

QUADRO
- Contém informações textuais
- Bordas fechadas em todos os lados
- Grade completa (todas as células delimitadas)
- Usado para definições, comparações textuais
```

### Sintaxe list-table

A sintaxe `list-table` é ideal para tabelas complexas. A [list-table:elementos-pretextuais](#) demonstra uma tabela com múltiplas colunas:

```list-table:elementos-pretextuais{caption="Elementos pré-textuais conforme NBR 14724" source="@NBR14724:2011"}
> header-rows: 1
> aligns: l,c,l

* - Elemento
  - Obrigatório
  - Descrição
* - Capa
  - Sim
  - Identificação do trabalho
* - Folha de rosto
  - Sim
  - Dados essenciais do trabalho
* - Ficha catalográfica
  - Não
  - Verso da folha de rosto
* - Errata
  - Não
  - Lista de correções
* - Folha de aprovação
  - Sim*
  - Assinaturas da banca
* - Dedicatória
  - Não
  - Homenagem a pessoas
* - Agradecimentos
  - Não
  - Reconhecimento a contribuições
* - Epígrafe
  - Não
  - Citação relacionada ao tema
* - Resumo em português
  - Sim
  - Síntese do trabalho [NBR6028:2003](@cite)
* - Resumo em língua estrangeira
  - Sim
  - Abstract
* - Lista de ilustrações
  - Não
  - Índice de figuras
* - Lista de tabelas
  - Não
  - Índice de tabelas
* - Lista de abreviaturas
  - Não
  - Glossário de siglas
* - Sumário
  - Sim
  - Índice de conteúdo [NBR6027:2012](@cite)
```

### Sintaxe CSV

Para dados tabulares simples, a sintaxe CSV é mais concisa. A [csv:dados-regionais](#) demonstra:

```csv:dados-regionais{caption="Dados regionais — exemplo de tabela CSV" source="Dados fictícios"}
Região,2022,2023,2024
Norte,150,175,200
Nordeste,280,310,350
Centro-Oeste,120,140,160
Sudeste,450,520,580
Sul,200,230,260
```

### Quadros e Listagens de Código

O Specdown oferece duas sintaxes para criar quadros (código/listagens):

1. **`listing:label`** — Quadro genérico, sem realce de sintaxe. Ideal para texto estruturado, pseudocódigo ou informações textuais.

2. **`src.<ext>:label`** — Listagem com realce de sintaxe. O `<ext>` indica a linguagem (lua, c, python, js, etc.). Utiliza o Pandoc Skylighting para colorização.

Ambas as sintaxes suportam os atributos `caption` e `source`, e são renderizadas com moldura (borda) no template ABNT.

#### Quadro Textual (sem realce)

O [listing:vantagens-specdown](#) demonstra a sintaxe `listing:` para informações textuais:

```listing:vantagens-specdown{caption="Principais vantagens do Specdown" source="Elaboração própria"}
1. SINTAXE SIMPLES
   Markdown é intuitivo e legível mesmo em formato texto puro.
   Não requer conhecimento de LaTeX ou linguagens complexas.

2. CONFORMIDADE AUTOMÁTICA
   O template ABNT cuida de margens, fontes, espaçamentos.
   Validação estrutural impede documentos malformados.

3. EXTENSIBILIDADE
   Sistema de templates permite criar novos formatos.
   O template ABNT estende o template padrão (default).

4. INTEGRAÇÃO COM DADOS
   Gráficos podem consultar o banco de dados.
   Views SQL alimentam visualizações automaticamente.
```

#### Listagem de Código (com realce)

O [src.c:hello-world](#) demonstra a sintaxe `src.c:` para código-fonte com realce de sintaxe:

```src.c:hello-world{caption="Programa Hello World em C" source="Elaboração própria"}
#include <stdio.h>

int main(void) {
    printf("Hello, World!\n");
    return 0;
}
```

Outras linguagens suportadas incluem: `src.lua:`, `src.python:`, `src.java:`, `src.js:`, `src.sql:`, entre outras. A lista completa depende do Pandoc Skylighting.

### Equações e Fórmulas com AsciiMath

O Specdown utiliza AsciiMath para expressões matemáticas — uma sintaxe mais simples e legível que LaTeX. A [csv:asciimath-vs-latex](#) compara as duas notações:

```csv:asciimath-vs-latex{caption="Comparação entre AsciiMath e LaTeX" source="Elaboração própria"}
Expressão,AsciiMath,LaTeX
Fração,x/y,\\frac{x}{y}
Raiz quadrada,sqrt(x),\\sqrt{x}
Potência,x^2,x^{2}
Subscrito,x_i,x_{i}
Somatório,sum_(i=1)^n i,\\sum_{i=1}^{n} i
Integral,int_0^1 f(x) dx,\\int_{0}^{1} f(x) dx
Fórmula quadrática,(-b +- sqrt(b^2-4ac))/(2a),\\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}
```

#### Sintaxe Inline

Para inserir matemática no meio do texto, use a sintaxe `` `math: expressão` ``. Exemplos:

- O teorema de Pitágoras: `math: a^2 + b^2 = c^2`
- Área do círculo: `math: A = pi r^2`
- Somatório: `math: sum_(i=1)^n i = (n(n+1))/2`

#### Sintaxe em Bloco (Equação Numerada)

Para equações destacadas e numeradas, use:

```math:pitagoras{caption="Teorema de Pitágoras"}
a^2 + b^2 = c^2
```

A [math:pitagoras](#) demonstra o teorema fundamental da geometria euclidiana.

A fórmula quadrática de Bhaskara ([math:bhaskara](#)) fornece as raízes de equações do segundo grau:

```math:bhaskara{caption="Fórmula de Bhaskara"}
x = (-b +- sqrt(b^2 - 4ac)) / (2a)
```

A integral de Gauss ([math:gauss](#)) é fundamental na teoria das probabilidades e estatística:

```math:gauss{caption="Integral de Gauss"}
int_(-oo)^(oo) e^(-x^2) dx = sqrt(pi)
```
A entropia de Shannon ([math:shannon](#)) quantifica a informação média em uma fonte de dados:

```math:shannon{caption="Entropia de Shannon"}
H(X) = -sum_(i=1)^n p(x_i) log_2 p(x_i)
```

As equações demonstram a capacidade do Specdown de renderizar fórmulas matemáticas complexas usando notação AsciiMath, que é mais intuitiva que LaTeX para a maioria dos casos.

#### Referência Rápida AsciiMath

- Operações básicas: `+`, `-`, `*`, `/`, `=`, `!=`, `<`, `>`, `<=`, `>=`
- Símbolos gregos: `alpha`, `beta`, `gamma`, `delta`, `pi`, `theta`, `omega`
- Funções: `sin`, `cos`, `tan`, `log`, `ln`, `exp`, `sqrt`
- Agrupamento: parênteses `()`, colchetes `[]`, chaves `{}`
- Matrizes: `[[a,b],[c,d]]` para matriz 2x2

## Citações e Referências Bibliográficas

O Specdown utiliza Citeproc para processar citações—não o tradicional toolchain BibTeX/Biber do LaTeX. Essa escolha simplifica significativamente o fluxo de trabalho: um único arquivo `.bib` e um estilo CSL são suficientes, sem necessidade de múltiplas compilações ou arquivos auxiliares (`.aux`, `.bbl`, `.blg`, `.bcf`, `.run.xml`). O processamento segue as normas NBR 10520 [NBR10520:2002](@cite) e NBR 6023 [NBR6023:2018](@cite).

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

## Referências Cruzadas

O Specdown suporta referências cruzadas para figuras, tabelas, quadros e seções:

- Figuras: conforme demonstrado na [fig:capybara](#)
- Tabelas: os dados da [csv:dados-regionais](#) mostram...
- Quadros: o [listing:diferenca-tabela-quadro](#) explica...

A sintaxe usa `[type:identificador](#)`:

    Figura \[fig:id](#)
    Tabela \[csv:id](#)
    Quadro \[listing:id](#)

O sistema infere o **tipo de relação** (`XREF_FIGURE`, `XREF_TABLE`, `XREF_LISTING`, `XREF_MATH`) para cada elemento flutuante durante a compilação. O gráfico a seguir ([chart:xref-usage](#)) mostra a distribuição desses tipos por seção—dados extraídos diretamente do banco de dados do documento:

```chart:xref-usage{query="xref_usage" caption="Tipos XREF por Seção — inferência de relações em tempo de compilação" width=750 height=420}
{
  "title": {"text": "Seções → Tipos de Referência", "left": "center", "textStyle": {"fontSize": 15, "fontWeight": "normal", "color": "#333"}},
  "tooltip": {"trigger": "item", "formatter": "{b}: {c}"},
  "dataset": {},
  "color": ["#3b82f6", "#10b981", "#f59e0b", "#ef4444", "#8b5cf6", "#ec4899", "#06b6d4", "#84cc16", "#f97316", "#6366f1", "#14b8a6", "#a855f7", "#22c55e", "#eab308"],
  "series": [{
    "type": "sankey",
    "layout": "none",
    "left": "1%",
    "right": "12%",
    "top": "10%",
    "bottom": "3%",
    "nodeWidth": 14,
    "nodeGap": 12,
    "emphasis": {"focus": "adjacency", "itemStyle": {"shadowBlur": 10, "shadowColor": "rgba(0,0,0,0.3)"}},
    "lineStyle": {"color": "source", "opacity": 0.4, "curveness": 0.5},
    "label": {"fontSize": 13, "color": "#333"},
    "levels": [
      {"depth": 0, "label": {"position": "right"}},
      {"depth": 1, "label": {"position": "left"}}
    ]
  }]
}
```

## Siglas e Abreviaturas

O Specdown gerencia siglas automaticamente. Na primeira ocorrência, o termo completo é exibido com a sigla entre parênteses. Nas ocorrências seguintes, apenas a sigla aparece.

Para definir uma sigla, use:

    `sigla: Termo Completo (SIGLA)`

Ao longo deste documento, várias siglas foram utilizadas: ABNT, SDN, ECH, UML, IBGE. Todas aparecem automaticamente na Lista de Abreviaturas e Siglas.

## Peculiaridades das Normas ABNT

As normas ABNT para trabalhos acadêmicos incluem requisitos complexos que o Specdown implementa automaticamente.

### Numeração de Páginas

A NBR 14724 [NBR14724:2011](@cite) estabelece que os elementos pré-textuais são **contados, mas não numerados**. A numeração visível começa apenas na parte textual, em algarismos arábicos.

Curiosamente, o uso de algarismos romanos nos pré-textuais (i, ii, iii...) **não é exigido pela norma** — é uma adição de algumas instituições [abntex2wiki:romanos](@cite). O Specdown suporta ambas as configurações.

### Capítulos em Páginas Ímpares

Para impressão frente e verso, a norma exige que capítulos iniciem em páginas ímpares (lado direito do documento aberto). O Specdown insere automaticamente páginas em branco quando necessário.

### Margens Espelhadas

Para encadernação, as margens são espelhadas:
- Margem interna (encadernação): 3 cm
- Margem externa: 2 cm

### Formatação de Tabelas (Padrão IBGE)

Tabelas seguem o padrão do IBGE [ibge1993](@cite):
- Bordas abertas nas laterais
- Apenas linhas horizontais (topo, separador, base)
- Título acima da tabela
- Fonte abaixo

### Template Extensível

O template ABNT é apenas um exemplo das capacidades do Specdown. O sistema de extensões permite criar templates para qualquer padrão documental — `sigla: Institute of Electrical and Electronics Engineers (IEEE)`, `sigla: American Psychological Association (APA)`, normas corporativas, etc.

O template ABNT estende o template `default`, herdando funcionalidades como gráficos, PlantUML e tabelas (list-table, CSV, TSV), e adicionando tipos específicos para a estrutura acadêmica brasileira.

## Conclusão

Este documento demonstrou como utilizar o template ABNT do Specdown para criar trabalhos acadêmicos em conformidade com a NBR 14724 [NBR14724:2011](@cite). Através de exemplos práticos, foram apresentados:

1. Inserção de figuras com legendas padronizadas ([fig:capybara](#))
2. Gráficos com dados do banco ([chart:abnt-types](#))
3. Diagramas PlantUML ([puml:fluxo-documento](#))
4. Tabelas com sintaxe list-table ([list-table:elementos-pretextuais](#))
5. Tabelas com sintaxe CSV ([csv:dados-regionais](#))
6. Quadros para informações textuais ([listing:vantagens-specdown](#))
7. Citações bibliográficas conforme ABNT
8. Referências cruzadas automáticas
9. Gerenciamento de siglas

### Uma Mudança de Paradigma

Mais do que uma ferramenta de formatação, o Specdown representa uma mudança de paradigma na produção de documentos acadêmicos brasileiros. Ao eliminar o LaTeX do pipeline de geração, rompe-se com décadas de dependência de um ecossistema notoriamente complexo.

A própria nomenclatura do ecossistema TeX revela sua fragmentação: TeX é o sistema de tipografia original de Donald Knuth (1978); LaTeX é uma camada de macros sobre o TeX criada por Leslie Lamport; pdfTeX, XeTeX e LuaTeX são diferentes *engines* que processam o código-fonte; e distribuições como TeX Live e MiKTeX empacotam milhares de pacotes com dependências cruzadas. Para o usuário iniciante, a distinção entre esses componentes raramente é clara—e quando algo falha, a depuração exige conhecimento de múltiplas camadas.

Plataformas como Overleaf [overleaf](@cite) mitigaram parte dessa complexidade ao oferecer um ambiente web pré-configurado, democratizando o acesso ao LaTeX. Porém, ao custo de *lock-in*: o documento existe apenas na nuvem do fornecedor, e a colaboração depende de todos os participantes terem conta na plataforma.

O formato DOCX de saída do Specdown não é uma limitação, mas uma característica estratégica. Diferentemente do PDF—um formato de visualização, não de edição—o DOCX permite colaboração nativa: controle de alterações, comentários em linha, e revisão por orientadores e bancas usando ferramentas já instaladas em seus computadores (Microsoft Word, LibreOffice, Google Docs). Não há necessidade de instalar software especializado ou criar contas em plataformas proprietárias.

O Specdown automatiza a formatação e validação do documento, permitindo que o autor concentre-se no conteúdo.

### Documentação e Relatórios: A Linha que Desaparece

Ferramentas tradicionais separam **documentação** (conteúdo estático, escrito manualmente) de **relatórios** (conteúdo dinâmico, gerado de dados). O Specdown dissolve essa fronteira.

Neste documento, elementos como:

- `toc:` — sumário gerado automaticamente da estrutura
- `lof:` — lista de figuras extraída do banco de dados
- `sigla_list:` — lista de siglas populada durante a compilação
- `chart:abnt-types{query="..."}` — gráfico que consulta views SQL

...não são conteúdo estático. São **consultas materializadas** que se atualizam a cada build. O documento é simultaneamente **documentação** (texto autoral) e **relatório** (dados do sistema de tipos).

Essa fusão é possível porque o Specdown armazena tudo em SQLite: objetos, relações, atributos, hierarquias. Views SQL podem agregar, filtrar e projetar esses dados—e gráficos ECharts podem visualizá-los. O template apenas define **quais views existem** e **como renderizá-las**.

O mesmo mecanismo que gera "Lista de Figuras" numa monografia pode gerar "Matriz de Rastreabilidade" num SRS ou "Relatório de Cobertura" num TRR. A diferença é o template e as views—não o motor.

## Trabalhos Futuros

O desenvolvimento do Specdown segue duas direções prioritárias:

### Editor Colaborativo em Tempo Real

Integração com um editor web que permita múltiplos autores editarem o mesmo documento simultaneamente, similar à experiência do Google Docs ou Overleaf—mas com o documento-fonte em Markdown e armazenamento local ou em repositórios Git, evitando dependência de plataformas proprietárias.

### Interoperabilidade DOCX (Round-Trip)

Atualmente, o fluxo é unidirecional: Markdown → DOCX. Um objetivo futuro é suportar importação de arquivos DOCX existentes, convertendo-os para a estrutura Markdown do Specdown. Isso permitiria:

- Migrar trabalhos iniciados em Word para o ecossistema Specdown
- Incorporar revisões feitas diretamente no DOCX de volta ao fonte Markdown
- Ciclos iterativos de edição (*round-trip*) sem perda de formatação semântica

Essa interoperabilidade bidirecional eliminaria a principal barreira de adoção: a necessidade de começar do zero em uma nova ferramenta.

## Referências

<!-- Bibliografia gerada automaticamente via citeproc a partir de references.bib -->

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

### Listas Automáticas

    `toc:`        — Sumário
    `lof:`        — Lista de figuras
    `lot:`        — Lista de tabelas
    `sigla_list:` — Lista de siglas

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

## ANNEX: Normas ABNT Consultadas

Lista das normas da ABNT consultadas para desenvolvimento do template [NBR14724:2011;NBR14724:2024;NBR6023:2018;NBR6028:2003;NBR6027:2012;NBR6024:2012;NBR10520:2002](@cite):

- **NBR 14724:2011** — Trabalhos acadêmicos — Apresentação
- **NBR 14724:2024** — Trabalhos acadêmicos — Apresentação (atualização)
- **NBR 6023:2018** — Referências — Elaboração
- **NBR 6028:2003** — Resumo — Apresentação
- **NBR 6027:2012** — Sumário — Apresentação
- **NBR 6024:2012** — Numeração progressiva das seções
- **NBR 10520:2002** — Citações em documentos
