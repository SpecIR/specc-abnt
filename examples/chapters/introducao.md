## Introdução

O Markdown conquistou a escrita acadêmica por sua simplicidade. Uma sintaxe minimalista que permite ao autor concentrar-se no conteúdo, não na formatação. Ferramentas como Limarka [limarka](@cite), Quarto [quarto](@cite) e RMarkdown prometem o melhor dos dois mundos—escrever em Markdown, obter documentos academicamente formatados. Porém, há um paradoxo fundamental, todas essas ferramentas dependem do LaTeX como backend para geração de PDF.

Essa dependência cria uma **abstração vazada**. Quando o documento requer formatação específica —margens ABNT, capas institucionais, fichas catalográficas— o autor é frequentemente forçado a injetar código LaTeX diretamente no Markdown, quebrando a promessa de separação entre conteúdo e apresentação. A necessidade de instalar uma distribuição TeX completa (aproximadamente 4GB) e eventualmente depurar erros crípticos de compilação LaTeX contradiz a simplicidade prometida pelo Markdown.

Há ainda o problema do formato de saída. LaTeX é amplamente utilizado na engenharia acadêmica — e praticamente só lá. Periódicos científicos (de outras áreas) normalmente aceitam submissões em Word. Escritórios de transferência tecnológica trabalham com Word. Equipes de P&D em indústria colaboram em Word. O documento que realmente circula, é quase sempre um arquivo `.docx`. LaTeX produz PDFs elegantes, mas PDFs são destinos finais — não documentos de trabalho.

O `sigla: SpecCompiler (specc)` propõe uma abordagem diferente: **eliminar completamente o LaTeX da cadeia de produção**. O pipeline Markdown → specc → `sigla: Office Open XML (OOXML)` gera documentos DOCX nativos, editáveis, e em conformidade com as normas ABNT. Similar em objetivo e resultados ao (ABNabnTeX) [abntex2classe](@cite), mas fundamentalmente diferente em implementação.

O SpecCompiler foi projetado originalmente para **engenharia de requisitos** — rastrear requisitos, casos de verificação e decisões de design em projetos de software crítico. Porém, ao tratar normas de publicação científica (como ABNT NBR 14724) como **especificações formais**, o sistema se adapta naturalmente à escrita acadêmica. O mesmo motor que valida rastreabilidade de requisitos valida a estrutura de uma monografia.

Essa convergência reflete uma verdade mais profunda: **documentação e relatórios são faces da mesma moeda**. Uma especificação de requisitos de software e uma dissertação de mestrado compartilham a necessidade de estrutura verificável, referências cruzadas consistentes, e conformidade com normas.

Este documento demonstra, de forma prática, como utilizar o SpecCompiler para criar uma monografia. Cada seção é um exemplo vivo das funcionalidades disponíveis, conforme ilustra a [fig:capybara](#).

```fig:capybara{caption="Capivara descansando - exemplo de figura com legenda" source="Autor"}
../assets/capybara.jpg
```

### Por que SpecCompiler?

O ecossistema de ferramentas Markdown para trabalhos acadêmicos—Limarka [limarka](@cite), Quarto [quarto](@cite), RMarkdown—compartilha uma característica comum, todas utilizam LaTeX como backend para geração de PDF. Isso significa que, apesar da simplicidade do Markdown na superfície, o autor ainda precisa de uma distribuição TeX completa instalada, e eventualmente precisará depurar erros de LaTeX quando a abstração "vazar".

O SpecCompiler adota uma abordagem diferente, não há LaTeX no pipeline. O [listing:sintaxe-comparacao](#) ilustra a diferença de sintaxe entre LaTeX e Markdown:

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
3. **Conformidade automática**: Pós-processamento OOXML aplica formatação ABNT (bordas de tabela IBGE, margens, numeração) conforme NBR 14724 [NBR14724:2011](@cite)
4. **Campos nativos**: Sumário, lista de figuras e tabelas usam campos do Word (atualização automática ao abrir o documento)
5. **Banco de dados**: Estrutura do documento em SQLite permite validação semântica e consultas para gráficos
6. **Citações bibliográficas**: Integração com Citeproc para referências no padrão ABNT [NBR6023:2018](@cite)

### Tipagem Forte vs Tipagem Fraca

No LaTeX, `\section{Introdução}` é um comando de formatação—nada impede `\section{Conclusão}` aparecer antes de `\section{Introdução}`. No Markdown puro, `## Introdução` é ainda mais genérico: um cabeçalho sem semântica alguma.

No SpecCompiler, quando você escreve `## Introdução`, o sistema:

1. Reconhece o texto "Introdução" como **alias implícito** do tipo `INTRODUCTION`
2. Verifica que `INTRODUCTION` é **permitido** em especificações `MONOGRAFIA`
3. Valida que aparece **após** elementos pré-textuais
4. Garante que há **exatamente uma** introdução (`max_count: 1`)

Cada tipo ABNT é um módulo Lua em `types/objects/`, carregado no build e compilado para o Spec-IR (SQLite). Por exemplo, o tipo `ABSTRACT` em `types/objects/abstract.lua` define:

- `implicit_aliases`: ["Resumo", "Abstract", "Resume", "Resumen"]
- `extends`: "PRE_TEXTUAL"
- `attributes`: [{ name: "keywords", type: "STRING" }]

Especificações bem tipadas não falham.

### Extensões ao Markdown

O Markdown original é deliberadamente minimalista—e essa simplicidade tem um custo. A especificação original não contempla tabelas, fórmulas matemáticas, referências cruzadas numeradas, nem figuras com legendas e fontes. Para escrita acadêmica, essas lacunas são críticas.

O SpecCompiler estende o Markdown com sintaxe adicional para suprir essas necessidades:

- **Tabelas**: Sintaxes `list-table:` e `csv:` para tabelas complexas com cabeçalhos e alinhamento
- **Matemática**: Notação AsciiMath (mais legível que LaTeX) para equações inline e em bloco
- **Figuras numeradas**: Blocos `fig:` com legendas, fontes e numeração automática
- **Referências cruzadas**: Links `[type:identificador](#)` que se resolvem para "Figura 1", "Tabela 2", etc.
- **Quadros e listagens**: Blocos `listing:` e `src.<ext>:` para código com moldura ABNT
- **Gráficos**: Blocos `chart:` que consultam o banco de dados para gerar visualizações
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
