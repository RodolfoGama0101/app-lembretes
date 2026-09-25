# System design — Lembretes

## Objetivo

Lembrar o usuário de tarefas no horário escolhido, funcionando offline e sem exigir cadastro.

## Componentes

```text
Telas Flutter
    │
    ▼
ReminderController ─────► NotificationService
    │                         │
    ▼                         ▼
ReminderRepository       APIs locais Android/iOS
    │
    ▼
SharedPreferences (JSON)
```

### Apresentação

`HomeScreen` e `ReminderFormScreen` mostram o estado e encaminham ações. Elas não conhecem detalhes de armazenamento ou plugins nativos.

### Aplicação e domínio

`ReminderController` concentra ordenação, validação de estado, conclusão e coordena persistência/notificação. `Reminder` é o modelo serializável e `NotificationKind` diferencia alertas temporários de permanentes.

A aparência do alerta pertence a cada `Reminder`: estilo, cor e símbolo são persistidos junto com os demais campos. Registros antigos recebem os padrões anteriores durante a leitura. Novos lembretes usam vermelho por padrão. A edição republica o alerta quando algum desses campos muda.

### Dados

`ReminderRepository` é um contrato. A implementação atual, `LocalReminderRepository`, salva uma lista JSON versionada em `SharedPreferences`. Uma futura implementação remota poderá manter o mesmo contrato ou ser combinada com cache local.

### Integração nativa

`LocalNotificationService` encapsula o plugin de notificações, fuso horário, permissões e canais Android. No Android, ele combina o símbolo e a cor em um ícone grande gerado para o painel e usa a cor também como destaque do sistema. A notificação permanente usa `ongoing: true` e aparece imediatamente. No Android, o mesmo identificador é reapresentado a cada 24 horas por um alarme aproximado restaurado após o reinício; a temporária é agendada e permite dispensa normal.

## Fluxo principal

1. O usuário informa título, data, hora e tipo.
2. O controlador cria um identificador local, publica ou agenda a notificação e persiste o lembrete.
3. O tipo permanente aparece imediatamente; o temporário é agendado no fuso horário do aparelho.
4. Concluir cancela o alerta temporário, mas preserva o permanente. Excluir cancela qualquer notificação do lembrete.

## Evolução para banco de dados

1. Adicionar um identificador global e campos `updatedAt`/`deletedAt`.
2. Implementar um repositório SQLite para cache mais robusto ou um `RemoteReminderRepository` para API.
3. Adicionar uma camada de sincronização com resolução simples por `updatedAt`.
4. Reagendar notificações locais após cada sincronização.

Essa evolução não exige alterar os widgets; apenas a composição do repositório no `main.dart` e, se necessário, o controlador.

## Decisões e limites

- Sem recorrência de tarefas; no Android, apenas o aviso permanente é reapresentado diariamente.
- Sem autenticação ou rede.
- Alarmes exatos são solicitados para alertas temporários no Android; quando negados, usa-se agendamento aproximado.
- O Android 14 ou posterior permite que o usuário dispense notificações `ongoing` com um gesto no painel. O app restaura as permanentes ao abrir ou retomar e as reapresenta diariamente no Android; o sistema pode atrasar a entrega. No iOS, o sistema também permite dispensá-las.
