## Peculiaridades das Normas ABNT

As normas ABNT para trabalhos acadêmicos incluem requisitos complexos que o SpecCompiler implementa automaticamente.

### Numeração de Páginas

A NBR 14724 [NBR14724:2011](@cite) estabelece que os elementos pré-textuais são **contados, mas não numerados**. A numeração visível começa apenas na parte textual, em algarismos arábicos.

Curiosamente, o uso de algarismos romanos nos pré-textuais (i, ii, iii...) **não é exigido pela norma** — é uma adição de algumas instituições [abntex2wiki:romanos](@cite). O SpecCompiler suporta ambas as configurações.

### Capítulos em Páginas Ímpares

Para impressão frente e verso, a norma exige que capítulos iniciem em páginas ímpares (lado direito do documento aberto). O SpecCompiler insere automaticamente páginas em branco quando necessário.

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

O template ABNT é apenas um exemplo das capacidades do SpecCompiler. O sistema de extensões permite criar templates para qualquer padrão documental — `sigla: Institute of Electrical and Electronics Engineers (IEEE)`, `sigla: American Psychological Association (APA)`, normas corporativas, etc.

O template ABNT estende o template `default`, herdando funcionalidades como gráficos, PlantUML e tabelas (list-table, CSV, TSV), e adicionando tipos específicos para a estrutura acadêmica brasileira.
