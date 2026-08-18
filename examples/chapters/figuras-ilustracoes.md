## Figuras e Ilustrações

As figuras são inseridas utilizando blocos de código com o prefixo `fig:` seguido de um identificador único. Os atributos `caption` e `source` definem a legenda e a fonte da ilustração.

### Sintaxe Básica

Para inserir uma figura:

    ```fig:identificador{caption="Legenda da figura" source="Fonte"}
    caminho/para/imagem.jpg
    ```

A legenda é posicionada abaixo da figura, seguida da fonte — conforme exige a ABNT.

Quando a imagem original é alta demais para a página, limite a altura diretamente nos
atributos do bloco. A largura será ajustada proporcionalmente pelo processador DOCX:

    ```fig:identificador-limitado{caption="Legenda da figura limitada" source="Fonte" height="5cm"}
    caminho/para/imagem.jpg
    ```

A [fig:capybara-limitada](#) usa a mesma imagem do exemplo inicial, mas com altura
máxima definida para deixar mais espaço para texto, legenda e fonte na página.

```fig:capybara-limitada{caption="Capivara com altura limitada para composição da página" source="Autor" height="5cm"}
../assets/capybara.jpg
```

### Gráficos

Gráficos são renderizados usando ECharts[^echarts], uma biblioteca de visualização de dados. O corpo do bloco contém a configuração JSON do gráfico, e os dados podem vir de duas fontes:

- **`generator`** (ou `view`): invoca um módulo Lua que calcula os dados programaticamente
- **`query`**: consulta uma view SQL sobre o banco de dados do próprio documento

[^echarts]: Apache ECharts — biblioteca open-source para visualização interativa. Documentação em <https://echarts.apache.org>.

O capítulo *Referências Cruzadas* demonstra a segunda forma, com um gráfico
alimentado pelas relações extraídas deste documento.

#### Geradores Lua para Funções Matemáticas

Geradores Lua são particularmente úteis para visualizar funções matemáticas. Cada gerador implementa uma função específica e pode ser invocado via atributo `generator` ou `view` no bloco de código do gráfico.

**Como criar um novo gerador:**

Um gerador é um módulo Lua em `types/views/` que segue este padrão:

```lua
return {
    kind = "view",
    schema = {
        id = "ID_UNICO",                    -- Identificador em maiúsculas
        long_name = "Nome Descritivo",
        description = "O que faz",
        inline_prefix = "prefixo",          -- Sintaxe inline: `prefixo: param=valor`
        aliases = { "alias1", "alias2" },   -- Nomes alternativos
    },
    hooks = {
        render = function(ctx)              -- Para uso inline
            -- Renderiza resumo de parâmetros
        end,
        dataset = function(dctx)            -- Para dados do gráfico
            local params = dctx.subject.params or {}
            -- Processar params, calcular função, retornar dados
            return { source = {{ "x", "y" }, {x1, y1}, ... } }
        end,
    },
}
```

**Exemplo: Distribuição Normal**

A [chart:curva-gauss](#) renderiza a distribuição normal a partir de parâmetros:

```chart:curva-gauss{generator="gauss" mean="0" sigma="1" xmin="-3" xmax="3" points="61" caption="Distribuição Normal — gerada via Lua" height="5cm"}
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

**Exemplo: Decaimento Exponencial**

A [chart:curva-exponencial](#) implementa uma nova função de decaimento exponencial (`f(x) = e^(-λx) + offset`):

```chart:curva-exponencial{generator="exponential" lambda="0.5" offset="0" xmin="0" xmax="10" points="81" caption="Decaimento Exponencial — f(x) = e^(-0.5x)" height="5cm"}
{
  "tooltip": {"trigger": "axis"},
  "xAxis": {"type": "value", "name": "x", "min": 0, "max": 10},
  "yAxis": {"type": "value", "name": "f(x)", "min": 0, "max": 1.1},
  "series": [{
    "type": "line",
    "smooth": true,
    "symbol": "none",
    "lineStyle": {"width": 2, "color": "#91cc75"},
    "areaStyle": {"color": {"type": "linear", "x": 0, "y": 0, "x2": 0, "y2": 1, "colorStops": [{"offset": 0, "color": "rgba(145,204,117,0.5)"}, {"offset": 1, "color": "rgba(145,204,117,0.1)"}]}},
    "encode": {"x": "x", "y": "y"}
  }]
}
```

### Diagramas PlantUML

Diagramas `sigla: Unified Modeling Language (UML)` podem ser gerados a partir de código PlantUML. O sistema processa os diagramas em paralelo para melhor desempenho.

A [puml:fluxo-documento](#) ilustra o fluxo básico de criação de um documento:

```puml:fluxo-documento{caption="Fluxo de criação de documento acadêmico" height="4cm"}
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

```fig:grafico{caption="Capivara — exemplo de figura com fonte por citação" source="@ibge1993"}
../assets/capybara.jpg
```
