---
marp: true
theme: default
paginate: true
size: 16:9
title: Ejemplo de presentación con Marp
author: Daniel
description: Presentación de prueba para generar PDF con Jenkins
---

# Ejemplo de presentación con Marp

Generación automática de PDF a partir de Markdown usando **Jenkins** y **Marp**

---

# Objetivo

Crear un pipeline que:

- Obtenga el repositorio desde SCM
- Instale las dependencias necesarias
- Genere un PDF a partir de un fichero Markdown
- Archive el artefacto resultante

---

# Herramientas usadas

- **Jenkins**
- **Docker**
- **Node.js**
- **Marp CLI**
- **Chromium**

---

# Flujo del pipeline

1. Checkout del repositorio
2. Instalación de dependencias
3. Generación del PDF
4. Archivado del artefacto

---

# Ejemplo de comando

```bash
npx @marp-team/marp-cli slides/presentacion.md -o pdf/presentacion.pdf
