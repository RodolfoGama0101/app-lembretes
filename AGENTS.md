# Instruções do projeto

## Contexto

- Este repositório contém um aplicativo Flutter de lembretes locais. A interface está em português do Brasil; Android e iOS usam notificações locais, enquanto a versão Web serve como prévia sem alertas.
- Consulte `README.md` para execução e comportamento visível ao usuário, e `docs/system-design.md` para as decisões de arquitetura.
- Em `lib/features/reminders/`, `domain/` define o modelo, `data/` cuida da persistência, `services/` encapsula notificações e `presentation/` contém telas e controlador. `lib/main.dart` compõe essas partes.

## Ao alterar o aplicativo

- Preserve a separação entre interface, regras, armazenamento e notificações. Mantenha textos da interface em português do Brasil.
- Respeite a relação entre tipo e horário: lembretes `unscheduled` têm `scheduledAt == null`; lembretes `temporary` e `persistent` têm horário. Ao mudar essa regra, ajuste modelo, formulário, controlador e testes em conjunto.
- Notificações temporárias são agendadas; permanentes e sem horário aparecem ao salvar e permanecem após a conclusão até a exclusão do lembrete. A implementação Web salva lembretes, mas não envia notificações.
- Ao mudar a serialização ou o armazenamento, considere os lembretes já salvos em `SharedPreferences` e cubra a compatibilidade com testes.

## Verificações

- Para alterações em Dart, execute `flutter analyze` e `flutter test`. Se uma verificação não puder ser executada, informe o motivo.
- Para alterações apenas na documentação, confira referências e comandos com os arquivos do projeto. Antes do commit, execute `git diff --check`.
- Ao alterar notificações nativas, confira também permissões, agendamento e restauração na plataforma afetada quando houver dispositivo disponível; informe o que não foi possível validar.

## Git

- Ao concluir cada tarefa que alterar arquivos, crie um commit Git apenas com as alterações feitas nessa tarefa.
- Use Conventional Commits: `tipo(escopo opcional): descrição` (por exemplo, `feat(reminders): add unscheduled reminders` ou `docs(readme): clarify setup`).
- Preserve alterações preexistentes ou de outras pessoas; não as inclua no commit. Revise os arquivos preparados antes de commitar.
- Na resposta final, informe as verificações executadas e o hash do commit. Se a tarefa não alterar arquivos, informe que não há alterações para commitar.
