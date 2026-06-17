## Tabelas e Quadros

A ABNT distingue entre **tabelas** e **quadros** — uma distinção importante que o SpecCompiler respeita.

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

O SpecCompiler oferece duas sintaxes para criar quadros (código/listagens):

1. **`listing:label`** — Quadro genérico, sem realce de sintaxe. Ideal para texto estruturado, pseudocódigo ou informações textuais.

2. **`src.<ext>:label`** — Listagem com realce de sintaxe. O `<ext>` indica a linguagem (lua, c, python, js, etc.). Utiliza o Pandoc Skylighting para colorização.

Ambas as sintaxes suportam os atributos `caption` e `source`, e são renderizadas com moldura (borda) no template ABNT.

#### Quadro Textual (sem realce)

O [listing:vantagens-specdown](#) demonstra a sintaxe `listing:` para informações textuais:

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
