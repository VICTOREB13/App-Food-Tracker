---
name: artifact-standards
description: >-
  Enforce strict YAML frontmatter schemas, file structures, Obsidian wikilink conventions,
  system code abstractions (abstractions.md), and Archify HTML diagram integration across all project artifacts
  (overview, architecture, abstractions, api_spec, implementation_plan, task, changelog, audit_report).
  Prevents typing errors, schema mismatches, and broken references.
auto_load_skills: []
permissions:
  browser: false
  terminal: false
  file_system: read_write
---

# Artifact Standards & Schema Enforcement (Anti-Typo Protocol)

This skill defines the **canonical, non-negotiable specification** for all Markdown and HTML artifacts generated in the workspace. All agents—especially `Project-Planner`, `Backend-Architect`, `Frontend-UI`, and `Systems-Auditor`—must adhere to these schemas to guarantee interoperability, zero typos, and seamless synchronization with Obsidian and CI/CD pipelines.

### 📚 Ecosistema Canónico de Artefactos Regulados

1. **`artifacts/project_overview.md`** (`tipo: overview`) - Visión general del proyecto e índice de navegación oficial.
2. **`artifacts/architecture/architecture.md`** (`tipo: arquitectura`) - Tech Stack oficial y enlace al diagrama interactivo Archify.
3. **`artifacts/architecture/architecture_diagram.html`** - Diagrama interactivo SVG compilado con Archify (especificación fuente en `artifacts/architecture/src/architecture_diagram.json`).
4. **`artifacts/architecture/api_spec.md`** (`tipo: api_spec`) - Especificación de endpoints y modelos de datos.
5. **`artifacts/architecture/abstractions.md`** (`tipo: abstracciones`) - **Abstracciones del Sistema y Arquitectura de Código** (interfaces de dominio, clases maestras, servicios de negocio, funciones puras, variables de configuración y data seams).
6. **`artifacts/planning/implementation_plan.md`** (`tipo: implementation_plan`) - Plan de iteración MVP (YAGNI & Lean UX).
7. **`artifacts/planning/task.md`** (`tipo: task_list`) - Checklist de tareas atómicas asignadas por agente (`[ ] (Nombre-Agente) Descripción`).
8. **`artifacts/planning/changelog_vX.md`** (`tipo: changelog`) - Historial versionado de cambios y releases (congelado por versión mayor).
9. **`artifacts/audit_reports/audit_report.md`** (`tipo: audit_report`) - Reporte de Quality Gate y veredicto vinculante (`veredicto: PASS` o `FAIL`).
10. **`03_Playbooks_QA/AGENTE_*.md`** (`tipo: playbook-agente`) - Playbooks de agentes con propiedades nativas para Obsidian Properties.

---

## 🛑 Golden Rules of Artifact Authoring

1. **Mandatory YAML Frontmatter:** Every `.md` artifact MUST start on line 1 with `---` and terminate the frontmatter with `---`. No text, blank lines, or comments may precede the frontmatter.
2. **Strict Field Casing:** All frontmatter keys MUST be strictly lowercased: `tipo`, `proyecto`, `version`, `iteracion`, `estado`, `fecha`, `veredicto`, `stack_principal`, `tags`.
3. **Strict Values:**
   - `tipo`: Strictly lowercase snake_case standard type (`overview`, `arquitectura`, `api_spec`, `abstracciones`, `implementation_plan`, `task_list`, `changelog`, `audit_report`).
   - `veredicto`: Strictly `PASS` or `FAIL` (uppercase).
   - `estado`: Strictly `activo`, `borrador`, `completado`, or `congelado`.
   - `fecha`: Strictly ISO format `YYYY-MM-DD` (e.g., `2026-09-08`).
   - `tags`: YAML array of lowercase kebab-case strings (e.g., `[proyecto, arquitectura, abstracciones, tech-stack]`).
