## Tabelas, Quadros e Listagens

A ABNT distingue **tabela** de **quadro**. O SpecCompiler trata essa distinção como
tipos diferentes — não como uma opção de formatação — e acrescenta um terceiro tipo,
a **listagem**, para código e texto preformatado.

Cada um tem legenda, contador e lista pré-textual próprios.

### A Diferença

Conforme as normas de apresentação tabular do `sigla: Instituto Brasileiro de Geografia e Estatística (IBGE)` [ibge1993](@cite):

- **Tabela**: dados numéricos ou estatísticos. Bordas abertas nas laterais — apenas
  linhas horizontais no topo, sob o cabeçalho e na base (estilo de três linhas).
- **Quadro**: informações textuais. Bordas fechadas nos quatro lados e grade
  completa, com todas as células delimitadas.

A [listing:diferenca-tabela-quadro](#) resume as duas formatações:

```listing:diferenca-tabela-quadro{caption="Diferença entre Tabela e Quadro conforme ABNT/IBGE" source="@ibge1993"}
TABELA                                  QUADRO
──────────────────────────────────────  ──────────────────────────────────────
Dados numéricos/estatísticos            Informações textuais
Bordas abertas nas laterais             Bordas fechadas nos quatro lados
Só linhas horizontais                   Grade completa (todas as células)
Legenda "Tabela N"                      Legenda "Quadro N"
```

### Escolhendo o Tipo

Cada sintaxe tem um padrão que corresponde ao seu uso mais comum, e uma variante
para o caso oposto. O [list-table:sintaxes-tabulares](#) resume o mapeamento:

```list-table:sintaxes-tabulares{caption="Sintaxes tabulares e a formatação resultante" source="Elaboração própria"}
> header-rows: 1
> aligns: l,l,l

* - Sintaxe
  - Resultado
  - Quando usar
* - `csv:`
  - Tabela
  - Dados numéricos em formato CSV
* - `csv-q:`
  - Quadro
  - Informações textuais em formato CSV
* - `list-table:`
  - Quadro
  - Informações textuais em múltiplas colunas
* - `list-table-t:`
  - Tabela
  - Dados numéricos em formato list-table
* - `listing:` / `src.<ext>:`
  - Listagem
  - Código ou texto preformatado, com moldura
```

O padrão segue a natureza de cada sintaxe: CSV nasceu para dados numéricos, e a
sintaxe `list-table` existe justamente para células com texto longo. As variantes
`csv-q:` e `list-table-t:` cobrem as exceções.

Os três tipos são numerados de forma independente: `Tabela 1`, `Quadro 1` e
`Listagem 1` podem coexistir. Cada um alimenta sua própria lista pré-textual —
Lista de Tabelas, Lista de Quadros e Lista de Listagens.

### Sintaxe CSV — Tabela

Para dados numéricos, a sintaxe CSV é a mais concisa. A [csv:dados-regionais](#)
renderiza como tabela, com as laterais abertas:

```csv:dados-regionais{caption="Dados regionais — exemplo de tabela CSV" source="Dados fictícios"}
Região,2022,2023,2024
Norte,150,175,200
Nordeste,280,310,350
Centro-Oeste,120,140,160
Sudeste,450,520,580
Sul,200,230,260
```

### Sintaxe list-table — Quadro

A sintaxe `list-table` acomoda células com texto longo, e por isso renderiza como
quadro. Cada linha começa com `* -` e cada célula seguinte com `-`. As linhas
iniciadas por `>` configuram a tabela.

O [list-table:elementos-pretextuais](#) demonstra a estrutura completa:

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
  - Sim
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

Os parâmetros de configuração aceitos são `header-rows` (quantas linhas iniciais
formam o cabeçalho), `aligns` (alinhamento por coluna: `l`, `c` ou `r`) e
`widths` (larguras relativas).

### Listagens

Uma **listagem** é um bloco de texto preformatado com moldura, onde as quebras de
linha têm significado — código-fonte, pseudocódigo, saída de terminal, diagramas
em ASCII. Diferente do quadro, não tem células.

Há duas sintaxes:

1. **`listing:label`** — sem realce de sintaxe. Para texto estruturado, pseudocódigo
   ou blocos que não são de nenhuma linguagem em particular.

2. **`src.<ext>:label`** — com realce de sintaxe. O `<ext>` indica a linguagem
   (`lua`, `c`, `python`, `js`, `sql`…), colorizada via Pandoc Skylighting.

Ambas aceitam `caption` e `source`, e recebem moldura no template ABNT.

#### Listagem Textual (sem realce)

A [listing:vantagens-specdown](#) demonstra a sintaxe `listing:` para texto estruturado:

```listing:vantagens-specdown{caption="Principais vantagens do SpecCompiler" source="Elaboração própria"}
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

A [src.c:hello-world](#) demonstra a sintaxe `src.c:` para código-fonte com realce de sintaxe:

```src.c:hello-world{caption="Programa Hello World em C" source="Elaboração própria"}
#include <stdio.h>

int main(void) {
    printf("Hello, World!\n");
    return 0;
}
```

Outras linguagens suportadas incluem `src.lua:`, `src.python:`, `src.java:`, `src.js:` e `src.sql:`. A lista completa depende do Pandoc Skylighting.

### Variantes: Invertendo o Padrão

Quando o conteúdo não segue a natureza da sintaxe, use a variante. O
[csv-q:estilos-markdown](#) usa CSV para informação textual, e por isso pede
`csv-q:` para sair com grade completa:

```csv-q:estilos-markdown{caption="Estilos de formatação em Markdown" source="Elaboração própria"}
Sintaxe,Descrição
**Negrito**,Ênfase forte
*Itálico*,Ênfase leve
`Código`,Elemento de código inline
[Link](url),Hiperlink
```

Na direção oposta, dados numéricos às vezes precisam da sintaxe `list-table` por
uma razão prática: **em português o separador decimal é a vírgula**, que também
separa os campos do CSV. Escrito sem aspas, `3,0` vira duas colunas — e o valor
excedente é descartado silenciosamente:

    Elemento,Medida
    Superior,3,0        → a célula vira "3"; o ",0" se perde
    Superior,"3,0"      → correto, mas exige aspas em cada valor

A [list-table-t:medidas-margens](#) evita o conflito de vez, e `list-table-t:`
garante a formatação de tabela:

```list-table-t:medidas-margens{caption="Margens e recuos exigidos pela NBR 14724" source="@NBR14724:2011"}
> header-rows: 1
> aligns: l,r,r

* - Elemento
  - Medida (cm)
  - Tolerância (cm)
* - Margem superior
  - 3,0
  - 0,5
* - Margem inferior
  - 2,0
  - 0,5
* - Margem esquerda
  - 3,0
  - 0,5
* - Margem direita
  - 2,0
  - 0,5
* - Recuo de parágrafo
  - 1,25
  - 0,25
```

### Equações e Fórmulas com AsciiMath

O SpecCompiler utiliza AsciiMath para expressões matemáticas — uma sintaxe mais simples e legível que LaTeX. A [csv:asciimath-vs-latex](#) compara as duas notações:

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

As equações demonstram a capacidade do SpecCompiler de renderizar fórmulas matemáticas complexas usando notação AsciiMath, que é mais intuitiva que LaTeX para a maioria dos casos.

#### Referência Rápida AsciiMath

- Operações básicas: `+`, `-`, `*`, `/`, `=`, `!=`, `<`, `>`, `<=`, `>=`
- Símbolos gregos: `alpha`, `beta`, `gamma`, `delta`, `pi`, `theta`, `omega`
- Funções: `sin`, `cos`, `tan`, `log`, `ln`, `exp`, `sqrt`
- Agrupamento: parênteses `()`, colchetes `[]`, chaves `{}`
- Matrizes: `[[a,b],[c,d]]` para matriz 2x2
