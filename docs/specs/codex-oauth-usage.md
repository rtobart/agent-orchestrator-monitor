# SDD: integración de cuota OAuth de Codex

## Objetivo

Mostrar en OC Monitor las ventanas reales de cuota de la cuenta ChatGPT/Codex autenticada por OAuth, independientemente de si el consumo se originó en Codex o en OpenCode con el provider `openai` OAuth.

La integración debe ser gratuita: no usa `OPENAI_API_KEY`, no invoca modelos y no consulta endpoints de facturación.

## Fuente de verdad

El binario local de Codex ofrece el método `account/rateLimits/read` de `codex app-server`. Su respuesta incluye para cada ventana:

- `usedPercent`: porcentaje consumido;
- `windowDurationMins`: duración de la ventana;
- `resetsAt`: instante Unix de reinicio.

Esta cuota pertenece al backend de la cuenta OAuth y ya agrega el consumo que OpenAI atribuye a esa cuenta. Por eso no se suma el `cost` estimado de SQLite para el provider `openai` OAuth: hacerlo duplicaría o distorsionaría el uso.

## Diseño

1. `CodexUsageService` ejecuta el `codex app-server` local por stdio.
2. Inicializa el protocolo y solicita `account/rateLimits/read`.
3. `CodexRateLimitParser` transforma `primary` y `secondary` en ventanas de dominio.
4. `MonitorViewModel` actualiza esa cuota fuera del hilo principal y conserva el último resultado válido.
5. `ContentView` presenta una sección “OpenAI Codex (OAuth)” con porcentaje y fecha de reinicio.
6. Los providers OpenCode existentes continúan usando SQLite, excepto `openai` autenticado por OAuth, que se representa mediante la cuota conjunta.

## Estados y errores

- `loading`: consulta inicial en curso.
- `available`: una o más ventanas válidas.
- `unavailable(message)`: Codex no está instalado, no hay sesión OAuth o falla el protocolo.
- Un refresco fallido no inventa valores ni convierte la cuota en coste monetario.

## Seguridad y compatibilidad

- No se leen ni muestran tokens de `auth.json` o `~/.codex/auth.json`.
- No se persisten credenciales.
- Se busca Codex en ubicaciones conocidas de la app y en `PATH`.
- El parser tolera campos adicionales y ventanas nulas para admitir evolución compatible del protocolo.

## Criterios de aceptación

1. Una respuesta con ventanas primaria y secundaria muestra ambas con porcentaje y reinicio.
2. Una ventana nula se omite sin fallar toda la respuesta.
3. Un porcentaje se normaliza al rango 0...100 para proteger la UI.
4. El provider `openai` OAuth no aparece como gasto USD independiente.
5. La actualización manual y la periódica refrescan SQLite y la cuota Codex.
6. La aplicación compila y las pruebas unitarias pasan sin efectuar llamadas de red ni consumir modelos.

## OpenCode Zen y Go

Son fuentes distintas. `opencode-go` usa las ventanas de suscripción publicadas por Go; `opencode` corresponde a Zen, cuyo gasto local se muestra sin atribuirle los límites de Go. Solo se presentan cuando su provider está conectado en OpenCode.