4. **Obsidian-Compliant Wikilinks:**
   - In any index or cross-referencing document, links to other artifacts MUST follow the format:
     `[[PRJ_{PROYECTO}_{artefacto}|{Alias}]]`
     *Examples:* `[[PRJ_App_Food_Tracker_architecture|Arquitectura del Sistema]]`, `[[PRJ_App_Food_Tracker_abstractions|Abstracciones]]`
   - **STRICTLY PROHIBITED:** Hardcoded local file paths (e.g., `file:///C:/...`, `../planning/task.md`).
5. **No Mermaid Diagrams (Archify HTML Only & Source JSON Separation):**
   - Code blocks with ````mermaid are **STRICTLY BANNED**.
   - All architecture diagrams, component diagrams, request lifecycles, and workflows must be authored as standalone, interactive HTML files with inline SVG generated via **Archify** (e.g., `artifacts/architecture/architecture_diagram.html`).
   - **Source JSON vs Compiled HTML Convention:**
     - Archify source JSON files (candidate specifications) MUST be stored in the dedicated subfolder `artifacts/architecture/src/` (e.g., `artifacts/architecture/src/architecture_diagram.json`).
     - Compiled standalone HTML files MUST be delivered directly to `artifacts/architecture/` (e.g., `artifacts/architecture/architecture_diagram.html`).
     - This guarantees that `artifacts/architecture/` stays clean, containing exclusively deliverable `.html` diagrams and `.md` contracts.
   - Markdown documents must link to the HTML diagram using Obsidian-compatible relative syntax or wikilinks:
     `[[PRJ_{PROYECTO}_architecture_diagram.html|Diagrama de Arquitectura Interactivo (Archify)]]`
6. **Obsidian Properties Compatibility & Anti-Broken YAML Protocol:**
   - **Flat Key-Values Only:** Obsidian Properties natively parses frontmatter as a flat table of typed properties (Text, List, Number, Checkbox, Date). Never nest objects or dictionaries (e.g., `permissions:\n  browser: false`). Nested maps cause Obsidian to fail parsing the frontmatter or reject the native Properties widget, displaying raw unformatted text with error badges.
   - **No Unquoted Colons in Values:** In YAML, a colon followed by a space (`: `) is reserved syntax for key-value separation. Writing unquoted values like `modelo: Tier Flash (High) (alias: flash, Gemini Flash High)` triggers a fatal syntax parse error, displaying a red dot in Obsidian and raw plaintext `---`. Any value containing `: ` MUST either be wrapped in double quotes `"..."` or preferably separated into clean atomic properties (`tier: Tier Flash (High)` y `alias: flash`).
   - **Metadata vs Body Content Separation:** Keep frontmatter exclusively for flat classification metadata (`tipo`, `rol`, `tier`, `alias`, `proyecto`, `version`, `estado`, `fecha`, `veredicto`, `tags`). Operational instructions, skill missions, permissions, and long descriptions belong in the Markdown body (in callouts `> **Misión:** ...` or structured sections `## 📋 Especificaciones de Operación`), never inside folded block scalars (`description: >-`) when intended for Obsidian.
   - **Clean Tag Arrays:** Tags must use standard flat list format or inline arrays:
     ```yaml
     tags:
       - agentes
       - backend
     ```
     or `tags: [agentes, backend]`.

---

## 📋 Canonical Artifact Schemas

### 1. `artifacts/project_overview.md`
**Role:** Master project overview and navigation index.

