#!/bin/bash

# Configuration
BANNER_DIR="$HOME/banners"
SLIDESHOW_DELAY=5  # Default delay in seconds
ALLOWED_WIDTH=78   # Appropriate width for terminal display

# Create banners directory if it doesn't exist
mkdir -p "$BANNER_DIR"

# Function to create a new banner
create_banner() {
    clear
    echo "Create a new banner"
    echo "------------------"
    
    read -p "Enter banner name (no spaces or special chars): " banner_name
    if [[ -z "$banner_name" ]]; then
        echo "Error: Banner name cannot be empty."
        return 1
    fi
    
    banner_file="$BANNER_DIR/$banner_name.txt"
    
    if [[ -f "$banner_file" ]]; then
        echo "Error: Banner '$banner_name' already exists."
        return 1
    fi
    
    echo "Enter your banner content below (Press Ctrl+D when finished):"
    echo ""
    
    # Create a temporary file for editing
    temp_file=$(mktemp)
    nano "$temp_file"
    
    # Format the banner to the allowed width
    fold -s -w $ALLOWED_WIDTH "$temp_file" > "$banner_file"
    
    rm "$temp_file"
    
    echo "Banner '$banner_name' created successfully!"
    sleep 2
}

# Function to edit an existing banner
edit_banner() {
    clear
    echo "Edit an existing banner"
    echo "-----------------------"
    
    if [[ ! -d "$BANNER_DIR" ]] || [[ -z "$(ls -A "$BANNER_DIR")" ]]; then
        echo "No banners available to edit."
        sleep 2
        return
    fi
    
    echo "Available banners:"
    ls -1 "$BANNER_DIR" | sed 's/\.txt$//'
    echo ""
    
    read -p "Enter banner name to edit: " banner_name
    banner_file="$BANNER_DIR/$banner_name.txt"
    
    if [[ ! -f "$banner_file" ]]; then
        echo "Error: Banner '$banner_name' does not exist."
        sleep 2
        return 1
    fi
    
    # Create a temporary copy for editing
    temp_file=$(mktemp)
    cp "$banner_file" "$temp_file"
    
    nano "$temp_file"
    
    # Format the edited banner
    fold -s -w $ALLOWED_WIDTH "$temp_file" > "$banner_file"
    
    rm "$temp_file"
    
    echo "Banner '$banner_name' updated successfully!"
    sleep 2
}

# Function to display a single banner
display_banner() {
    clear
    if [[ ! -f "$1" ]]; then
        echo "Error: Banner file not found."
        return 1
    fi
    
    # Center the banner in the terminal
    banner_content=$(cat "$1")
    term_width=$(tput cols)
    term_height=$(tput lines)
    
    # Calculate padding
    banner_height=$(echo "$banner_content" | wc -l)
    vertical_padding=$(( (term_height - banner_height) / 2 ))
    
    # Clear screen and add vertical padding
    clear
    for ((i=0; i<vertical_padding; i++)); do
        echo ""
    done
    
    # Display each line centered
    while IFS= read -r line; do
        line_length=${#line}
        horizontal_padding=$(( (term_width - line_length) / 2 ))
        printf "%*s%s\n" $horizontal_padding '' "$line"
    done <<< "$banner_content"
}

# Function to run the slideshow
run_slideshow() {
    clear
    echo "Running banner slideshow"
    echo "Press Ctrl+C to stop..."
    
    if [[ ! -d "$BANNER_DIR" ]] || [[ -z "$(ls -A "$BANNER_DIR")" ]]; then
        echo "No banners available for slideshow."
        sleep 2
        return
    fi
    
    # Get all banner files
    banner_files=("$BANNER_DIR"/*.txt)
    
    # Check delay setting
    delay=$SLIDESHOW_DELAY
    read -p "Enter delay between banners in seconds (default: $delay): " user_delay
    if [[ $user_delay =~ ^[0-9]+$ ]] && [[ $user_delay -gt 0 ]]; then
        delay=$user_delay
    fi
    
    # Run slideshow in a loop
    while true; do
        for banner_file in "${banner_files[@]}"; do
            display_banner "$banner_file"
            sleep "$delay"
        done
    done
}

# Function to configure slideshow settings
configure_settings() {
    clear
    echo "Configure Slideshow Settings"
    echo "---------------------------"
    
    echo "Current settings:"
    echo "1. Slideshow delay: $SLIDESHOW_DELAY seconds"
    echo "2. Banner width: $ALLOWED_WIDTH characters"
    echo ""
    
    read -p "Select setting to change (1-2) or any other key to cancel: " choice
    
    case $choice in
        1)
            read -p "Enter new slideshow delay in seconds: " new_delay
            if [[ $new_delay =~ ^[0-9]+$ ]] && [[ $new_delay -gt 0 ]]; then
                SLIDESHOW_DELAY=$new_delay
                echo "Slideshow delay updated to $new_delay seconds."
            else
                echo "Invalid delay value. Must be a positive integer."
            fi
            ;;
        2)
            read -p "Enter new banner width (40-120): " new_width
            if [[ $new_width =~ ^[0-9]+$ ]] && [[ $new_width -ge 40 ]] && [[ $new_width -le 120 ]]; then
                ALLOWED_WIDTH=$new_width
                echo "Banner width updated to $new_width characters."
            else
                echo "Invalid width. Must be between 40 and 120."
            fi
            ;;
        *)
            echo "Settings not changed."
            ;;
    esac
    
    sleep 2
}

# Main menu
while true; do
    clear
    echo "Raspberry Pi Banner Slideshow"
    echo "----------------------------"
    echo "1. Create a new banner"
    echo "2. Edit an existing banner"
    echo "3. Run banner slideshow"
    echo "4. Configure settings"
    echo "5. Exit"
    echo ""
    
    read -p "Enter your choice (1-5): " choice
    
    case $choice in
        1) create_banner ;;
        2) edit_banner ;;
        3) run_slideshow ;;
        4) configure_settings ;;
        5) 
            clear
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            sleep 2
            ;;
    esac
done
