#!/bin/bash

# ============================================================================
# ZERO-DELAY DYNAMIC WALLPAPER FOR HYPRLAND
# ============================================================================
# Compatible con la nueva sintaxis Hyprlang de hyprpaper v0.8+
# Genera el config al vuelo y carga instantaneamente en RAM (tmpfs).

DIR="${1:-$HOME/.local/share/backgrounds/desert-sands}"
TMP_CONF="/tmp/hyprpaper_dynamic.conf"

# Verificacion inicial
if [ ! -d "$DIR" ]; then
    echo "Error: Directorio no encontrado: $DIR"
    exit 1
fi

# 1. Cargar imagenes (Bash array nativo)
shopt -s nullglob
IMAGES=("$DIR"/*.png "$DIR"/*.jpg "$DIR"/*.jpeg "$DIR"/*.webp)
COUNT=${#IMAGES[@]}

if [ "$COUNT" -eq 0 ]; then
    echo "Error: No se encontraron imagenes en $DIR"
    exit 1
fi

# 2. Variables de tiempo constantes
DAY_SECONDS=86400
INTERVAL=$((DAY_SECONDS / COUNT))
[ "$INTERVAL" -eq 0 ] && INTERVAL=1

# Función para generar config y recargar hyprpaper (BYPASS DE IPC OBSOLETO)
apply_wallpaper() {
    local target_img="$1"
    
    # Obtener nombres de monitores activos para configuracion explicita
    # Esto soluciona el bug de "Monitor has no target" en hyprpaper v0.8.3+
    local monitors
    if command -v jq >/dev/null 2>&1; then
        monitors=$(hyprctl monitors -j 2>/dev/null | jq -r '.[].name' 2>/dev/null)
    fi

    # Escribir el archivo de configuración temporal (NUEVA SINTAXIS v0.8+)
    echo "ipc = off" > "$TMP_CONF"
    echo "splash = false" >> "$TMP_CONF"
    
    if [ -n "$monitors" ]; then
        for mon in $monitors; do
            cat >> "$TMP_CONF" <<EOF
wallpaper {
    monitor = $mon
    path = $target_img
    fit_mode = cover
}
EOF
        done
    else
        cat >> "$TMP_CONF" <<EOF
wallpaper {
    monitor = 
    path = $target_img
    fit_mode = cover
}
EOF
    fi

    # Matar la instancia vieja e iniciar la nueva con el archivo temporal
    pkill hyprpaper
    hyprpaper -c "$TMP_CONF" >/dev/null 2>&1 &
    disown
}

# 3. Calcular imagen inicial de INMEDIATO (Milisegundo 0)
NOW=$(printf '%(%s)T' -1)
MIDNIGHT=$(date -d "today 00:00:00" +%s)
PASSED=$((NOW - MIDNIGHT))
INDEX=$((PASSED / INTERVAL))

# Correccion de limites
[ "$INDEX" -ge "$COUNT" ] && INDEX=$((COUNT - 1))

CURRENT_IMG="${IMAGES[$INDEX]}"

# 4. APLICAR IMAGEN INICIAL AL INSTANTE
apply_wallpaper "$CURRENT_IMG"

# 5. LOOP DE FONDO LIGERO
while true; do
    NOW=$(printf '%(%s)T' -1)
    PASSED=$((NOW - MIDNIGHT))
    
    # Si pasamos a otro día, actualizar la medianoche
    if [ "$PASSED" -ge "$DAY_SECONDS" ] || [ "$PASSED" -lt 0 ]; then
        MIDNIGHT=$(date -d "today 00:00:00" +%s)
        PASSED=$((NOW - MIDNIGHT))
    fi

    INDEX=$((PASSED / INTERVAL))
    [ "$INDEX" -ge "$COUNT" ] && INDEX=$((COUNT - 1))
    
    TARGET_IMG="${IMAGES[$INDEX]}"
    
    # Solo aplicar si cambió
    if [[ "$TARGET_IMG" != "$CURRENT_IMG" ]]; then
        CURRENT_IMG="$TARGET_IMG"
        apply_wallpaper "$CURRENT_IMG"
    fi
    
    # Calcular segundos exactos hasta el próximo cambio para que el script duerma
    NEXT_SWITCH=$(( (INDEX + 1) * INTERVAL ))
    SLEEP_TIME=$(( NEXT_SWITCH - PASSED ))
    
    [ "$SLEEP_TIME" -le 0 ] && SLEEP_TIME=1
    
    sleep "$SLEEP_TIME"
done