```markdown
---
tipo: overview
proyecto: Nombre_Del_Proyecto
version: v0.1.0
estado: activo
fecha: YYYY-MM-DD
tags: [proyecto, overview, artefacto]
---

# 🚀 Visión General del Proyecto: [Nombre_Del_Proyecto]

> **Instrucción para Project-Planner:** Actualiza este archivo en cada iteración para reflejar qué hace el proyecto en su estado actual (términos de negocio y funcionalidad clave).

## 📖 ¿Qué hace el proyecto?
[Descripción concisa y orientada al usuario final del sistema o prototipo actual.]

---

## 🗺️ Índice Oficial de Artefactos

- **Arquitectura:** [[PRJ_{PROYECTO}_architecture|Arquitectura del Sistema]]
- **Diagrama Interactivo:** [[PRJ_{PROYECTO}_architecture_diagram.html|Diagrama HTML (Archify)]]
- **Abstracciones:** [[PRJ_{PROYECTO}_abstractions|Abstracciones]]
- **Contrato de Datos (API):** [[PRJ_{PROYECTO}_api_spec|Especificación de API y Modelos]]
- **Plan de Implementación:** [[PRJ_{PROYECTO}_implementation_plan|Plan de Implementación Actual]]
- **Checklist de Tareas:** [[PRJ_{PROYECTO}_task|Checklist de Tareas]]
- **Historial de Cambios:** [[PRJ_{PROYECTO}_changelog_v1|Registro de Versiones (Changelog)]]
- **Último Reporte de Auditoría:** [[PRJ_{PROYECTO}_audit_report|Reporte de Auditoría (Quality Gate)]]
```

---

### 2. `artifacts/architecture/architecture.md`
**Role:** Technical stack, component boundaries, and interactive diagram link.

```markdown
---
tipo: arquitectura
proyecto: Nombre_Del_Proyecto
version: v0.1.0
estado: activo
stack_principal: [Next.js, Tailwind CSS, PostgreSQL, Docker]
diagrama_html: PRJ_Nombre_Del_Proyecto_architecture_diagram.html
tags: [proyecto, arquitectura, tech-stack, archify]
---

# Arquitectura del Sistema: [Nombre_Del_Proyecto] (v[x.x.x])

> **Instrucción para Project-Planner / Backend-Architect:** Define el Tech Stack exacto y enlaza el diagrama generado con Archify. Queda estrictamente prohibido usar bloques ```mermaid.

## 🏗️ Tech Stack Oficial

- **Frontend:** [Framework, Lenguaje, Bibliotecas UI]
- **Backend:** [Framework, Lenguaje, Runtime]
- **Base de Datos & Cache:** [Motor SQL/NoSQL, Índices, ORM]
- **Infraestructura & Contenedores:** [Docker, Docker Compose, Proxy Nginx/Caddy]

---

## 📐 Diagrama de Arquitectura Interactivo (Archify)

El diagrama de componentes, flujos y fronteras del sistema se mantiene como archivo HTML independiente con SVG interactivo:

🔗 **Ver Diagrama:** [[PRJ_{PROYECTO}_architecture_diagram.html|Abrir Diagrama de Arquitectura Interactivo]]

*(Ubicación en disco: `artifacts/architecture/architecture_diagram.html` | Archivo fuente JSON: `artifacts/architecture/src/architecture_diagram.json`)*
```

---

### 3. `artifacts/architecture/api_spec.md`
**Role:** Data schemas, model definitions, and API endpoint contracts.

```markdown
---
tipo: api_spec
proyecto: Nombre_Del_Proyecto
version: v0.1.0
estado: activo
tags: [proyecto, api, backend, contratos]
---

# Especificación de API y Modelos de Datos

> **Instrucción para Backend-Architect:** Diseña aquí los modelos de base de datos y los endpoints antes de escribir código. Frontend-UI consumirá exclusivamente este contrato.

## 🗄️ Modelos de Base de Datos

### Modelo: `[NombreModelo]`
- **Tabla:** `[nombre_tabla_plural]`
- **Campos:**
  - `id`: UUID / BigInteger (Primary Key)
  - `tenant_id`: UUID (Indexed leftmost prefix para multi-tenancy si aplica)
  - `created_at` / `updated_at`: Timestamps
- **Índices Compuestos:** `[tenant_id, campo_frecuente]`

---

## 📡 Endpoints de la API

