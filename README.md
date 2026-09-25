# Lembretes

Aplicativo Flutter para organizar lembretes no próprio aparelho. Funciona sem cadastro ou servidor e mantém os dados localmente. A interface está em português e acompanha o tema claro ou escuro do sistema.

## Funcionalidades

- Criar lembretes com título, observação opcional e data e hora, ou deixá-los **sem horário**.
- Editar, marcar como concluído, reabrir e excluir lembretes.
- Consultar itens pendentes e concluídos, com destaque para o próximo lembrete e tarefas atrasadas.
- Receber notificações locais no Android e no iOS, conforme o tipo escolhido.

| Tipo | Quando aparece no celular | Ao concluir |
| --- | --- | --- |
| **Temporária** | No horário escolhido; pode ser dispensada. | O alerta agendado é cancelado. |
| **Permanente** | Assim que o lembrete é salvo; a data e a hora organizam a tarefa. | Continua visível até o lembrete ser excluído. |
| **Sem horário** | Assim que o lembrete é salvo, como aviso permanente. | Continua visível até o lembrete ser excluído. |

No Android 14 ou posterior, o sistema pode permitir dispensar uma notificação permanente pelo painel. O aplicativo a restaura ao abrir ou retomar. No iOS, o sistema também pode permitir dispensá-la.

## Executar o projeto

Instale o Flutter com um Dart compatível com `>=3.5.0 <4.0.0` e configure um dispositivo ou emulador. Para Android, configure o Android SDK; para iOS, use macOS com Xcode.

```bash
flutter pub get
flutter devices
flutter run
```

Se houver mais de um dispositivo disponível, escolha um com `flutter run -d <id-do-dispositivo>`.

### Permissões de notificação

No celular, permita notificações quando o sistema solicitar. Se a permissão for negada, o lembrete ainda será salvo, mas não enviará o aviso. Para notificações temporárias no Android, o aplicativo também solicita acesso a alarmes exatos; sem esse acesso, usa agendamento aproximado. As notificações permanentes aparecem ao salvar e não dependem de alarmes exatos.

### Prévia no navegador

```bash
flutter run -d chrome
```

A versão Web permite criar e organizar lembretes, mas **não envia notificações**. Os dados ficam no armazenamento local desse navegador e são perdidos se os dados do site forem apagados. Para testar alertas, use Android ou iOS.

## Dados locais

Os lembretes são salvos com `SharedPreferences` no dispositivo ou navegador em uso. Não há conta nem sincronização entre dispositivos. Excluir um lembrete também cancela sua notificação. No Android, alertas temporários agendados são restaurados após a reinicialização do aparelho; os avisos permanentes são restaurados quando o aplicativo é aberto ou retomado.

## Desenvolvimento

Execute as verificações do projeto com:

```bash
flutter analyze
flutter test
```

O código separa modelo e regras dos lembretes, persistência, notificações e interface:

| Caminho | Responsabilidade |
| --- | --- |
| `lib/features/reminders/domain/` | Modelo e tipos de lembrete. |
| `lib/features/reminders/data/` | Contrato do repositório e armazenamento local. |
| `lib/features/reminders/services/` | Notificações nativas e implementação Web sem alertas. |
| `lib/features/reminders/presentation/` | Telas, widgets e controlador. |
| `test/` | Testes do controlador, armazenamento e interface. |

As decisões de arquitetura e os caminhos de evolução estão em [docs/system-design.md](docs/system-design.md).

## Ícones do aplicativo

Os arquivos-fonte da arte ficam em `assets/branding/`. Para gerar os ícones de Android, iOS e Web e a prévia dos recortes:

```bash
python -m pip install -r tool/requirements.txt
python tool/generate_app_icons.py
```

O identificador interno `fio_lembretes` foi mantido para preservar instalações e dados locais existentes.
