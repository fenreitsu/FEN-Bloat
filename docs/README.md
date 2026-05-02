# FEN-Bloat - Windows Utility & Debloater

> Una fusion de lo mejor de **Win11Debloat** y **Chris Titus WinUtil** en una herramienta modular de PowerShell.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue)
![Windows](https://img.shields.io/badge/Windows-10%2F11-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

---

> [!WARNING]
> **DISCLAIMER IMPORTANTE**
>
> Este proyecto esta en **desarrollo activo**. No esta listo para entornos de produccion.
>
> - Este script realiza **cambios significativos en el sistema operativo** (registro de Windows, eliminacion de aplicaciones, modificacion de servicios).
> - **Siempre crea un punto de restauracion** antes de ejecutar cualquier funcion de debloat o tweaks.
> - Ejecuta este script **bajo tu propio riesgo**. Los autores no son responsables de danos al sistema, perdida de datos o comportamiento inesperado.
> - Se recomienda probar primero en una maquina virtual o equipo de prueba.

---

## Descripcion

FEN-Bloat es una herramienta modular para Windows que elimina aplicaciones preinstaladas no deseadas, instala programas utiles, desactiva la telemetria de Microsoft y aplica ajustes de configuracion para limpiar y personalizar tu sistema.

Arquitectura modular con scripts independientes, GUI en WPF con tema oscuro/claro, y modo CLI completo para automatizacion.

## Caracteristicas

### Debloat - Eliminacion de Bloatware

Elimina **33+ aplicaciones preinstaladas** de Windows con un click:

| Categoria | Apps |
|-----------|------|
| **Gaming & Xbox** | Xbox Console Companion, Xbox Game Bar, Xbox Identity Provider, Xbox Game Overlay, Xbox Speech To Text, Xbox TCUI, Xbox App |
| **Social** | Skype, People |
| **Microsoft Apps** | Bing Weather, Bing News, Bing Search, Get Help, Get Started/Tips, 3D Viewer, Paint 3D, Power Automate, Print 3D, Feedback Hub, Phone Link, Microsoft Family, Cortana, Widgets, Mail & Calendar |
| **Games** | Solitaire Collection, Candy Crush Saga, Candy Crush Soda |
| **Utilities** | Alarms & Clock, Camera, Maps, Sound Recorder |
| **Media** | Groove Music, Movies & TV |
| **Office** | OneNote, Office Hub, Sticky Notes, To Do |
| **Cloud** | OneDrive |
| **Other** | Clipchamp |

**Boton "Remove Needless Apps"**: Selecciona automaticamente 28 apps recomendadas para eliminacion segura.

**"Uninstall Selected"**: Permite desinstalar tanto bloatware como apps instalables desde el mismo panel, con streaming en tiempo real de la salida de winget a la terminal.

### Instalaciones - Aplicaciones Recomendadas

Categorias organizadas con **28+ aplicaciones** de terceros via `winget`:

| Categoria | Apps |
|-----------|------|
| **Essentials** | Google Chrome, Mozilla Firefox, 7-Zip, Notepad++, PowerToys, Adobe Reader |
| **Utilities** | CPU-Z, CrystalDiskInfo, ShareX, Everything, Windows Terminal |
| **Gaming** | Steam, Discord, OBS Studio, Playnite |
| **Dev Tools** | VS Code, Git, Python (latest), Docker Desktop, .NET SDK |
| **Creative** | GIMP, Blender, Audacity, VLC, HandBrake |
| **Social** | Discord, Zoom, Slack |

Cada app muestra un indicador **(Latest)** con un link clickeable (`>>`) a la pagina de descargas oficial para ver la version que se instalara.

**Funciones de instalacion**:
- Instalacion individual o masiva con `Install/Upgrade Apps`
- `Upgrade All`: Actualiza todas las apps instaladas con winget
- Exportar lista de apps instaladas a JSON
- Importar y reinstalar desde archivo JSON
- Salida en tiempo real a la terminal durante la instalacion

### Tweaks & Privacidad

**15 tweaks** organizados en 3 categorias:

**Privacy & AI:**
- Desactivar Telemetria y Diagnostico
- Desactivar Bing Search en Windows Search
- Desactivar Microsoft Copilot
- Desactivar Windows Recall
- Desactivar Widgets

**System & UI:**
- Activar Modo Oscuro del sistema
- Mostrar Extensiones de Archivo
- Menu Contextual Clasico (estilo Windows 10)
- Desactivar Xbox Game Bar y DVR
- Activar "End Task" en la barra de tareas
- Desactivar Inicio Rapido (Fast Startup)

**Notifications & Taskbar:**
- Desactivar Notificaciones Sugeridas
- Desactivar Apps en Segundo Plano de Terceros
- Desactivar Delivery Optimization (P2P)
- Desactivar Pantalla de Bloqueo

**Boton "Recommended"**: Selecciona automaticamente 9 tweaks seguros recomendados.

Todos los cambios de registro se **respaldan automaticamente** antes de aplicarse.

### Herramientas del Sistema

| Herramienta | Funcion |
|-------------|---------|
| **Repair Windows Update** | Reinicia componentes de Windows Update (servicios y carpetas de catalogo) |
| **Run SFC & DISM** | Ejecuta `sfc /scannow` seguido de `DISM /Online /Cleanup-Image /RestoreHealth` |
| **Clean Temporary Files** | Limpia carpetas TEMP, TMP, Windows\Temp, Prefetch, INetCache |
| **Create Restore Point** | Crea punto de restauracion "FEN-Bloat Restore Point" |
| **MicroWin (ISO Creator)** | Informacion para crear ISO personalizada de Windows |
| **Open Logs Folder** | Abre la carpeta de logs en Explorer |

### GUI

- **3 pestañas**: Install, Tweaks, Tools
- **Tema Oscuro y Claro** con conmutacion dinamica (detecta el tema del sistema al inicio)
- **Barra de progreso** animada durante operaciones
- **Estado dinamico** que muestra apps/tweaks seleccionados
- **Logos personalizados** por tema
- **Botones con colores semanticos**: azul (principal), amarillo (advertencia), rojo (peligro), gris (secundario)
- **Checkboxes con animacion** y estilo personalizado
- **Scrollbar estilizada** con thumb redondeado
- Ventana redimensionable con bordes redondeados y barra de titulo custom

### CLI

Modo linea de comandos completo para automatizacion y despliegue masivo. Compatible con scripts de provisioning.

## Requisitos

- **Windows 10** (version 1809 o superior)
- **Windows 11** (todas las versiones 21H2+)
- **PowerShell 5.1** o superior (incluido en Windows)
- **Privilegios de Administrador** (el script los solicita automaticamente)
- **WinGet** (requerido para la pestaña de instalaciones, opcional para debloat)

## Instalacion y Uso

### Clonar el Repositorio (Recomendado)

```powershell
git clone https://github.com/fenreitsu/FEN-Bloat.git
cd FEN-Bloat
```

### Ejecutar

```powershell
# Abrir PowerShell como Administrador
.\FEN-Bloat.ps1
```

### Modo CLI (Sin GUI)

```powershell
# Desactivar telemetria y eliminar apps de Xbox
.\FEN-Bloat.ps1 -NoGUI -DisableTelemetry -RemoveXboxApps

# Instalar aplicaciones especificas
.\FEN-Bloat.ps1 -NoGUI -InstallApps Google.Chrome,7zip.7zip,Git.Git

# Multiple acciones
.\FEN-Bloat.ps1 -NoGUI -DisableTelemetry -DisableCopilot -EnableDarkMode -ShowFileExtensions -InstallApps Google.Chrome,7zip.7zip

# Reparar Windows Update y ejecutar SFC
.\FEN-Bloat.ps1 -NoGUI -RepairWindowsUpdate -RunSFCAndDISM

# Exportar lista de apps instaladas
.\FEN-Bloat.ps1 -NoGUI -ExportAppList "C:\MisApps.json"

# Importar y reinstalar desde lista
.\FEN-Bloat.ps1 -NoGUI -ImportAppList "C:\MisApps.json"
```

### Parametros CLI Disponibles

| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| `-NoGUI` | switch | Ejecutar sin interfaz grafica |
| `-DisableTelemetry` | switch | Desactivar telemetria y diagnostico |
| `-RemoveXboxApps` | switch | Eliminar aplicaciones de Xbox |
| `-DisableCopilot` | switch | Desactivar Microsoft Copilot |
| `-DisableRecall` | switch | Desactivar Windows Recall |
| `-DisableBingSearch` | switch | Desactivar Bing Search |
| `-EnableDarkMode` | switch | Activar modo oscuro del sistema |
| `-ShowFileExtensions` | switch | Mostrar extensiones de archivo |
| `-ClassicContextMenu` | switch | Restaurar menu contextual clasico |
| `-DisableGameBar` | switch | Desactivar Xbox Game Bar y DVR |
| `-UpdateWinget` | switch | Actualizar fuentes de winget |
| `-InstallApps <ids>` | string[] | Instalar apps via winget |
| `-UpdateAllApps` | switch | Actualizar todas las apps instaladas |
| `-RepairWindowsUpdate` | switch | Reparar componentes de Windows Update |
| `-RunSFCAndDISM` | switch | Ejecutar SFC y DISM |
| `-CleanTemporaryFiles` | switch | Limpiar archivos temporales |
| `-CreateRestorePoint` | switch | Crear punto de restauracion |
| `-ExportAppList <path>` | string | Exportar lista de apps a JSON |
| `-ImportAppList <path>` | string | Importar y instalar desde JSON |
| `-ForceUpdate` | switch | Forzar actualizacion del script |
| `-NoAutoUpdate` | switch | Saltar verificacion automatica de actualizaciones |

## Estructura de Archivos

```
FEN-Bloat/
├── FEN-Bloat.ps1                    # Script principal (punto de entrada)
├── Config/
│   ├── Apps.json                    # Apps instalables por categoria
│   ├── Features.json                # Definicion de tweaks disponibles
│   └── DefaultSettings.json         # Configuracion por defecto
├── Schemas/
│   ├── MainWindow.xaml              # Layout de la GUI
│   └── SharedStyles.xaml            # Estilos y temas
├── Scripts/
│   ├── Core/
│   │   └── Core-Functions.ps1       # Funciones auxiliares (logging, registro, admin)
│   ├── GUI/
│   │   ├── Show-MainWindow.ps1      # Logica de la GUI (pestanas, handlers, eventos)
│   │   └── GUI-Helpers.ps1          # Helpers UI (checkboxes, progress bar, tema)
│   ├── Debloat/
│   │   └── Debloat-Functions.ps1    # Funciones de eliminacion de bloatware
│   └── Install/
│       └── Install-Functions.ps1    # Funciones de instalacion via winget
├── assets/
│   ├── fenreitsu.png                # Logo modo claro (GUI)
│   ├── fenreitsu-white.png          # Logo modo oscuro (GUI)
│   └── fenreitsu-cli-icon.txt       # ASCII art para terminal
├── Logs/                            # (generado en runtime)
│   └── FEN-Bloat.log                # Registro de operaciones
├── Backups/                         # (generado en runtime)
│   └── RegistryBackup_*.json        # Backups de cambios de registro
├── .gitignore
├── compile.ps1                      # Script de validacion (legacy)
└── docs/
    └── README.md                    # Este archivo
```

## Flujo de Ejecucion

```
Usuario ejecuta FEN-Bloat.ps1
        |
        v
Verificar Administrador --NO--> Reiniciar con -Verb RunAs
        | SI
        v
Mostrar ASCII art logo + info de usuario
        |
        v
Verificar archivos requeridos (MainWindow.xaml, SharedStyles.xaml)
        |
        v
Cargar Apps.json + Features.json + DefaultSettings.json
        |
        v
Verificar WinGet (advertencia si no disponible)
        |
        v
¿Parametros CLI? --SI--> Ejecutar acciones CLI y salir
        | NO
        v
Mostrar GUI principal (3 pestañas)
        |
        v
Usuario interactua con las pestañas
        |
        v
Cada operacion: try/catch + log + backup registro + streaming a terminal
        |
        v
Log "FEN-Bloat finished"
```

## Formato del Log

```
[2026-05-01 22:14:59] [INFO] [CORE] === FEN-Bloat v1.0.0 started ===
[2026-05-01 22:14:59] [INFO] [CORE] User: reias | PC: REIOS
[2026-05-01 22:15:30] [INFO] [INSTALL] Installing Google.Chrome (1/6)...
[2026-05-01 22:16:15] [SUCCESS] [INSTALL] Google.Chrome installed successfully
[2026-05-01 22:16:20] [INFO] [DEBLOAT] Removing 5 selected bloatware apps
[2026-05-01 22:16:25] [SUCCESS] [DEBLOAT] Removed: Microsoft.XboxApp
[2026-05-01 22:16:26] [ERROR] [DEBLOAT] Error removing Microsoft.SkypeApp: not found
```

Colores en consola:
- **Gris**: INFO
- **Verde**: SUCCESS
- **Rojo**: ERROR
- **Amarillo**: WARNING

## Seguridad

- **Backup de registro**: Cada cambio de registro se respalda automaticamente antes de aplicarse. Los backups se guardan en `Backups/RegistryBackup_*.json`.
- **Punto de restauracion**: Funcion incluida para crear un punto antes de cambios masivos.
- **Sin codigo externo**: No se descarga ni ejecuta codigo de fuentes no verificadas.
- **Try/Catch**: Todas las operaciones estan envueltas en manejo de errores.
- **Logs completos**: Cada accion se registra con timestamp, nivel y modulo.
- **Configuracion editable**: Apps.json permite personalizar que apps se ofrecen para instalacion.

## Solucion de Problemas

### WinGet no disponible
```powershell
# Verificar si esta instalado
winget --version

# Instalar desde Microsoft Store
# https://apps.microsoft.com/detail/9NBLGGH4NNS1

# O instalar winget-cli desde GitHub
# https://github.com/microsoft/winget-cli/releases
```

### Error de ejecucion
```powershell
# Verificar politica de ejecucion
Get-ExecutionPolicy

# Cambiar si es necesario (como admin)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Permisos de administrador
El script se reinicia automaticamente con privilegios elevados. Si falla:
```powershell
Start-Process powershell.exe -Verb RunAs -ArgumentList "-File `"$PWD\FEN-Bloat.ps1`""
```

### La GUI no aparece
Verifica que los archivos XAML existan:
```powershell
Test-Path "Schemas\MainWindow.xaml"
Test-Path "Schemas\SharedStyles.xaml"
```

## Contribuir

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/NombreFeature`)
3. Commit tus cambios (`git commit -m 'Add NombreFeature'`)
4. Push a la rama (`git push origin feature/NombreFeature`)
5. Abre un Pull Request

## Licencia

Distribuido bajo la licencia MIT. Ver `LICENSE` para mas informacion.

## Creditos

Proyecto inspirado en:
- **[Win11Debloat](https://github.com/Raphire/Win11Debloat)** por Raphire
- **[Chris Titus WinUtil](https://github.com/ChrisTitusTech/winutil)** por ChrisTitusTech

## Disclaimer

Este software se proporciona "tal cual", sin garantia de ningun tipo, expresa o implicita. Los autores no son responsables de ningun daño directo, indirecto, incidental o consecuente que resulte del uso de este script. **Siempre realiza un punto de restauracion antes de ejecutar funciones de debloat o tweaks.** Usar bajo tu propia responsabilidad.
