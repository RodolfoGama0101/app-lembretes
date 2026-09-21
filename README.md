# Fio

Fio é um aplicativo Flutter de lembretes locais. Ele foi desenhado para registrar uma tarefa em poucos toques e avisar no horário escolhido, sem conta, servidor ou coleta de dados.

## O que já funciona

- criação, edição, conclusão e exclusão de lembretes;
- notificações locais agendadas;
- notificação temporária, dispensável normalmente;
- notificação fixa no Android, mantida no painel até o lembrete ser concluído no app;
- armazenamento no próprio aparelho com `SharedPreferences`;
- restauração de notificações agendadas após reiniciar o Android;
- interface em português e testes unitários/de widget.

> No iOS, o sistema não permite notificações realmente não dispensáveis. A opção **Fixa** é exibida como uma notificação local normal nessa plataforma.

## Executar

Pré-requisitos: Flutter estável, Android Studio/Xcode e um aparelho ou emulador.

```bash
flutter pub get
flutter run
```

Na primeira criação de lembrete, permita notificações e, no Android, alarmes exatos. Se o segundo acesso não for concedido, o Fio usa um agendamento aproximado automaticamente.

## Arquitetura

A implementação separa domínio, persistência, notificações e apresentação. Essa fronteira permite trocar o repositório local por banco ou API sem reescrever as telas e regras de negócio.

Consulte [docs/system-design.md](docs/system-design.md) para as decisões e o caminho de evolução.

## Design visual

O frontend usa uma direção Swiss: superfícies brancas/neutras, tipografia sans, grade marcada por linhas de 1 px e azul Yves Klein como único acento. Datas e horários são elementos editoriais grandes; a régua do dia destaca o próximo compromisso sem adicionar ruído visual.
