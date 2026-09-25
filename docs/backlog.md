# Backlog de produto — Lembretes

Atualizado em 25/09/2026. Origem: [análise de produto e experiência](product-analysis.md). As tarefas abaixo são propostas. Conclusões são registradas junto às tarefas; as demais continuam pendentes. P0 trata confiança e bloqueios; P1 melhora o fluxo principal; P2 amplia usos após estabilização.

## Visão geral

| ID | Prioridade | Tarefa | Esforço relativo | Depende de |
| --- | --- | --- | --- | --- |
| BL-01 | P0 | Editar item atrasado sem mudar horário | Pequeno | — |
| BL-02 | P0 | Abrir a lista quando notificações falharem | Médio | — |
| BL-03 | P0 | Mostrar permissão e precisão reais do aviso | Médio | — |
| BL-04 | P0 | Validar entrega em aparelhos e corrigir divergências | Médio | BL-03 |
| BL-05 | P1 | Criar item sem data e sem aviso automático | Médio | — |
| BL-06 | P1 | Separar data da tarefa e momento/tipo do aviso | Grande | BL-05 |
| BL-07 | P1 | Abrir item pelo alerta e oferecer Concluir/Adiar | Grande | BL-06 |
| BL-08 | P1 | Reduzir formulário para captura rápida | Médio | BL-06 |
| BL-09 | P1 | Reorganizar lista por urgência e corrigir progresso | Médio | BL-05 |
| BL-10 | P1 | Escolher o aviso após conclusão | Pequeno/Médio | BL-06 |
| BL-11 | P1 | Exportar e importar dados locais | Médio | — |
| BL-12 | P2 | Adicionar recorrência simples | Grande | BL-06, BL-07 |
| BL-13 | P2 | Buscar e filtrar lembretes | Médio | BL-09 |
| BL-14 | P2 | Proteger texto sensível no bloqueio | Médio | BL-06 |
| BL-15 | P2 | Avaliar lembretes por contexto, como local | Grande | Validação com usuários |

Estimativas são relativas, não prazos. Mudanças na serialização devem migrar os lembretes existentes da chave fio.reminders.v1 com testes. Mudanças nativas devem cobrir permissão, edição, conclusão, exclusão e reinício quando houver aparelho. Preserve a separação entre domínio, dados, serviços e apresentação do [desenho do sistema](system-design.md).

## P0 — confiança no comportamento atual

### BL-01 — Editar item atrasado sem reagendar

**Estado:** concluída em 25/09/2026.

**Problema:** o formulário rejeita qualquer horário passado mesmo se a pessoa só alterar título, observação ou aparência.

**Critérios de aceite:**

- Editar um item mantendo o horário atrasado funciona; criar item novo com horário passado continua bloqueado.
- Se a data/hora for alterada, a nova escolha segue a regra de agendamento definida para o tipo.
- Testes cobrem edição simples e alteração de data de item vencido.

### BL-02 — Abrir os dados mesmo com falha nas notificações

**Estado:** concluída em 25/09/2026; entrega nativa real ainda integra a matriz BL-04.

**Problema:** erro de fuso ou inicialização nativa impede a abertura da lista.

**Critérios de aceite:**

- Lembretes salvos continuam visíveis e editáveis quando o serviço de alertas está indisponível.
- A interface mostra erro específico e opção de nova tentativa, sem afirmar que o aviso foi agendado.
- Testes cobrem falha de inicialização e recuperação; falhas relevantes de restauração são comunicadas.

### BL-03 — Transparência de permissão e precisão

**Estado:** concluída em 25/09/2026 no fluxo Dart; confirmação em Android/iOS integra BL-04.

**Problema:** a pessoa vê “salvo” sem saber se o aviso está desativado ou se, no Android, o horário é aproximado.

**Critérios de aceite:**

- Serviço e interface distinguem aviso agendado, agendamento aproximado, permissão negada e erro de agendamento.
- Lista e formulário mostram texto curto e acionável para cada estado; abrir novamente atualiza o diagnóstico.
- Revogação de permissão e fallback de alarme exato têm testes e são verificados em Android quando disponível.

### BL-04 — Matriz de entrega nativa

**Estado:** parcialmente validada em 25/09/2026 no emulador Android 17. A [matriz e os passos de reprodução](native-validation.md) registram resultados; entrega aproximada real, Android 13/14 e iOS seguem sem validação.

**Problema:** testes Dart não comprovam a entrega pelo sistema operacional.

**Critérios de aceite:**

- Registrar resultados em Android 13/14+ e iOS disponível para permissão concedida/negada, horário preciso/aproximado, app fechado, reinício, edição, conclusão, exclusão e dispensa de aviso permanente.
- Corrigir divergências do README ou ajustar a promessa visível quando houver limite do sistema.
- Documentar aparelho, versão do sistema e reprodução; marcar cenários sem dispositivo como não validados.

## P1 — ciclo principal de uso

### BL-05 — Caixa de entrada sem data

**Estado:** concluída em 25/09/2026 no fluxo Dart; comportamento de notificações nativas integra BL-04.

**Problema:** Sem horário publica aviso permanente ao salvar.

**Critérios de aceite:**

- É possível salvar tarefa sem data e sem notificação e depois atribuir data ou ativar aviso.
- Fixar aviso imediatamente continua como opção explícita.
- Lembretes antigos sem horário preservam o comportamento salvo ou passam por migração documentada sem disparos inesperados.

