# Análise de produto e experiência — Lembretes

Atualizada em 25/09/2026. Esta revisão fundamenta o [backlog](backlog.md). Combina leitura do código, documentação e capturas existentes com pesquisa secundária. As necessidades são hipóteses de produto: ainda não houve entrevistas nem testes com usuários deste app. Os achados registram o estado anterior à implementação; acompanhe as conclusões no [backlog](backlog.md).

## Propósito e base atual

O app permite registrar tarefas e receber avisos locais sem conta, servidor ou conexão. Android e iOS usam notificações locais; a Web salva no navegador, sem alertas. Há título, observação, data/hora, três tipos de lembrete, aparência do alerta, edição, conclusão, reabertura e exclusão. Os dados são gravados em um JSON no SharedPreferences. Consulte o [README](../README.md) e o [desenho do sistema](system-design.md).

A separação entre modelo, repositório, notificações e telas facilita evolução. O controlador compensa algumas falhas entre gravação e agendamento; a leitura ignora registros inválidos sem esconder os válidos. A interface usa português, temas claro/escuro e exclusão por controle visível, além de gesto. Em 25/09/2026, flutter analyze terminou sem problemas e flutter test passou com 25 testes. flutter devices mostrou Windows, Chrome e Edge; não havia Android ou iPhone para validar a entrega nativa.

## Necessidades encontradas na pesquisa

