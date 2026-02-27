# SleepTime

**Detecção passiva de sono para iPhone — sem wearable, sem configurar alarme, sem lembrar de nada.**

---

## O Problema

O iPhone sabe quando você está usando ele. Sabe quando você para de usar. Sabe quando você volta a usar de manhã. Com essas informações, ele poderia facilmente inferir que você dormiu — **mas a Apple simplesmente não faz isso.**

O recurso "Sono" nativo do iOS depende de:

- Configurar um **horário de dormir manualmente** (que ninguém mantém atualizado)
- Usar um **Apple Watch** para detecção automática
- Confiar em apps de terceiros que pedem pra você **apertar um botão antes de dormir** (sério?)

Se você não tem Apple Watch e não quer configurar alarmes, o iOS te ignora completamente. Nenhum dado de sono, nenhum histórico, nada no app Saúde.

**SleepTime resolve isso.**

## Como Funciona

A lógica é simples e elegante:

```
Última atividade: 23:47
Próxima atividade: 07:12
                    ↓
        Gap de 7h25m detectado
        Dentro da janela de sono (20h-10h)
                    ↓
        💤 Sono registrado automaticamente
```

1. **Cada vez que você abre o app**, ele registra um timestamp de atividade
2. **Background App Refresh** registra timestamps adicionais a cada ~30 minutos
3. O app analisa **gaps de inatividade** entre esses timestamps
4. Se um gap for longo o suficiente (padrão: 4h+) e começar dentro da janela noturna (20h-10h), é sono

Sem sensores especiais. Sem wearable. Só matemática com timestamps.

## Features

| Feature | Descrição |
|---|---|
| **Detecção automática** | Ao abrir o app, o sono é detectado silenciosamente |
| **Detecção manual** | Botão "Detectar Sono" com feedback claro do resultado |
| **Qualidade do sono** | Classificação automática: Bom (8h+), Regular (6-8h), Ruim (-6h) |
| **Histórico visual** | Gráfico de barras dos últimos 30 dias com cores por qualidade |
| **Detalhes por noite** | Horário de dormir, acordar, duração e qualidade |
| **Sincronização HealthKit** | Exporta registros para o app Saúde da Apple |
| **Janela configurável** | Ajuste o horário esperado de sono e duração mínima |
| **Background Refresh** | Coleta timestamps mesmo sem abrir o app |

## Requisitos

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Estrutura

```
SleepTime/
├── Models/
│   ├── SleepRecord.swift          # Registro de sono (início, fim, duração, qualidade)
│   └── ActivityTimestamp.swift     # Timestamp de atividade (foreground/background)
├── Services/
│   ├── SleepDetectionService.swift    # Algoritmo de detecção de gaps
│   ├── BackgroundTaskService.swift    # BGAppRefresh para timestamps passivos
│   └── HealthKitService.swift         # Integração com o app Saúde
├── Views/
│   ├── HomeView.swift             # Tela principal com card de sono
│   ├── HistoryView.swift          # Histórico com gráficos (Swift Charts)
│   ├── SettingsView.swift         # Configurações de janela e HealthKit
│   └── SleepDetailView.swift      # Detalhe de uma noite
└── SleepTimeApp.swift             # Entry point + TabView
```

## Por Que Isso Não Existe?

Boa pergunta. O iPhone tem todos os dados necessários — o Screen Time prova isso. A Apple escolhe empurrar a detecção de sono para o Apple Watch, provavelmente como incentivo de venda. Enquanto isso, quem usa só o iPhone fica sem nenhuma forma passiva de tracking.

O SleepTime preenche esse gap (literalmente).

---

*Feito com SwiftUI, SwiftData e uma quantidade saudável de frustração com a Apple.*
