#!/bin/bash

# Configurações globais
VERSION="3.1"
CONFIG_DIR="$HOME/.slideshow"
IMAGE_DIR="$CONFIG_DIR/images"
CONFIG_FILE="$CONFIG_DIR/settings.conf"
LOG_FILE="$CONFIG_DIR/slideshow.log"
PID_FILE="$CONFIG_DIR/slideshow.pid"

# Cores para terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Inicialização
init() {
    check_dependencies
    create_directories
    load_config
    cleanup_old_process
}

check_dependencies() {
    local missing=()
    local required=("feh" "convert" "ffmpeg" "inotifywait")
    
    for cmd in "${required[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}Instalando dependências...${NC}"
        sudo apt update && sudo apt install -y "${missing[@]}" imagemagick inotify-tools
    fi
}

create_directories() {
    mkdir -p "$CONFIG_DIR" "$IMAGE_DIR"
    [[ ! -f "$CONFIG_FILE" ]] && touch "$CONFIG_FILE"
    [[ ! -f "$LOG_FILE" ]] && touch "$LOG_FILE"
}

load_config() {
    declare -gA config
    
    # Configurações padrão
    config=(
        [delay]="5"
        [random]="false"
        [fullscreen]="true"
        [transition]="fade"
        [transition_duration]="1"
        [overlay_text]=""
        [overlay_color]="white"
        [overlay_bg]="transparent"
        [overlay_size]="36"
        [overlay_position]="south"
    )

    # Carrega configurações do arquivo
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS='=' read -r key value; do
            [[ -n "$key" ]] && config["$key"]="$value"
        done < "$CONFIG_FILE"
    fi
}

save_config() {
    > "$CONFIG_FILE"
    for key in "${!config[@]}"; do
        echo "$key=${config[$key]}" >> "$CONFIG_FILE"
    done
}

cleanup_old_process() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null; then
            kill "$pid" 2>/dev/null
        fi
        rm -f "$PID_FILE"
    fi
}

# Funções do menu principal
add_content() {
    while true; do
        clear
        echo -e "${GREEN}=== Adicionar Conteúdo ===${NC}"
        echo
        echo "1) Adicionar imagens"
        echo "2) Criar banner de texto"
        echo "3) Voltar"
        echo
        read -p "▶ Escolha [1-3]: " choice

        case $choice in
            1) add_images ;;
            2) create_text_banner ;;
            3) return ;;
            *) echo -e "${RED}Opção inválida!${NC}"; sleep 1 ;;
        esac
    done
}

