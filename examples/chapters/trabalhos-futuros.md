## Trabalhos Futuros

O desenvolvimento do SpecCompiler segue duas direções prioritárias:

### Editor Colaborativo em Tempo Real

Integração com um editor web que permita múltiplos autores editarem o mesmo documento simultaneamente, similar à experiência do Google Docs ou Overleaf—mas com o documento-fonte em Markdown e armazenamento local ou em repositórios Git, evitando dependência de plataformas proprietárias.

### Interoperabilidade DOCX (Round-Trip)

Atualmente, o fluxo é unidirecional: Markdown → DOCX. Um objetivo futuro é suportar importação de arquivos DOCX existentes, convertendo-os para a estrutura Markdown do SpecCompiler. Isso permitiria:

- Migrar trabalhos iniciados em Word para o ecossistema SpecCompiler
- Incorporar revisões feitas diretamente no DOCX de volta ao fonte Markdown
- Ciclos iterativos de edição (*round-trip*) sem perda de formatação semântica

Essa interoperabilidade bidirecional eliminaria a principal barreira de adoção: a necessidade de começar do zero em uma nova ferramenta.