### `[METODO] /api/[ruta]`
- **Descripción:** [Propósito del endpoint]
- **Autenticación / RBAC:** [Público / Bearer Token / Role required]
- **Request Body (JSON):**
```json
{
  "campo": "valor"
}
```
- **Respuestas:**
  - `200 OK` / `201 Created`:
```json
{
  "success": true,
  "data": {}
}
```
  - `400 Bad Request` / `404 Not Found` / `500 Server Error`
```

---

### 4. `artifacts/architecture/abstractions.md`
**Role:** High-level class abstractions, domain interfaces, business services, core functions, variables/configuration, and data flow seams.

```markdown
---
tipo: abstracciones
proyecto: Nombre_Del_Proyecto
version: v0.1.0
estado: activo
fecha: YYYY-MM-DD
tags: [proyecto, arquitectura, abstracciones, backend]
---

# Abstracciones del Sistema y Arquitectura de Código

> **Instrucción para Backend-Architect:** Documenta aquí las clases maestras, interfaces de dominio, servicios de negocio, funciones utilitarias nucleares y variables globales o de configuración. Actúa como el complemento conceptual de `api_spec.md` para entender el funcionamiento interno del software sin requerir inspección línea por línea del código fuente.

## 🏛️ Filosofía de Diseño y Paradigmas de Código
- **Patrón Arquitectónico:** [Clean Architecture / DDD / Modular Monolith / MVC]
- **Principios Rectores:** [IoC/DI, Single Responsibility, Inmutabilidad, Manejo determinista de errores]

---

## 🧩 Módulos y Capas del Sistema
- **Dominio / Entidades:** [Reglas de negocio puras, Value Objects e invariantes]
- **Aplicación / Servicios:** [Casos de uso y orquestación de operaciones]
- **Infraestructura / Repositorios:** [Persistencia concreta, clientes HTTP externos y brokers]
- **Presentación / Controladores:** [Rutas, DTOs y serialización]

---

## 📐 Interfaces y Contratos de Dominio
### `I[NombreContrato]`
- **Propósito:** [Frontera de abstracción de servicio o repositorio]
- **Firmas:** `metodo(param: Tipo): Promise<Resultado>`

---

## ⚙️ Clases Núcleo y Servicios de Negocio
### Clase: `[NombreServicio]`
- **Responsabilidad:** [Propósito único / SRP]
- **Dependencias Inyectadas:** `[IDependenciaA, IDependenciaB]`
- **Métodos Clave:**
  - `ejecutarAccion(entrada: DTO): SalidaDTO`: Qué computa, efectos secundarios y excepciones controladas.

---

## 🛠️ Funciones Críticas y Lógica Pura
### `[nombreFuncion(param1, param2)]`
- **Módulo:** `utils/` o `domain/rules/`
- **Entrada / Salida:** Tipos y transformaciones deterministas sin efectos secundarios.

---

## 🌐 Variables de Estado, Constantes Globales y Configuración
- **Variables de Entorno (.env):** `VAR_NAME` (propósito, tipo, obligatoriedad y fallback seguro).
- **Enums y Constantes:** Estados de máquina, límites de concurrencia y flags de configuración.

---

## 🔄 Costuras de Flujo de Datos (Data Seams)
- **Lifecycle Request-to-Persistence:** Controller -> Service -> Repository -> Domain Event -> Response.
- **Eventos y Observers:** Eventos disparados y manejadores suscritos.
```

---

### 5. `artifacts/planning/implementation_plan.md`
**Role:** Step-by-step roadmap for current iteration under strict YAGNI.

```markdown
---
tipo: implementation_plan
proyecto: Nombre_Del_Proyecto
iteracion: v0.1.0
estado: activo
fecha: YYYY-MM-DD
tags: [proyecto, planning, mvp, yagni]
---

# Plan de Implementación (Iteración Actual)

