## Referências Cruzadas

O SpecCompiler suporta referências cruzadas para figuras, tabelas, quadros,
equações e seções. O texto exibido ("Figura 1", "Quadro 3") é resolvido na
compilação — nunca digitado à mão:

- Figuras: conforme demonstrado na [fig:capybara](#)
- Tabelas: os dados da [csv:dados-regionais](#) mostram a evolução regional
- Quadros: o [list-table:elementos-pretextuais](#) enumera os elementos
- Listagens: a [listing:diferenca-tabela-quadro](#) contrasta as duas formatações
- Equações: a [math:bhaskara](#) resolve o segundo grau

A sintaxe usa `[prefixo:identificador](#)`, onde o prefixo é o tipo do bloco
referenciado:

    [fig:id](#)            → Figura N
    [csv:id](#)            → Tabela N
    [list-table:id](#)     → Quadro N
    [listing:id](#)        → Listagem N
    [math:id](#)           → Equação N
    [chart:id](#)          → Gráfico N

Qualquer alias do tipo funciona como prefixo: `[tab:id](#)` e `[csv:id](#)`
apontam para o mesmo tipo Tabela.

O sistema infere o **tipo de relação** (`XREF_FIGURE`, `XREF_TABLE`, `XREF_QUADRO`, `XREF_LISTING`, `XREF_MATH`) para cada elemento flutuante durante a compilação. Referências não resolvidas interrompem o build, o que impede legendas órfãs no documento final. O gráfico a seguir ([chart:xref-usage](#)) mostra a distribuição desses tipos por seção—dados extraídos diretamente do banco de dados do documento:

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
