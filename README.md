# Hyprland Dynamic Wallpaper

Un script ligero y optimizado para cambiar dinámicamente el fondo de pantalla en Hyprland, diseñado con enfoque en el rendimiento, cero retraso (zero-delay) y mitigación de desgaste en discos SSD.

## ¿Qué hace este script?

Este script sincroniza un conjunto de imágenes en un directorio para cambiar a lo largo del día de forma progresiva. Calcula de forma precisa qué imagen debe mostrarse en base al tiempo transcurrido desde la medianoche y el número total de imágenes disponibles, garantizando una transición uniforme durante las 24 horas del día.

## ¿Cómo funciona?

### Optimización en RAM (`tmpfs`) y Prevención de Desgaste SSD
El script genera dinámicamente el archivo de configuración temporal para `hyprpaper` en la ruta `/tmp/hyprpaper_dynamic.conf`. Dado que en la mayoría de las distribuciones Linux `/tmp` está montado bajo **`tmpfs`** (es decir, en la memoria RAM), el archivo se crea y sobreescribe sin tocar el almacenamiento persistente. Al escribir la configuración en RAM en lugar de en el disco duro, **evitamos realizar cientos de escrituras innecesarias en tu SSD (SSD wear and tear)**, lo cual prolonga significativamente la vida útil de la unidad.

### Compatibilidad con sintaxis de `hyprpaper` v0.8+
En versiones recientes de `hyprpaper` (v0.8.3 y superiores), los métodos tradicionales mediante IPC suelen presentar problemas o encontrarse bloqueados por defecto por políticas de seguridad (`ipc = off`). Este script realiza un bypass de estas limitaciones generando directamente un archivo que sigue la nueva sintaxis:

```hyprlang
wallpaper {
    monitor = 
    path = /ruta/a/la/imagen.png
    fit_mode = cover
}
```

El script finaliza limpiamente la instancia anterior (`pkill`) y recarga la nueva apuntando al archivo temporal en `/tmp`. Gracias a que pre-carga los arrays de forma nativa en Bash, evita utilizar subcomandos pesados como `find` cada vez que se ejecuta, garantizando una visualización casi instantánea. Entre cada transición de fondo, el script calcula los segundos exactos restantes y entra en estado de reposo ligero con `sleep`, resultando en un uso de CPU prácticamente nulo (0%).

## Instalación y Uso

1. Clona este repositorio en tu sistema:
   ```bash
   git clone https://github.com/tu-usuario/hyprland-dynamic-wallpaper.git
   cd hyprland-dynamic-wallpaper
   ```

2. Otorga permisos de ejecución al script:
   ```bash
   chmod +x wallpapers.sh
   ```

3. **(Importante):** Edita la variable `DIR` dentro de `wallpapers.sh` para que apunte al directorio donde guardas tu secuencia de imágenes dinámicas. Por defecto asume `$HOME/.local/share/backgrounds/parasite-wallpaper`.

4. Agrégalo al autostart dentro de la configuración de Hyprland (`~/.config/hypr/hyprland.conf`):
   ```hyprlang
   exec-once = /ruta/absoluta/a/hyprland-dynamic-wallpaper/wallpapers.sh
   ```

## Roadmap

- [ ] **Migración a C/Rust**: Está planificado reescribir por completo la lógica del script usando un lenguaje de bajo nivel como C o Rust. El objetivo es:
  - Disminuir drásticamente el uso de memoria (RAM footprint).
  - Interactuar directamente con el socket de Wayland/Hyprland y saltarse las dependencias a comandos como `bash`, `pkill` o `sleep`.
  - Proporcionar una latencia sub-milisegundo en las transiciones visuales.