> **Instrucción para Project-Planner:** Redacta el plan atómico paso a paso. Cumple estrictamente el principio YAGNI (sin sobre-ingeniería).

## 🎯 Objetivo de la Iteración
[Objetivo funcional concreto y medible de este ciclo MVP.]

## 🛠️ Fases de Ejecución

### Fase 1: Modelado y Contratos (Backend-Architect)
1. Definir esquema en `api_spec.md` y abstracciones en `abstractions.md`.
2. Generar migraciones e índices compuestos.

### Fase 2: Construcción de Interfaces (Frontend-UI)
1. Crear componentes modulares basados en `api_spec.md`.
2. Asegurar DOM < 800 nodos en vistas críticas.

### Fase 3: Quality Gate (Systems-Auditor)
1. Ejecutar suites automatizadas y pruebas Playwright E2E.
2. Auditar dependencias y verificar DOM.

### Fase 4: Despliegue (DevOps-Engineer)
1. Empaquetar contenedores Docker y validar `docker-compose.yml`.
```

---

### 6. `artifacts/planning/task.md`
**Role:** Atomic task checklist with explicit subagent assignment.

```markdown
---
tipo: task_list
proyecto: Nombre_Del_Proyecto
iteracion: v0.1.0
estado: activo
fecha: YYYY-MM-DD
tags: [proyecto, tasks, checklist]
---

# Checklist de Tareas

> **Instrucción para Agentes:** Marcar con `[x]` al completar cada tarea. Toda tarea debe indicar su subagente responsable explícitamente.

## Tareas Pendientes

- [ ] (Project-Planner) Diseñar arquitectura y generar `architecture_diagram.html` con Archify.
- [ ] (Backend-Architect) Redactar `api_spec.md` y `abstractions.md`, y construir migraciones/modelos.
- [ ] (Frontend-UI) Diseñar vistas responsivas consumiendo `api_spec.md`.
- [ ] (Systems-Auditor) Ejecutar auditoría automatizada con Playwright/tests y emitir veredicto en `audit_report.md`.
- [ ] (DevOps-Engineer) Configurar `Dockerfile` y `docker-compose.yml` tras aprobación de Quality Gate.
```

---

### 7. `artifacts/planning/changelog_vX.md`
**Role:** Versioned iteration and release history following Keep a Changelog.

```markdown
---
tipo: changelog
proyecto: Nombre_Del_Proyecto
version: v1
estado: activo
fecha: YYYY-MM-DD
tags: [proyecto, changelog, versiones]
---

# Registro de Cambios (Changelog) - [Nombre_Del_Proyecto]

