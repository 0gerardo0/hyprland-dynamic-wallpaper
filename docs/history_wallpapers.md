# Script Histórico: Wallpapers Dinámicos (v1)

Este es el script original que creaste. Tenía una lógica matemática excelente para calcular la fracción del día y sincronizar las imágenes. 

Fue reemplazado porque utilizaba `find` y `sort` en el arranque (lo que consumía mucha CPU y retrasaba la carga) y porque dependía de la comunicación IPC (`hyprctl`) que se rompió en Hyprland/hyprpaper v0.8.3 al cambiar la sintaxis.

```bash
#!/bin/bash

# Configuracion
DIR="$HOME/.local/share/backgrounds/parasite-wallpaper"
DAY_SECONDS=86400

# Verificacion inicial
if [ ! -d "$DIR" ]; then
    echo "Error: Directorio no encontrado."
    exit 1
fi

# Cargar imagenes en array
mapfile -t IMAGES < <(find "$DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort -V)
COUNT=${#IMAGES[@]}

if [ "$COUNT" -eq 0 ]; then
    exit 1
fi

# Calculo de intervalo (entero) una sola vez
# Cuantos segundos dura cada imagen
INTERVAL=$((DAY_SECONDS / COUNT))

# Si hay mas imagenes que segundos, forzar 1s
if [ "$INTERVAL" -eq 0 ]; then INTERVAL=1; fi

CURRENT_WALLPAPER=""

while true; do
    # Obtener segundos actuales del sistema (Epoch)
    NOW=$(printf '%(%s)T' -1)
    
    # Obtener segundos de la medianoche de hoy
    # Truco de bash puro para evitar llamar a 'date' externo constantemente si tienes bash 4.2+
    # Pero para asegurar compatibilidad y precision de zona horaria, usamos date una vez
    MIDNIGHT=$(date -d "today 00:00:00" +%s)
    
    # Segundos transcurridos hoy
    PASSED=$((NOW - MIDNIGHT))
    
    # Calcular indice actual (Matematica nativa de bash)
    INDEX=$((PASSED / INTERVAL))
    
    # Correccion de limites
    if [ "$INDEX" -ge "$COUNT" ]; then INDEX=$((COUNT - 1)); fi
    
    TARGET_IMG="${IMAGES[$INDEX]}"
    
    # Aplicar cambio solo si es necesario
    if [ "$TARGET_IMG" != "$CURRENT_WALLPAPER" ]; then
        hyprctl hyprpaper preload "$TARGET_IMG" > /dev/null 2>&1
        hyprctl hyprpaper wallpaper ",$TARGET_IMG" > /dev/null 2>&1
        
        # Limpieza
        if [ -n "$CURRENT_WALLPAPER" ]; then
             hyprctl hyprpaper unload "$CURRENT_WALLPAPER" > /dev/null 2>&1
        fi
        CURRENT_WALLPAPER="$TARGET_IMG"
    fi
    
    # Calcular tiempo para dormir hasta el siguiente cambio exacto
    # Siguiente segundo clave
    NEXT_SWITCH=$(( (INDEX + 1) * INTERVAL ))
    # Cuanto falta
    SLEEP_TIME=$(( NEXT_SWITCH - PASSED ))
    
    # Proteccion contra dormir 0 o negativo
    if [ "$SLEEP_TIME" -le 0 ]; then SLEEP_TIME=1; fi
    
    sleep "$SLEEP_TIME"
done
```