| Necessidade | Evidência | Implicação |
| --- | --- | --- |
| Registrar compromissos com hora definida e intenções ainda sem data. | Um estudo de campo descreve prazos, objetivos persistentes e intenções vagas, que podem ganhar horário depois. [Microsoft Research, 2017](https://www.microsoft.com/en-us/research/wp-content/uploads/2017/07/memory_imwut2017.pdf). | Oferecer uma caixa de entrada sem data e sem aviso obrigatório. |
| Retomar ou reagendar algo que não pôde ser feito quando o alerta apareceu. | O estudo registra avisos ignorados durante imprevistos. Participantes de uma pesquisa sobre medicação valorizaram o adiamento configurável. [Microsoft Research](https://www.microsoft.com/en-us/research/wp-content/uploads/2017/07/memory_imwut2017.pdf); [BMJ Open, 2022](https://bmjopen.bmj.com/content/12/2/e053183). | Oferecer Adiar e Concluir no aviso e abrir o item correto ao tocá-lo. O estudo de medicação não representa sozinho todos os usos. |
| Receber avisos úteis sem saturação. | A Apple recomenda alertas concisos, relevantes e com ações simples; repetições em excesso podem levar à desativação dos avisos do app. [Apple](https://developer.apple.com/design/human-interface-guidelines/notifications/). | Deixar explícito quando o aviso é fixado ou repetido e permitir controlar isso. |
| Confiar no horário e nos dados. | O Android diferencia alarmes precisos e aproximados. O plugin SharedPreferences não recomenda seu uso para dados críticos, pois a gravação em disco pode ser assíncrona. [Android](https://developer.android.com/develop/background-work/services/alarms); [plugin](https://github.com/flutter/packages/blob/main/packages/shared_preferences/shared_preferences/README.md). | Informar a precisão, testar a entrega real e oferecer exportação/importação. |

## Lacunas verificadas

1. **Sem horário cria um aviso permanente imediato.** Não há anotação silenciosa sem data. Permanente também aparece ao salvar mesmo com data futura. O formulário explica a regra, mas ela mistura guardar uma tarefa, data de execução e momento do alerta. Ver [formulário](../lib/features/reminders/presentation/reminder_form_screen.dart), [modelo](../lib/features/reminders/domain/reminder.dart) e [serviço](../lib/features/reminders/services/local_notification_service.dart).
2. **O alerta não fecha o ciclo da tarefa.** O serviço envia o ID como payload, mas não registra resposta ao toque nem ações para concluir ou adiar. Ver [serviço](../lib/features/reminders/services/local_notification_service.dart).
3. **Editar um item atrasado exige alterar o horário.** A validação de horário futuro roda em toda gravação, mesmo se só o título ou a observação mudar. Ver [formulário](../lib/features/reminders/presentation/reminder_form_screen.dart).
4. **Falha do fuso pode bloquear os dados.** A inicialização nativa ocorre antes da leitura da lista. Uma exceção mostra apenas a tela de erro. Ver [main](../lib/main.dart) e [serviço](../lib/features/reminders/services/local_notification_service.dart).
5. **O estado do aviso não é transparente.** No Android, sem alarme exato o agendamento torna-se aproximado, mas o formulário não distingue isso. Falhas na restauração de avisos permanentes são ignoradas pelo controlador. Ver [serviço](../lib/features/reminders/services/local_notification_service.dart) e [controlador](../lib/features/reminders/presentation/reminder_controller.dart).
6. **Progresso usa a data prevista, não a conclusão.** Não existe data de conclusão no modelo: concluir hoje uma tarefa prevista para ontem não aumenta “concluídos de hoje”. A definição da métrica precisa ser escolhida antes da correção. Ver [controlador](../lib/features/reminders/presentation/reminder_controller.dart).
7. **Não há portabilidade.** Toda a lista fica em uma chave local, sem exportação/importação. Ver [repositório](../lib/features/reminders/data/local_reminder_repository.dart).
8. **Falta prova nativa em aparelho.** Os testes do controlador usam serviço falso; não verificam permissão, reinício, economia de bateria, dispensa ou toque no alerta. Ver [testes](../test/reminder_controller_test.dart).

Manter o aviso permanente após concluir é uma decisão atual, não uma regressão. Convém validar se a pessoa espera que “concluído” encerre o aviso e tornar a escolha explícita, preservando registros antigos durante a migração.

## Direção de design

O tema atual combina fundo neutro, azul para ações, cartões arredondados e claro/escuro em [app_theme.dart](../lib/core/theme/app_theme.dart). As [capturas de QA](../qa-report/screenshots) mostram a ação principal fácil de localizar e estados vazios legíveis. A prioridade é melhorar hierarquia e clareza, sem trocar toda a identidade visual.

### Criação

- **Primeira etapa curta:** título, data/aviso opcional e Salvar. Atalhos Hoje, Amanhã, Escolher data e Sem data reduzem toques sem presumir uma data.
- **Tarefa e alerta separados:** oferecer Sem aviso, Avisar no horário e Fixar agora, cada um com descrição objetiva. A data de fazer e a hora do alerta podem ser distintas.
- **Detalhes recolhidos:** observação, cor, símbolo e prévia ficam em Mais opções. Mostrar prévia quando houver aviso, com as limitações da plataforma. Preservar cores já salvas.

### Lista e estados

- Destacar **Atrasados**, **Hoje**, **Próximos** e **Sem data**, com contagens e ordem estável. Hoje, sem horário vem antes de itens atrasados; muitas anotações podem esconder urgências.
- Mostrar Aviso desativado, Horário aproximado e Aviso agendado por texto/ícone, sem depender apenas de cor. A cor personalizada não deve ser confundida com o vermelho semântico de atraso ou erro.
- Manter concluir, editar e excluir descobríveis. Oferecer Adiar para item atrasado e uma forma breve de desfazer conclusão.
- Definir o cabeçalho: “tarefas previstas para hoje” usa data prevista; “concluídas hoje” exige registrar a data da conclusão.

### Acessibilidade

Conferir claro/escuro, 320 px, fonte ampliada, TalkBack/VoiceOver, foco de teclado na Web, contraste, rótulos de estado e alvos de toque de pelo menos 48 dp quando aplicável. [Diretriz Android](https://developer.android.com/guide/topics/ui/accessibility/views/apps-views). As capturas antigas são referência, não substituem nova avaliação.

## Sequência recomendada

1. Corrigir bloqueios de edição e acesso aos dados; tornar visível o estado dos avisos.
2. Separar anotação e notificação; reduzir o tempo de criação.
3. Fechar o ciclo com ações no aviso e adiamento.
4. Acrescentar recorrência e portabilidade sem perder registros existentes.
5. Validar com usuários: criar algo sem data, reagir a aviso inoportuno, recuperar item atrasado e trocar de aparelho. Observar hesitação e compreensão do horário/estado do aviso.

As tarefas e critérios de aceite estão no [backlog](backlog.md).
