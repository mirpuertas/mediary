# 📱Mediary
Privacy-first, offline health & medication journal built with Flutter.

## Status
- App language: Spanish (v1)
- Planned: English localization (v2)

## Descripción
Mediary es una aplicación mobile *local-first* para registrar información diaria
relacionada con la salud: sueño, ánimo y toma de medicación.

El foco del proyecto está en:
- privacidad (no hay cuentas, ni nube, ni tracking)
- funcionamiento offline
- simplicidad de uso y claridad visual

Toda la información se almacena exclusivamente en el dispositivo del usuario.

## Funcionalidades (v1)
- Registro diario de sueño (duración, calidad y notas)
- Registro de ánimo diario
- Gestión de medicamentos y grupos de medicación
- Recordatorios locales (medicamentos y grupos)
- Flujo rápido de registro desde notificaciones
- Vista de calendario y pantalla de resumen
- Exportación de datos (CSV / PDF / XLSX) generada localmente
- Soporte de tema claro y oscuro

## Estructura del proyecto
El repositorio corresponde a una aplicación Flutter completa.  
La organización del código dentro de `lib/` prioriza claridad, separación de
responsabilidades y facilidad de mantenimiento.

- `models/`: modelos de datos
- `providers/`: manejo de estado (Provider)
- `services/`: base de datos, notificaciones y exportación
- `screens/`: pantallas de la aplicación
- `widgets/`, `ui/`, `utils/`: componentes y helpers compartidos

## Navegación
La estructura de navegación de la aplicación puede verse en
[docs/navigation.md](docs/navigation.md).

## Privacidad
Mediary no recopila, transmite ni almacena información fuera del dispositivo.
No requiere cuentas de usuario, no utiliza servicios en la nube y no incluye
analítica ni publicidad.

Ver política de privacidad completa en
[PRIVACY_POLICY.md](privacy_policy.md).

## Roadmap (ideas para v2)
- Internacionalización (español / inglés)
- Mejoras en el flujo de recordatorios (marcar tomas antes del horario)
- Información y guía sobre optimización de batería en Android
- Copias de seguridad locales (backup / restore)
- Consistencia y normalización del sistema de colores dinámicos
- Soporte de pantalla borde a borde (edge-to-edge) adaptable a Android 15+
- Mejoras de accesibilidad y pulido visual
- Tests y CI básico

## Estado del repositorio
Este repositorio se publica con fines de evaluación técnica y portfolio.
No se otorga permiso para reutilizar o redistribuir el código.

## License
All rights reserved. Viewing and evaluation only.
