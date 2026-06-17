## Conclusão

Este documento demonstrou como utilizar o template ABNT do SpecCompiler para criar trabalhos acadêmicos em conformidade com a NBR 14724 [NBR14724:2011](@cite). Através de exemplos práticos, foram apresentados:

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

Mais do que uma ferramenta de formatação, o SpecCompiler representa uma mudança de paradigma na produção de documentos acadêmicos brasileiros. Ao eliminar o LaTeX do pipeline de geração, rompe-se com décadas de dependência de um ecossistema notoriamente complexo.

A própria nomenclatura do ecossistema TeX revela sua fragmentação: TeX é o sistema de tipografia original de Donald Knuth (1978); LaTeX é uma camada de macros sobre o TeX criada por Leslie Lamport; pdfTeX, XeTeX e LuaTeX são diferentes *engines* que processam o código-fonte; e distribuições como TeX Live e MiKTeX empacotam milhares de pacotes com dependências cruzadas. Para o usuário iniciante, a distinção entre esses componentes raramente é clara—e quando algo falha, a depuração exige conhecimento de múltiplas camadas.

Plataformas como Overleaf [overleaf](@cite) mitigaram parte dessa complexidade ao oferecer um ambiente web pré-configurado, democratizando o acesso ao LaTeX. Porém, ao custo de *lock-in*: o documento existe apenas na nuvem do fornecedor, e a colaboração depende de todos os participantes terem conta na plataforma.

O formato DOCX de saída do SpecCompiler não é uma limitação, mas uma característica estratégica. Diferentemente do PDF—um formato de visualização, não de edição—o DOCX permite colaboração nativa: controle de alterações, comentários em linha, e revisão por orientadores e bancas usando ferramentas já instaladas em seus computadores (Microsoft Word, LibreOffice, Google Docs). Não há necessidade de instalar software especializado ou criar contas em plataformas proprietárias.

O SpecCompiler automatiza a formatação e validação do documento, permitindo que o autor concentre-se no conteúdo.

### Documentação e Relatórios: A Linha que Desaparece

Ferramentas tradicionais separam **documentação** (conteúdo estático, escrito manualmente) de **relatórios** (conteúdo dinâmico, gerado de dados). O SpecCompiler dissolve essa fronteira.

Neste documento, elementos como:

- a seção `## Sumário` — sumário gerado automaticamente da estrutura
- a seção `## Lista de Figuras` — lista de figuras extraída do banco de dados
- a seção `## Lista de Siglas` — lista de siglas populada durante a compilação
- `chart:abnt-types{query="..."}` — gráfico que consulta views SQL

...não são conteúdo estático. São **consultas materializadas** que se atualizam a cada build. O documento é simultaneamente **documentação** (texto autoral) e **relatório** (dados do sistema de tipos).

Essa fusão é possível porque o SpecCompiler armazena tudo em SQLite: objetos, relações, atributos, hierarquias. Views SQL podem agregar, filtrar e projetar esses dados—e gráficos ECharts podem visualizá-los. O template apenas define **quais views existem** e **como renderizá-las**.

O mesmo mecanismo que gera "Lista de Figuras" numa monografia pode gerar "Matriz de Rastreabilidade" num SRS ou "Relatório de Cobertura" num TRR. A diferença é o template e as views—não o motor.
