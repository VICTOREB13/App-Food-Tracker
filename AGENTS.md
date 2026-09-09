# Protocolo de Orquestación de Agentes y Subagentes (Teamwork)

Este workspace opera bajo la metodología de **Prototipado Evolutivo** implementada a través de un **Orquestador Principal** y un **Pool de Subagentes Especializados**, respaldados por un **Bus Central de Artefactos**, herramientas **MCP de Testing y Contexto**, y diagramas HTML nativos con **Archify**.

---

## 1. Asignación de Modelos de IA y Autoload Skills
*(Centralizado en `.agents/models.yaml` como Single Source of Truth)*
* **Agente Principal (Chat / Orquestador):** Configurado en **Tier Pro (High)** (alias Antigravity: `pro`, Gemini Pro High).
  * Habilidad: `Project-Planner` (`.agents/skills/project-planner/SKILL.md`)
  * Autoload Skills: `archify`, `artifact-standards`, `improve-codebase-architecture`, `lean-ux`
* **Subagentes Autónomos:** Se ejecutan en contextos aislados bajo **Tier Flash (High)** (alias Antigravity: `flash`, Gemini Flash High):
  * `Backend-Architect` (`.agents/skills/backend-architect/SKILL.md`)
    * Autoload Skills: `improve-codebase-architecture`, `sqlite-local-first-flutter`, `artifact-standards`
  * `Frontend-UI` (`.agents/skills/frontend-ui/SKILL.md`)
    * Autoload Skills: `ui-ux-pro-max`, `design-taste-frontend`, `refactoring-ui`, `redesign-existing-projects`, `vercel-react-best-practices`, `flutter-production-engineering`, `web-typography`, `microinteractions`, `top-design`, `design-everyday-things`, `artifact-standards`
  * `Systems-Auditor` (`.agents/skills/systems-auditor/SKILL.md`)
    * Autoload Skills: `ux-heuristics`, `vercel-react-best-practices`, `design-everyday-things`, `artifact-standards`
  * `DevOps-Engineer` (`.agents/skills/devops-engineer/SKILL.md`)
    * Autoload Skills: `artifact-standards`

---

## 2. Regla Fundamental de Ejecución (No Coding en Chat Principal)
1. El **Agente Principal (Project-Planner)** tiene estrictamente prohibido escribir código de producción, tests o dockerfiles directamente en el chat raíz.
2. Su función exclusiva es:
   - Investigar el repositorio.
   - Diseñar la arquitectura técnica en `artifacts/architecture/architecture.md` y compilar el diagrama interactivo con `archify`.
   - Redactar el plan en `artifacts/planning/implementation_plan.md` bajo estricto principio YAGNI.
   - Desglosar las tareas atómicas en `artifacts/planning/task.md`.
   - Despachar **subagentes** bajo **Tier Flash (High)** (alias Antigravity: `flash`) para cada tarea técnica.
   - Monitorear el progreso y presentar los resultados finales al usuario.

---

## 3. Bus de Comunicación por Artefactos (`artifacts/`) y Estándares YAML
Los subagentes no comparten ventana de chat; su memoria compartida son los archivos en disco:
* **Estándar de Artefactos:** Regulado por `artifact-standards/SKILL.md` (frontmatter YAML estricto en minúsculas, fechas ISO, enlaces Wikilink con prefijo `[[PRJ_{PROYECTO}_{artefacto}|Alias]]`).
* **Entradas para Backend/Frontend:** `architecture.md`, `implementation_plan.md` y `task.md`.
* **Salida de Backend / Entrada de Frontend y Auditoría:** `api_spec.md` (contratos de API y modelos de base de datos) y `abstractions.md` (abstracciones de clases, interfaces de dominio, servicios nucleares, funciones críticas y costuras de flujo de datos).
* **Salida de Auditoría / Bloqueo de Despliegue:** `audit_reports/audit_report.md` (`veredicto: PASS` obligatorio para DevOps).
* **Historial de Versiones:** `changelog_vX.md`.
* **Diagramas de Sistema:** Formato HTML autónomo con SVG generado por **Archify** (`architecture_diagram.html`). Los archivos JSON fuente residen en `artifacts/architecture/src/` y los compilados HTML se entregan directamente en `artifacts/architecture/`. Queda **estrictamente prohibido** el uso de bloques ```mermaid.

---

## 4. Integración de Servidores MCP
* **`context7` MCP:** Obligatorio para todos los agentes. Consulta la documentación oficial actualizada (`resolve-library-id` y `query-docs`) de cualquier framework, ORM, SDK o biblioteca antes de codificar o planificar.
* **`playwright` MCP:** Utilizado por `Systems-Auditor` y `Frontend-UI` para pruebas E2E en navegadores reales, medición exacta de nodos DOM (`document.querySelectorAll('*').length`), inspección visual con screenshots y detección de errores en consola.
* **`obsidian` MCP:** Mantiene la base de conocimiento y los playbooks sincronizados entre el entorno local y la bóveda en Obsidian.