add_images() {
    echo -e "\n${YELLOW}Arraste imagens para a pasta $IMAGE_DIR ou digite o caminho:${NC}"
    read -p "▶ Caminho (deixe em branco para cancelar): " path
    
    if [[ -n "$path" ]]; then
        if [[ -d "$path" ]]; then
            cp -v "$path"/*.{jpg,jpeg,png} "$IMAGE_DIR" 2>/dev/null | tee -a "$LOG_FILE"
            echo -e "${GREEN}Imagens adicionadas com sucesso!${NC}"
        elif [[ -f "$path" ]]; then
            cp -v "$path" "$IMAGE_DIR" | tee -a "$LOG_FILE"
            echo -e "${GREEN}Imagem adicionada com sucesso!${NC}"
        else
            echo -e "${RED}Caminho inválido!${NC}"
        fi
        sleep 2
    fi
}

create_text_banner() {
    clear
    echo -e "${GREEN}=== Criar Banner de Texto ===${NC}"
    
    read -p "▶ Texto do banner: " text
    read -p "▶ Cor do texto [${config[overlay_color]}]: " color
    read -p "▶ Cor de fundo [${config[overlay_bg]}]: " bg
    read -p "▶ Tamanho da fonte [${config[overlay_size]}]: " size
    read -p "▶ Nome do arquivo (sem extensão): " filename
    
    color=${color:-${config[overlay_color]}}
    bg=${bg:-${config[overlay_bg]}}
    size=${size:-${config[overlay_size]}}
    
    echo -e "\n${YELLOW}Criando banner...${NC}"
    convert -size 800x600 -background "$bg" -fill "$color" \
            -pointsize "$size" -gravity center label:"$text" \
            "$IMAGE_DIR/$filename.png" 2>> "$LOG_FILE"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Banner criado: $filename.png${NC}"
    else
        echo -e "${RED}Erro ao criar banner! Verifique o log.${NC}"
    fi
    sleep 2
}

configure_slideshow() {
    while true; do
        clear
        echo -e "${GREEN}=== Configurar Slideshow ===${NC}"
        echo
        echo "1) Tempo entre slides (atual: ${config[delay]}s)"
        echo "2) Ordem aleatória (atual: ${config[random]})"
        echo "3) Tela cheia (atual: ${config[fullscreen]})"
        echo "4) Efeitos de transição (atual: ${config[transition]})"
        echo "5) Configurar overlay"
        echo "6) Salvar e voltar"
        echo
        read -p "▶ Escolha [1-6]: " choice

        case $choice in
            1) 
                read -p "Novo tempo entre slides (segundos): " delay
                [[ -n "$delay" ]] && config["delay"]="$delay"
                ;;
            2) 
                config["random"]=$([[ "${config[random]}" == "true" ]] && echo "false" || echo "true")
                ;;
            3) 
                config["fullscreen"]=$([[ "${config[fullscreen]}" == "true" ]] && echo "false" || echo "true")
                ;;
            4) 
                echo -e "\nEfeitos disponíveis: fade, slide, zoom, none"
                read -p "Escolha o efeito: " effect
                [[ -n "$effect" ]] && config["transition"]="$effect"
                ;;
            5) 
                configure_overlay
                ;;
            6) 
                save_config
                return
                ;;
            *) 
                echo -e "${RED}Opção inválida!${NC}"
                sleep 1
                ;;
        esac
    done
}

configure_overlay() {
    clear
    echo -e "${GREEN}=== Configurar Overlay ===${NC}"
    
    read -p "▶ Texto do overlay [${config[overlay_text]}]: " text
    read -p "▶ Cor do texto [${config[overlay_color]}]: " color
    read -p "▶ Cor de fundo [${config[overlay_bg]}]: " bg
    read -p "▶ Tamanho da fonte [${config[overlay_size]}]: " size
    read -p "▶ Posição (north/south/east/west/center) [${config[overlay_position]}]: " pos
    
    [[ -n "$text" ]] && config["overlay_text"]="$text"
    [[ -n "$color" ]] && config["overlay_color"]="$color"
    [[ -n "$bg" ]] && config["overlay_bg"]="$bg"
    [[ -n "$size" ]] && config["overlay_size"]="$size"
    [[ -n "$pos" ]] && config["overlay_position"]="$pos"
}

preview_slideshow() {
    echo -e "\n${YELLOW}Preparando pré-visualização...${NC}"
    
    local images=("$IMAGE_DIR"/*.{jpg,jpeg,png} 2>/dev/null)
    if [[ ${#images[@]} -eq 0 ]]; then
        echo -e "${RED}Nenhuma imagem encontrada!${NC}"
        sleep 2
        return
    fi
    
    local feh_options="--auto-zoom --hide-pointer"
    [[ "${config[fullscreen]}" == "true" ]] && feh_options+=" --fullscreen"
    
    if [[ "${config[random]}" == "true" ]]; then
        shuf -e "${images[@]}" | feh $feh_options --cycle-once --slideshow-delay "${config[delay]}"
    else
        feh $feh_options --cycle-once --slideshow-delay "${config[delay]}" "${images[@]}"
    fi
}

start_slideshow() {
    echo -e "\n${YELLOW}Iniciando slideshow... Pressione Ctrl+C para parar${NC}"
    
    local feh_options="--auto-zoom --hide-pointer"
    [[ "${config[fullscreen]}" == "true" ]] && feh_options+=" --fullscreen"
    
    # Gera arquivo de playlist temporário
    local playlist="$CONFIG_DIR/playlist.txt"
    if [[ "${config[random]}" == "true" ]]; then
        shuf -e "$IMAGE_DIR"/*.{jpg,jpeg,png} 2>/dev/null > "$playlist"
    else
        ls -1 "$IMAGE_DIR"/*.{jpg,jpeg,png} 2>/dev/null > "$playlist"
    fi
    
    # Inicia em background e grava o PID
    feh $feh_options --slideshow-delay "${config[delay]}" --filelist "$playlist" &
    echo $! > "$PID_FILE"
    
    # Monitora alterações na pasta de imagens
    inotifywait -m -e create -e delete -e moved_to -e moved_from "$IMAGE_DIR" |
    while read -r directory action file; do
        echo -e "${BLUE}Atualizando playlist...${NC}"
        if [[ "${config[random]}" == "true" ]]; then
            shuf -e "$IMAGE_DIR"/*.{jpg,jpeg,png} 2>/dev/null > "$playlist"
        else
            ls -1 "$IMAGE_DIR"/*.{jpg,jpeg,png} 2>/dev/null > "$playlist"
        fi
    done
}

manage_content() {
    while true; do
        clear
        echo -e "${GREEN}=== Gerenciar Conteúdo ===${NC}"
        echo
        
        local images=("$IMAGE_DIR"/*)
        if [[ ${#images[@]} -eq 0 ]]; then
            echo -e "${YELLOW}Nenhum conteúdo encontrado!${NC}"
        else
            echo "Conteúdo disponível:"
            ls -1 "$IMAGE_DIR" | nl
        fi
        
        echo
        echo "1) Remover item"
        echo "2) Limpar tudo"
        echo "3) Voltar"
        echo
        read -p "▶ Escolha [1-3]: " choice

        case $choice in
            1)
                if [[ ${#images[@]} -gt 0 ]]; then
                    read -p "Número do item a remover: " num
                    local to_remove=$(ls -1 "$IMAGE_DIR" | sed -n "${num}p")
                    if [[ -n "$to_remove" ]]; then
                        rm -v "$IMAGE_DIR/$to_remove" | tee -a "$LOG_FILE"
                        echo -e "${GREEN}Item removido!${NC}"
                    else
                        echo -e "${RED}Número inválido!${NC}"
                    fi
                    sleep 1
                fi
                ;;
            2)
                read -p "Tem certeza que deseja remover TODOS os itens? (s/n) " confirm
                if [[ "$confirm" =~ [sS] ]]; then
                    rm -v "$IMAGE_DIR"/* | tee -a "$LOG_FILE"
                    echo -e "${GREEN}Conteúdo removido!${NC}"
                    sleep 1
                fi
                ;;
            3)
                return
                ;;
            *)
                echo -e "${RED}Opção inválida!${NC}"
                sleep 1
                ;;
        esac
    done
}

advanced_settings() {
    while true; do
        clear
        echo -e "${GREEN}=== Configurações Avançadas ===${NC}"
        echo
        echo "1) Ver log"
        echo "2) Limpar log"
        echo "3) Redefinir configurações"
        echo "4) Voltar"
        echo
        read -p "▶ Escolha [1-4]: " choice

        case $choice in
            1)
                less "$LOG_FILE"
                ;;
            2)
                > "$LOG_FILE"
                echo -e "${GREEN}Log limpo!${NC}"
                sleep 1
                ;;
            3)
                read -p "Tem certeza que deseja redefinir TODAS as configurações? (s/n) " confirm
                if [[ "$confirm" =~ [sS] ]]; then
                    rm -f "$CONFIG_FILE"
                    load_config
                    echo -e "${GREEN}Configurações redefinidas!${NC}"
                    sleep 1
                fi
                ;;
            4)
                return
                ;;
            *)
                echo -e "${RED}Opção inválida!${NC}"
                sleep 1
                ;;
        esac
    done
}

# Ponto de entrada
init
while true; do
    clear
    echo -e "${GREEN}====================================${NC}"
    echo -e "${GREEN}  🖼️  Slideshow Profissional v$VERSION  ${NC}"
    echo -e "${GREEN}====================================${NC}"
    echo
    echo -e "${BLUE}1) ${NC}Adicionar conteúdo"
    echo -e "${BLUE}2) ${NC}Configurar slideshow"
    echo -e "${BLUE}3) ${NC}Pré-visualizar"
    echo -e "${BLUE}4) ${NC}Iniciar slideshow"
    echo -e "${BLUE}5) ${NC}Gerenciar conteúdo"
    echo -e "${BLUE}6) ${NC}Configurações avançadas"
    echo -e "${BLUE}7) ${NC}Sair"
    echo
    read -p "▶ Escolha uma opção [1-7]: " choice

    case $choice in
        1) add_content ;;
        2) configure_slideshow ;;
        3) preview_slideshow ;;
        4) start_slideshow ;;
        5) manage_content ;;
        6) advanced_settings ;;
        7) 
            cleanup_old_process
            exit 0
            ;;
        *) 
            echo -e "${RED}Opção inválida!${NC}"
            sleep 1
            ;;
    esac
done
