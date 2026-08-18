## Introdução

Este documento demonstra, de forma prática, como utilizar o SpecCompiler para criar uma monografia. Cada seção é um exemplo vivo das funcionalidades disponíveis, conforme ilustra a [fig:capybara](#).

```fig:capybara{caption="Capivara descansando - exemplo de figura com legenda" source="Autor"}
../assets/capybara.jpg
```

### Por que SpecCompiler?

O ecossistema de ferramentas Markdown para trabalhos acadêmicos—Limarka [limarka](@cite), Quarto [quarto](@cite), RMarkdown—compartilha uma característica comum, todas utilizam LaTeX como backend para geração de PDF. Isso significa que, apesar da simplicidade do Markdown na superfície, o autor ainda precisa de uma distribuição TeX completa instalada, e eventualmente precisará depurar erros de LaTeX quando a abstração "vazar".

O SpecCompiler adota uma abordagem diferente, não há LaTeX no pipeline. A [listing:sintaxe-comparacao](#) ilustra a diferença de sintaxe entre LaTeX e Markdown:

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

As principais funcionalidades do SpecCompiler incluem:

1. **Sem dependência LaTeX**: O pipeline utiliza exclusivamente Pandoc e OOXML—nenhuma distribuição TeX necessária
2. **Saída editável e colaborativa**: Diferentemente do PDF (formato de visualização), o DOCX permite controle de alterações, comentários em linha, e revisão por orientadores usando ferramentas familiares (Word, LibreOffice, Google Docs)
3. **Banco de dados**: Estrutura do documento em SQLite permite validação semântica e consultas.
4. **Citações bibliográficas**: Integração com Citeproc para referências no padrão ABNT [NBR6023:2018](@cite)

### Extensões ao Markdown

O Markdown original é deliberadamente minimalista—e essa simplicidade tem um custo. A especificação original não contempla tabelas, fórmulas matemáticas, referências cruzadas numeradas, nem figuras com legendas e fontes. Para escrita acadêmica, essas lacunas são críticas.

O SpecCompiler estende o Markdown com sintaxe adicional para suprir essas necessidades:

- **Tabelas e quadros**: Sintaxes `csv:` e `list-table:`, com a distinção ABNT entre tabela (dados numéricos) e quadro (informação textual)
- **Matemática**: Notação AsciiMath para equações inline e em bloco
- **Figuras numeradas**: Blocos `fig:` com legendas, fontes e numeração automática
- **Referências cruzadas**: Links `[prefixo:identificador](#)` que se resolvem para "Figura 1", "Quadro 2", "Tabela 3", etc.
- **Listagens**: Blocos `listing:` e `src.<ext>:` para texto e código com moldura ABNT, com contador e lista próprios
- **Gráficos**: Blocos `chart:` alimentados por geradores Lua ou por views SQL do documento
- **Diagramas**: Blocos `puml:` para diagramas UML via PlantUML
- **Inclusão de arquivos**: Blocos `include` para dividir documentos longos em capítulos e apêndices separados
- **Notas de rodapé**: Sintaxe nativa do Pandoc[^1] para notas de rodapé numeradas automaticamente

[^1]: Notas de rodapé são suportadas nativamente via Pandoc `commonmark_x`. Esta é uma nota de exemplo que aparecerá no rodapé da página.

As seções seguintes demonstram essas extensões em uso prático.

### Estrutura deste Documento

Este tutorial segue a estrutura padrão de uma monografia conforme NBR 14724 [NBR14724:2011](@cite):

- **Elementos pré-textuais**: Capa, folha de rosto, resumo, listas, sumário
- **Elementos textuais**: Introdução, desenvolvimento, conclusão
- **Elementos pós-textuais**: Referências, apêndices, anexos
