# Validação nativa de notificações

Registro de 25/09/2026 para a matriz da [BL-04](backlog.md). Os resultados abaixo vêm de uma execução do aplicativo no Android, da hierarquia de acessibilidade e dos serviços `dumpsys notification` e `dumpsys alarm`. Testes Dart continuam em `test/`.

## Ambiente

| Item | Valor |
| --- | --- |
| Dispositivo | Emulador `sdk gphone16k x86 64` (`emulator-5554`) |
| Sistema | Android 17, API 37, arquitetura x86_64 |
| Aplicativo | Build debug, pacote `com.rodolfogama.lembretes`, target SDK 36 |
| Flutter | 3.44.0 |
| Fuso do emulador | GMT; horários abaixo são os exibidos no aparelho |
| Estado inicial | Lista vazia; notificações não concedidas; acesso a alarmes exatos no modo padrão |

## Resultados

| Cenário | Procedimento e evidência | Resultado |
| --- | --- | --- |
| Permissão negada | Criado lembrete temporário para 19h e escolhida a opção de negar no diálogo Android. Lista mostrou **Aviso desativado**; o serviço de notificações não tinha registro do pacote. | Passou |
| Permissão concedida sem alarme exato | Concedida `POST_NOTIFICATIONS` e retomado o app. Lista mostrou **Horário aproximado**. O AlarmManager registrou 19h com janela aproximada de 42 min. | Passou para agendamento; hora real de entrega aproximada não observada |
| Alarme exato | Concedido `SCHEDULE_EXACT_ALARM` e retomado o app. Lista mostrou **Aviso agendado**; AlarmManager registrou `window=0` e `exactAllowReason=permission`. | Passou |
| Edição do temporário | Alterado o título sem mudar 19h. A lista mostrou o texto novo e o AlarmManager manteve um alarme ativo para o item. | Passou |
| Conclusão, reabertura e exclusão do temporário | Concluir removeu o alarme ativo; reabrir criou um alarme; excluir removeu o item e o alarme. | Passou |
| Item sem data e sem aviso | Criado com **Sem aviso**. Apareceu como **Sem data • sem aviso**, sem registro ativo no AlarmManager nem no serviço de notificações. | Passou |
| Conversão em aviso fixo | O item anterior foi editado para **Fixar aviso agora**. O painel mostrou uma notificação `ONGOING_EVENT` e o AlarmManager registrou a próxima apresentação diária aproximada. | Passou |
| Dispensa do aviso fixo | O gesto de dispensar removeu a notificação no Android 17. Voltar ao app restaurou a mesma notificação. | Passou |
| Entrega em segundo plano | Aviso temporário agendado para 18h20. Com o app em segundo plano, o serviço Android registrou uma notificação com o título e o horário escolhidos. | Passou |
| Entrega com processo encerrado | Aviso preciso agendado para 18h30. Após enviar o app ao fundo, `am kill` encerrou o processo (`pidof` sem resultado), mantendo o alarme. Às 18h30, o Android publicou o aviso; o receiver iniciou um processo do pacote para entregá-lo. | Passou; `force-stop` não foi usado |
| Reinício do aparelho | Emulador reiniciado com aviso fixo ativo. Após o boot, o alarme diário estava restaurado; a notificação não estava visível antes de abrir o app e reapareceu quando ele abriu. | Passou conforme o comportamento documentado |
| Revogação após salvar | Revogada `POST_NOTIFICATIONS` com aviso fixo existente. O painel deixou de exibi-lo e a lista mostrou **Aviso desativado**. Conceder novamente e retomar restaurou o estado **Aviso configurado**. | Passou |
| Conclusão e exclusão do aviso fixo | Concluir manteve a notificação no painel. Excluir o item concluído removeu a notificação e o alarme diário. | Passou |
| Entrada de hora por texto | Antes da correção, digitar `18:16` mostrava **Insira um horário válido**, embora o mostrador aceitasse 18h. Após usar formato de 24h explicitamente, `18:45` foi aceito no teste de interface e no emulador. | Corrigido nesta tarefa |

## Limites e reprodução

A entrega **aproximada** foi verificada como agendamento do sistema, mas não foi medida até sua chegada; o Android pode atrasá-la. Não havia iPhone, simulador iOS nem emuladores Android 13/14 nesta sessão. Esses cenários permanecem sem validação. A amostra é um emulador Android 17, não prova o mesmo comportamento em aparelhos de fabricantes diferentes.

Para repetir: instale com `flutter run -d emulator-5554`, crie um aviso temporário futuro e um item sem data, negue a primeira solicitação no diálogo Android e alterne as permissões para as etapas seguintes. Nesta sessão, a concessão/revogação de notificações usou `adb shell pm grant`/`pm revoke` para `android.permission.POST_NOTIFICATIONS`; o acesso a alarmes exatos usou `adb shell cmd appops set com.rodolfogama.lembretes SCHEDULE_EXACT_ALARM allow` (e `default` ao terminar). Observe os estados na lista e confira alarmes/notificações com `adb shell dumpsys alarm` e `adb shell dumpsys notification --noredact`. Para o teste de processo encerrado, envie o app ao fundo e use `adb shell am kill com.rodolfogama.lembretes`; `am force-stop` representa outro comportamento do sistema. Para o teste de reinício, use `adb reboot` e espere `sys.boot_completed=1` antes de conferir o AlarmManager.

Os lembretes criados para esta matriz foram excluídos. As permissões do pacote foram devolvidas ao estado inicial do emulador.

## BL-06 — data da tarefa e modo de aviso independentes

Em 25/09/2026, a versão de depuração atualizada foi instalada no mesmo emulador Android 17 (API 37). Uma tarefa futura `QA_BL06` foi salva com **Sem aviso**: apareceu na lista com horário e sem notificação ativa do sistema (`dumpsys notification`). Ao editá-la para **Fixar agora**, o Android solicitou `POST_NOTIFICATIONS`; depois de concedida, a lista mostrou **Aviso configurado** e o sistema publicou a notificação. Excluir o item removeu a notificação. O item de teste foi apagado e a permissão foi devolvida ao estado negado. O agendamento de **Avisar no horário** já foi exercitado na matriz anterior; a combinação nova com data sem aviso foi verificada aqui.

## BL-08 — captura rápida

Em 25/09/2026, o formulário atualizado foi instalado no emulador Android 17 (API 37). A árvore de acessibilidade mostrou os quatro atalhos de data. A sequência **Sem data → Amanhã** exibiu 26/09/2026 e permitiu salvar `QA_BL08` sem aviso; a lista mostrou a tarefa para amanhã e `dumpsys notification` não encontrou notificação correspondente. O item de teste foi excluído. O teste de widget cobre largura de 320 px, fonte ampliada a 1,3×, tema escuro, abertura de **Mais opções** e persistência da observação.
