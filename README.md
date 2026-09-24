# Fio

Fio é um aplicativo Flutter de lembretes locais. Ele registra tarefas em poucos toques, sem conta, servidor ou coleta de dados.

## O que já funciona

- criação, edição, conclusão e exclusão de lembretes;
- notificação temporária agendada para o horário escolhido, dispensável normalmente;
- notificação permanente exibida ao salvar, mantida após concluir e removida ao excluir o lembrete;
- armazenamento no próprio aparelho com `SharedPreferences`;
- restauração dos alertas temporários agendados após reiniciar o Android e das notificações permanentes quando o app é aberto;
- interface em português e testes unitários/de widget.

> O Android 14 ou posterior pode permitir dispensar uma notificação permanente pelo painel, mesmo com `ongoing: true`. O Fio a restaura ao abrir ou retomar o app. No iOS, a notificação também pode ser dispensada pelo sistema.

## Executar

Pré-requisitos: Flutter estável, Android Studio/Xcode e um aparelho ou emulador.

```bash
flutter pub get
flutter run
```

Na primeira criação de lembrete, permita notificações. Para alertas temporários no Android, permita também alarmes exatos. Se esse acesso não for concedido, o Fio usa um agendamento aproximado. Notificações permanentes aparecem imediatamente e não precisam dessa permissão de alarme.


### Prévia local no navegador

`flutter run -d chrome` abre o Fio no Chrome após `flutter pub get`. Os lembretes ficam no armazenamento local desse navegador; limpar os dados do site os remove. A prévia Web não envia notificações, inclusive quando a aba está fechada. Para testar alertas, use Android ou iOS.

## Arquitetura

A implementação separa domínio, persistência, notificações e apresentação. Essa fronteira permite trocar o repositório local por banco ou API sem reescrever as telas e regras de negócio.

Consulte [docs/system-design.md](docs/system-design.md) para as decisões e o caminho de evolução.

## Design visual

O frontend segue a linguagem da One UI 9: título amplo, ações ao alcance do polegar, superfícies suaves, cantos arredondados, azul de ação e tema claro/escuro conforme o aparelho. Os alertas Android exibem horário e observações em formato expandido, usando o painel nativo do sistema.
