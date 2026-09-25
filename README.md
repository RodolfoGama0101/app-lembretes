# Lembretes

Aplicativo Flutter para organizar lembretes no próprio aparelho. Funciona sem cadastro ou servidor e mantém os dados localmente. A interface está em português e acompanha o tema claro ou escuro do sistema.

## Funcionalidades

- Criar tarefas com título, observação opcional e data/hora ou sem data. O seletor de hora usa formato de 24 horas (por exemplo, 18:45).
- Escolher separadamente o aviso: **Sem aviso**, **Avisar no horário** (somente com data) ou **Fixar agora**. O formulário resume o efeito antes de salvar. Atalhos **Hoje**, **Amanhã**, **Escolher data** e **Sem data** agilizam a definição do prazo; observação e aparência ficam em **Mais opções**.
- Editar, marcar como concluído, reabrir e excluir lembretes.
- Consultar itens pendentes e concluídos, com destaque para o próximo lembrete e tarefas atrasadas.
- Escolher, para avisos, texto compacto ou expandível, cor e símbolo. No Android, a cor aparece no ícone grande da notificação e em detalhes definidos pelo sistema.

| Aviso | Quando aparece no celular | Ao concluir |
| --- | --- | --- |
| **Sem aviso** | Não envia notificação, com ou sem data da tarefa. | A tarefa continua na lista de concluídos. |
| **Avisar no horário** | Na data e hora da tarefa, se as permissões permitirem; no Android pode ser aproximado. | O alerta agendado é cancelado. |
| **Fixar agora** | Ao salvar, mesmo se a tarefa tiver data futura; o horário organiza a tarefa. | O aviso continua configurado até excluir o lembrete; o sistema pode dispensá-lo do painel. |

Registros anteriores são lidos na mesma chave local `fio.reminders.v1`: temporário vira **Avisar no horário**, permanente e sem horário com aviso viram **Fixar agora**, e caixa de entrada vira **Sem aviso**. A data e as preferências de aparência são preservadas. A versão Web salva as escolhas, mas não envia notificações.

No Android, o símbolo escolhido aparece em um ícone grande colorido no painel; a cor também é enviada como destaque para o sistema. O restante da aparência depende da versão e das configurações do aparelho. Vermelho é o padrão para novos lembretes; os já salvos mantêm sua cor e seu símbolo. No iOS, o sistema controla o visual do banner, e a cor e o símbolo escolhidos aparecem na lista do aplicativo. Na Web, o formulário oferece um exemplo visual para opções com aviso, mas não envia alertas. Registros antigos sem aparência salva mantêm os padrões anteriores: expandido, azul e sino.

No Android 14 ou posterior, o sistema permite dispensar uma notificação permanente com um gesto no painel. O aplicativo a restaura ao abrir ou retomar e agenda uma nova apresentação aproximadamente a cada 24 horas, inclusive depois de reiniciar o aparelho, enquanto o lembrete existir e as notificações estiverem permitidas. O horário pode variar por decisão do Android. No iOS, o sistema também pode permitir dispensá-la; ela volta quando o app abre ou retoma. Nenhum dos dois sistemas garante que um aviso comum permaneça continuamente no painel até a exclusão dentro do aplicativo.

## Executar o projeto

Instale o Flutter com um Dart compatível com `>=3.5.0 <4.0.0` e configure um dispositivo ou emulador. Para Android, configure o Android SDK; para iOS, use macOS com Xcode.

```bash
flutter pub get
flutter devices
flutter run
```

Se houver mais de um dispositivo disponível, escolha um com `flutter run -d <id-do-dispositivo>`.

### Permissões de notificação

No celular, permita notificações quando o sistema solicitar. Se a permissão for negada, o lembrete ainda será salvo, mas não enviará o aviso. Para avisos no horário no Android, o aplicativo também solicita acesso a alarmes exatos; sem esse acesso, usa agendamento aproximado. Os avisos fixados aparecem ao salvar e não dependem de alarmes exatos.

Se o serviço de notificações não iniciar ou não puder restaurar os avisos, os lembretes continuam acessíveis e podem ser editados. A tela inicial informa o problema e oferece **Tentar novamente**. Alterações feitas enquanto os avisos estão indisponíveis são reconciliadas com o painel quando o serviço volta.

Para itens com aviso, a lista mostra se ele foi configurado, se seu horário é aproximado ou se a permissão está desativada. Itens sem aviso não solicitam permissão de notificações, tenham data ou não. O diagnóstico é atualizado ao abrir ou retomar o aplicativo. No Android, um agendamento aproximado pode chegar depois da hora escolhida; o estado mostrado descreve a programação feita pelo app, não garante a entrega pelo sistema.

### Assinatura Android para publicação

O APK de publicação usa a chave local em `android/lembretes-release.jks` e as senhas em `android/key.properties`. Ambos os arquivos são ignorados pelo Git. **Guarde uma cópia segura dos dois arquivos**: sem a mesma chave, não é possível distribuir uma atualização instalável sobre esta versão.

Para gerar novamente o APK de publicação:

```bash
flutter build apk --release
```

Em outra máquina, restaure os arquivos em `android/` antes de compilar. O build de release falha se `key.properties` estiver ausente.

### Prévia no navegador

```bash
flutter run -d chrome
```

A versão Web permite criar e organizar lembretes, mas **não envia notificações**. Os dados ficam no armazenamento local desse navegador e são perdidos se os dados do site forem apagados. Para testar alertas, use Android ou iOS.

## Identificador Android

O pacote Android é `com.rodolfogama.lembretes` a partir da versão 1.0.1. Como ele difere de `br.com.fio.fio_lembretes`, o Android instala esta versão como outro aplicativo: lembretes salvos na instalação antiga não são transferidos automaticamente. O pacote Dart agora se chama `lembretes`. A chave antiga `fio.reminders.v1` permanece no armazenamento para preservar lembretes já salvos na Web.

## Dados locais

Os lembretes são salvos com `SharedPreferences` no dispositivo ou navegador em uso. Não há conta nem sincronização entre dispositivos. Excluir um lembrete também cancela sua notificação. No Android, alertas temporários e a reapresentação diária dos avisos permanentes são restaurados após a reinicialização do aparelho; os avisos permanentes também são restaurados quando o aplicativo é aberto ou retomado.

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

Para gerar novamente os ícones grandes das notificações Android após mudar a paleta:

```bash
python tool/generate_notification_badges.py
```

## Planejamento de produto

A [análise de produto e experiência](docs/product-analysis.md) reúne achados do código, pesquisa de necessidades e propostas de design. O [backlog](docs/backlog.md) organiza as melhorias por prioridade, dependência e critérios de aceite. A [matriz de validação nativa](docs/native-validation.md) registra os cenários testados no emulador e os ainda pendentes.
