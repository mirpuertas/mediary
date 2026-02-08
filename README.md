# 📱Mediary
Privacy-first, offline health & medication journal built with Flutter.

## Status
- App languages: Spanish & English (v2)
- Localization: `l10n` (ARB)

## Descripción
Mediary es una aplicación mobile *local-first* para registrar información diaria
relacionada con la salud: sueño, ánimo y toma de medicación.

El foco del proyecto está en:
- privacidad (no hay cuentas, ni nube, ni tracking)
- funcionamiento offline
- simplicidad de uso y claridad visual

Toda la información se almacena exclusivamente en el dispositivo del usuario.

## Funcionalidades (v2)
- Registro diario de sueño (duración, calidad y notas)
- Registro de ánimo diario
- Gestión de medicamentos y grupos de medicación
- Recordatorios locales (medicamentos y grupos)
- Flujo rápido de registro desde notificaciones
- Vista de calendario y pantalla de resumen
- Exportación local (CSV / PDF / XLSX)
- Backup cifrado (exportable a la ubicación elegida por la persona usuaria)
- Cifrado de base de datos
- Bloqueo por PIN y biometría (huella / face unlock, según dispositivo)
- Registro de agua (widget de Android)
- Registro de cuadras caminadas
- Soporte de tema claro y oscuro (sin hardcoding de colores; tokens centralizados)

## Seguridad
- Base de datos cifrada
- Acceso protegido con PIN y biometría (si el dispositivo lo soporta)
- Backups cifrados exportables

## Estructura del proyecto
El repositorio corresponde a una aplicación Flutter completa.  
La organización del código dentro de `lib/` prioriza claridad, separación de
responsabilidades y facilidad de mantenimiento.

- `main.dart`: punto de entrada y bootstrap de la app
- `app/`: navegación y rutas (`navigation.dart`, `routes.dart`)
- `features/`: módulos por funcionalidad, con separación por capas:
  - `data/`: repositorios y acceso a datos
  - `state/`: controladores/estado del feature
  - `presentation/`: UI (screens, sections, widgets)
- `providers/`: controladores globales y preferencias de la app (cross-cutting),
  por ejemplo `app_preferences_controller.dart` y `theme_controller.dart`
- `services/`: servicios compartidos (por ejemplo, base de datos, notificaciones, exportación)
- `models/`: modelos de datos comunes
- `ui/` y `widgets/`: componentes reutilizables
- `utils/`: utilidades generales
- `l10n/`: recursos de internacionalización

La lógica/estado de cada dominio vive dentro de `features/*/state`. `providers/` se usa solo
para preferencias y estado global de la aplicación.

## Navegación
La estructura de navegación de la aplicación puede verse en
[docs/navigation.md](docs/navigation.md).


## Privacidad
Mediary no recopila, transmite ni almacena información fuera del dispositivo.
No requiere cuentas de usuario, no utiliza servicios en la nube y no incluye analítica ni publicidad.
La exportación y los backups se generan localmente. La aplicación no transmite datos a servidores.

Ver política de privacidad completa en
[privacy_policy.md](privacy_policy.md).

## Roadmap (ideas para v3)
- Mejoras en el flujo de recordatorios (marcar tomas antes del horario)
- Completar la integración de colores dinámicos/tokens en todo el UI (Material 3)
- Soporte de pantalla borde a borde (edge-to-edge) adaptable a Android 15+
- Cifrado de exportaciones (CSV / PDF / XLSX)
- Tests y CI básico

## Estado del repositorio
Este repositorio se publica con fines de evaluación técnica y portfolio.
No se otorga permiso para reutilizar o redistribuir el código.

## License
All rights reserved. Viewing and evaluation only.