Todos los cambios notables de este proyecto se documentarán en este archivo siguiendo [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/) y [Semantic Versioning](https://semver.org/lang/es/).

## [Unreleased]

### Added
- [Nueva funcionalidad o endpoint añadido]

### Changed
- [Modificación en arquitectura o comportamiento existente]

### Deprecated
- [Funcionalidades que se retirarán próximamente]

### Removed
- [Código o dependencias eliminadas]

### Fixed
- [Bugs resueltos reportados por Systems-Auditor]

### Security
- [Parches de seguridad y remediación de dependencias]

---

## [0.1.0] - YYYY-MM-DD
### Added
- Inicialización del prototipo MVP.
- Diagrama interactivo Archify y especificación de API.
```

---

### 8. `artifacts/audit_reports/audit_report.md`
**Role:** Unbiased Quality Gate verdict and test execution matrix.

```markdown
---
tipo: audit_report
proyecto: Nombre_Del_Proyecto
iteracion: v0.1.0
veredicto: PASS
estado: activo
fecha: YYYY-MM-DD
tags: [proyecto, audit, quality-gate]
---

# Reporte de Auditoría y Quality Gate

> **Instrucción para Systems-Auditor:** Eres el guardián imparcial de la calidad. Ningún despliegue se autoriza sin `veredicto: PASS`.

## 🧪 Matriz de Pruebas Automatizadas
- [ ] **Pruebas Unitarias / Backend:** [Estado de ejecución y comandos usados]
- [ ] **Pruebas E2E / Playwright:** [Navegación en browser, snapshots tomados]

## 📊 Rendimiento y Nodos DOM
- [ ] **Auditoría de DOM:** [Cantidad máxima de nodos medida en las vistas. Límite < 800 recomendado, < 1400 máximo tolerable]
- [ ] **Consultas N+1:** [Verificación de queries y carga ansiosa]

## 🛡️ SecOps y Dependencias
- [ ] **Escaneo de Vulnerabilidades:** [`npm audit` o `composer audit` con 0 vulnerabilidades altas/críticas]
- [ ] **Control de Acceso / IDOR:** [Verificación de tenancy y autorización]

---

## 🚦 Veredicto Final

**Status:** PASS
*(O `Status: FAIL` si se incumplió algún criterio. Justificar la razón y reasignar tareas en `task.md`)*
```

### 9. Playbooks de Agentes y Notas de Bóveda Obsidian: `03_Playbooks_QA/AGENTE_*.md`
**Role:** Definición operativa y visualización nativa en Obsidian Properties.

```markdown
---
tipo: playbook-agente
rol: Autonomous Subagent
tier: Tier Flash (High)
alias: flash
estado: activo
tags:
  - agentes
  - backend
  - subagentes
  - modelos
---

# Nombre del Agente (Rol)

> **Misión:** Resumen de alto nivel de las funciones y límites del agente.

## 📋 Especificaciones de Operación
- **Tier & Modelo:** **Tier Flash (High)** (alias Antigravity: `flash`, Gemini Flash High; ver `[[DOC_Modelos_Tiers|.agents/models.yaml]]`).
- **Autoload Skills:** `skill-1`, `skill-2`, `artifact-standards`.
- **Herramientas MCP:** `context7`, `playwright`.
- **Permisos:** Terminal (true), Filesystem (Read/Write), Browser (false).

---
```

---

## 🔍 Checklist Anti-Errores de Tipeo (Pre-Flight Check)

Antes de guardar o confirmar cualquier artefacto o documento en disco, verifica:

| Ítem a Comprobar | Regla Estricta | Error Típico a Evitar |
| :--- | :--- | :--- |
| **Claves de Frontmatter** | Solo minúsculas (`tipo`, `proyecto`, `veredicto`) | ❌ `Tipo:`, `Project:` |
| **Estructura Frontmatter** | Estrictamente plana (flat properties). Cero objetos/diccionarios anidados | ❌ `permissions:\n  terminal: true` |
| **Dos Puntos en Valores** | Valores con `: ` entrecomillados `"..."` o en claves atómicas separadas (`tier`, `alias`) | ❌ `modelo: Tier Flash (alias: flash)` sin comillas |
| **Descripciones Largas** | En el cuerpo Markdown (`> **Misión:** ...`), nunca en frontmatter | ❌ `description: >-` en notas de Obsidian |
| **Veredicto Auditor** | Mayúsculas exactas: `PASS` o `FAIL` | ❌ `Pass`, `Aprobado`, `fail` |
| **Formato Fecha** | `YYYY-MM-DD` | ❌ `DD/MM/YYYY`, `Sept 8 2026` |
| **Wikilinks Obsidian** | `[[PRJ_{PROYECTO}_{archivo}|{Alias}]]` | ❌ `[link](file:///...)`, `[[archivo]]` sin prefijo |
| **Diagramas** | Archivos `.html` con Archify en `artifacts/architecture/` (JSONs fuente en `src/`) | ❌ Bloques ````mermaid o `.json` sueltos en raíz de `artifacts/architecture/` |
| **Asignación de Tareas** | `[ ] (Agente-Asignado) Descripción` | ❌ `[ ] Backend: ...` sin paréntesis |