### BL-06 — Separar tarefa, data e alerta

**Estado:** implementada em 25/09/2026; validação nativa registrada na matriz BL-04.

**Problema:** o tipo técnico de notificação determina a experiência; data futura de item permanente não determina quando ele aparece.

**Critérios de aceite:**

- O formulário responde a “Quando fazer?” e “Quando avisar?”, incluindo Sem aviso, Avisar no horário e Fixar agora.
- O resumo antes de salvar descreve o efeito real em Android, iOS e Web; não promete permanência contínua que o sistema não garante.
- Modelo, controlador, serialização e testes migram os três tipos atuais sem perda dos registros existentes.

### BL-07 — Ações úteis na notificação

**Problema:** tocar no alerta não leva ao item e não há como adiar ou concluir sem abrir a lista.

**Critérios de aceite:**

- Tocar no alerta abre o lembrete correspondente inclusive com app fechado.
- Concluir atualiza armazenamento e aviso conforme a escolha do item; Adiar oferece durações simples e agenda uma única próxima entrega.
- Callbacks nativos são idempotentes e funcionam após reinício; plataformas sem suporte oferecem alternativa clara dentro do app.

### BL-08 — Captura rápida e detalhes opcionais

**Estado:** implementada em 25/09/2026; testada em widget com 320 px, fonte 1,3× e tema escuro, e no emulador Android 17.

**Problema:** aparência e prévia ocupam a mesma etapa da criação básica.

**Critérios de aceite:**

- Título e escolha de data/aviso bastam para salvar; observação, cor, símbolo e prévia ficam em Mais opções.
- Há atalhos Hoje, Amanhã, Escolher data e Sem data, com a escolha final visível antes de salvar.
- Verificar toque, rolagem, teclado, fonte ampliada, 320 px e tema escuro; dados antigos permanecem editáveis.

### BL-09 — Lista orientada à ação e progresso coerente

**Problema:** sem data aparece antes de atrasados; métrica mistura data prevista e linguagem de conclusão diária.

**Critérios de aceite:**

- Agrupar ou filtrar Atrasados, Hoje, Próximos e Sem data, sem esconder itens antigos e com ordem estável.
- Definir e documentar progresso: se for “concluídos hoje”, persistir data de conclusão; se for “tarefas previstas para hoje”, ajustar rótulo e testes.
- Atraso e estado do aviso usam texto/ícone, não só cor; validar leitor de tela e tamanhos de toque.

### BL-10 — Comportamento após concluir

**Problema:** aviso permanente continua no painel mesmo após a conclusão até excluir o item.

**Critérios de aceite:**

- Antes de salvar, fica claro se o aviso permanecerá após concluir, e a pessoa pode escolher.
- Concluir, reabrir, editar e excluir reconciliam exatamente um aviso por item, sem reaparecimento inesperado.
- Registros antigos preservam a escolha existente na migração; o padrão para novos itens é definido após teste de uso.

### BL-11 — Exportação e importação local

**Problema:** não há forma de transportar ou recuperar os dados do próprio usuário.

**Critérios de aceite:**

- Exportar arquivo versionado legível pelo app, com instrução de armazenamento seguro.
- Importar com prévia da quantidade, tratamento de arquivo inválido e política explícita para IDs/duplicatas; não apagar a lista antes de validar o arquivo inteiro.
- Testes cobrem dados antigos, registros parcialmente inválidos e agendamento de importados conforme permissões atuais.

## P2 — expansão controlada

### BL-12 — Recorrência simples

Oferecer diário, dias da semana, semanal e mensal. **Aceite:** próxima ocorrência e regra de conclusão ficam explícitas; meses curtos, mudança de fuso, reinício e limites de avisos pendentes têm testes. Reapresentar um aviso permanente não cria nova ocorrência da tarefa.

### BL-13 — Busca e filtros

Buscar título/observação e filtrar por pendente, concluído, atrasado e sem data. **Aceite:** resultados e contagens refletem edição/conclusão imediatamente; busca funciona com teclado e leitor de tela.

### BL-14 — Privacidade no bloqueio

Permitir ocultar detalhes sensíveis do alerta conforme a plataforma. **Aceite:** a prévia explica o que será mostrado; a tarefa completa continua acessível no app. Validar demanda, pois o sistema também controla a tela bloqueada.

### BL-15 — Lembretes por contexto

Pesquisar a demanda por gatilhos como chegar a um local antes de solicitar permissões adicionais. **Aceite para iniciar a implementação:** entrevistas ou testes mostram casos frequentes que horário não resolve; há desenho de privacidade e alternativa sem localização.

## Validação de produto e design

Antes de ampliar o escopo, observar pessoas anotando algo sem data, criando aviso para amanhã, adiando um alerta durante outra atividade e recuperando um item atrasado. Registrar hesitação, interpretação de “permanente” e compreensão de permissões/horário. Usar os resultados para decidir o padrão de BL-10 e a ordem de P1/P2, sem tratar pesquisa secundária como preferência universal.

## Definição de pronto para implementações

- Interface em português do Brasil e acessibilidade conferida nos fluxos alterados.
- flutter analyze e flutter test aprovados; compatibilidade de dados antigos coberta quando houver mudança de armazenamento.
- Notificações nativas verificadas no aparelho disponível ou limitação registrada.
- README e [desenho do sistema](system-design.md) atualizados quando o comportamento ou a arquitetura mudar.
