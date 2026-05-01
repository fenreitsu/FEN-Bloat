# FEN-Bloat - Windows Utility & Debloater

> Una fusion de lo mejor de **Win11Debloat** y **Chris Titus WinUtil** en un solo script de PowerShell.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue)
![Windows](https://img.shields.io/badge/Windows-10%2F11-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

## Descripcion

A lightweight script for Windows that removes apps you don't use, installs useful programs, disables data sending to Microsoft, and makes basic adjustments to clean and customize your system.

Todo en **un solo archivo `.ps1`**, sin dependencias externas (excepto winget para instalaciones).

## Caracteristicas

### Debloat
- Eliminacion de 45+ aplicaciones preinstaladas (Xbox, Skype, OneDrive, Cortana, etc.)
- Desactivacion completa de telemetria y diagnostico de Microsoft
- Desactivacion de AI features: Copilot, Recall, Click to Do
- Desactivacion de Bing Search en Windows Search
- Modo oscuro del sistema
- Menu contextual clasico estilo Windows 10
- Desactivacion de Game Bar, DVR y servicios de gaming

### Instalaciones
- Categorias organizadas: Essentials, Utilities, Gaming, Dev Tools, Creative
- Busqueda en vivo de aplicaciones
- Instalacion silenciosa via `winget`
- Actualizacion masiva de todas las aplicaciones
- Exportar/importar listas de apps (JSON/CSV) para reinstalacion despues de formateo
- Enlaces directos a Microsoft Store

### Tweaks & Configuracion
- Tweaks avanzados de registro con backup automatico
- Control de Windows Updates (pausar, forzar busqueda)
- MicroWin - Creacion de ISO personalizada de Windows
- Creacion de puntos de restauracion
- Reversion de cambios desde backups

### Herramientas
- Reparacion de Windows Update (reset de catalogo)
- SFC /scannow + DISM /RestoreHealth
- Limpieza de archivos temporales
- Liberador de espacio en disco (CleanMgr)
- Informacion del sistema
- Accesos rapidos a herramientas de Windows
- Exportacion de lista de apps instaladas

### GUI
- Interfaz moderna con 4 pestañas
- **Tema Oscuro y Claro** (conmutable)
- Barra de progreso en tiempo real
- Barra de estado con mensajes informativos
- Logos personalizados por tema
- Configuracion persistente entre sesiones

### CLI
- Modo linea de comandos sin GUI
- Parametros para automatizacion
- Ideal para scripts de despliegue masivo

## Requisitos

- **Windows 10** (version 1809 o superior)
- **Windows 11** (todas las versiones 21H2+)
- **PowerShell 5.1** o superior (incluido en Windows)
- **Privilegios de Administrador**
- **WinGet** (opcional, solo para pestaña de instalaciones)

## Instalacion y Uso

### Metodo Rapido (Recomendado)

```powershell
# Abrir PowerShell como Administrador y ejecutar:
irm "https://raw.githubusercontent.com/TU_USUARIO/FEN-Bloat/main/FEN-Bloat.ps1" | iex
```

### Metodo Manual

1. Descargar `FEN-Bloat.ps1` desde [Releases](https://github.com/TU_USUARIO/FEN-Bloat/releases)
2. Extraer el archivo ZIP
3. Abrir PowerShell como **Administrador**
4. Navegar a la carpeta y ejecutar:

```powershell
.\FEN-Bloat.ps1
```

### Modo CLI (Sin GUI)

```powershell
# Desactivar telemetria y eliminar apps de Xbox
.\FEN-Bloat.ps1 -NoGUI -DisableTelemetry -RemoveXboxApps

# Instalar aplicaciones especificas
.\FEN-Bloat.ps1 -NoGUI -InstallApps Google.Chrome,7zip.7zip,Git.Git

# Multiple acciones
.\FEN-Bloat.ps1 -NoGUI -DisableTelemetry -DisableCopilot -EnableDarkMode -ShowFileExtensions -InstallApps "Google.Chrome","7zip.7zip"

# Reparar Windows Update y ejecutar SFC
.\FEN-Bloat.ps1 -NoGUI -RepairWindowsUpdate -RunSFCAndDISM

# Exportar lista de apps instaladas
.\FEN-Bloat.ps1 -NoGUI -ExportAppList "C:\MisApps.json"

# Importar y reinstalar desde lista
.\FEN-Bloat.ps1 -NoGUI -ImportAppList "C:\MisApps.json"
```

### Parametros Disponibles

| Parametro | Descripcion |
|-----------|-------------|
| `-NoGUI` | Ejecutar sin interfaz grafica |
| `-DisableTelemetry` | Desactivar telemetria y diagnostico |
| `-RemoveXboxApps` | Eliminar aplicaciones de Xbox |
| `-DisableCopilot` | Desactivar Microsoft Copilot |
| `-DisableRecall` | Desactivar Windows Recall |
| `-DisableBingSearch` | Desactivar Bing Search |
| `-EnableDarkMode` | Activar modo oscuro del sistema |
| `-ShowFileExtensions` | Mostrar extensiones de archivo |
| `-ClassicContextMenu` | Restaurar menu contextual clasico |
| `-DisableGameBar` | Desactivar Xbox Game Bar y DVR |
| `-InstallApps <ids>` | Instalar apps via winget |
| `-UpdateAllApps` | Actualizar todas las apps |
| `-UpdateWinget` | Actualizar fuentes de winget |
| `-RepairWindowsUpdate` | Reparar Windows Update |
| `-RunSFCAndDISM` | Ejecutar SFC y DISM |
| `-CleanTemporaryFiles` | Limpiar archivos temporales |
| `-CreateRestorePoint` | Crear punto de restauracion |
| `-ExportAppList <path>` | Exportar lista de apps a JSON |
| `-ImportAppList <path>` | Importar y instalar desde JSON |

## Estructura de Archivos

```
C:\FEN-Bloat\
├── Logs\
│   └── FEN-Bloat.log           # Registro de todas las operaciones
├── Config\
│   └── LastUsed.json           # Configuracion persistente (tema, selecciones)
├── Backups\
│   └── RegistryBackup_*.json   # Backups de cambios de registro
├── FEN-Bloat.ps1               # Script principal
├── assets\
│   ├── fenreitsu.png           # Logo modo claro
│   └── fenreitsu-white.png     # Logo modo oscuro
└── README.md                   # Este archivo
```

## Formato del Log

```
[2026-04-30 10:30:15] [INFO] [DEBLOAT] Iniciando eliminacion de bloatware: 5 apps seleccionadas
[2026-04-30 10:30:16] [SUCCESS] [DEBLOAT] Eliminado: Microsoft.XboxApp
[2026-04-30 10:30:17] [ERROR] [DEBLOAT] Error eliminando Microsoft.SkypeApp: package no encontrado
[2026-04-30 10:31:00] [INFO] [INSTALL] Instalando Google Chrome via winget
[2026-04-30 10:31:45] [SUCCESS] [INSTALL] Google Chrome instalado correctamente
```

## Estructura Interna del Script

El script esta organizado en regiones para facilitar el mantenimiento:

| Region | Contenido |
|--------|-----------|
| REGION 1 | Parametros y configuracion inicial |
| REGION 2 | Funciones auxiliares comunes |
| REGION 3 | Modulo Debloat |
| REGION 4 | Modulo Instalaciones (winget) |
| REGION 5 | Modulo Tweaks y Herramientas |
| REGION 6 | Configuracion persistente |
| REGION 7 | Modo CLI |
| REGION 8 | GUI (Windows Forms) |
| REGION 9 | Punto de entrada principal |

## Flujo de Ejecucion

```
Usuario ejecuta FEN-Bloat.ps1
        |
        v
Verificar Administrador --NO--> Reiniciar con -Verb RunAs
        | SI
        v
Verificar WinGet (opcional)
        |
        v
Verificar actualizaciones en GitHub (async)
        |
        v
Cargar configuracion guardada (LastUsed.json)
        |
        v
¿Parametros CLI? --SI--> Ejecutar acciones y salir
        | NO
        v
Mostrar GUI principal
        |
        v
Usuario interactua con las 4 pestañas
        |
        v
Cada operacion: try/catch + log + backup registro
        |
        v
Guardar configuracion y estado
```

## Seguridad

- Todos los cambios de registro se **respaldan automaticamente** antes de aplicar
- Creacion de **punto de restauracion** recomendado antes de cambios masivos
- Funcion de **reversion de cambios** para restaurar valores originales
- Cada operacion envuelta en `try/catch` con manejo de errores
- Sin descarga ni ejecucion de codigo externo no verificado

## Solucion de Problemas

### WinGet no disponible
```powershell
# Instalar desde Microsoft Store o via winget-cli
winget install --id Microsoft.WinGet
```

### Error de ejecucion
```powershell
# Verificar politica de ejecucion
Get-ExecutionPolicy

# Cambiar si es necesario (como admin)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Permisos de administrador
El script se reinicia automaticamente con privilegios elevados. Si falla, ejecutar manualmente:
```powershell
Start-Process powershell.exe -Verb RunAs -ArgumentList "-File `"$PWD\FEN-Bloat.ps1`""
```

## Contribuir

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Distribuido bajo la licencia MIT. Ver `LICENSE` para mas informacion.

## Creditos
- Me he inspirado directamente en:
- **Win11Debloat** - [Raphire/Win11Debloat](https://github.com/Raphire/Win11Debloat)
- **WinUtil** - [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil)

## Disclaimer

Este script realiza cambios significativos en el sistema operativo. **Siempre crea un punto de restauracion antes de usarlo**. Los autores no son responsables de danos al sistema. Usar bajo tu propia responsabilidad.
