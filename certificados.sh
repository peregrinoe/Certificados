#!/bin/bash

# SSL Certificate Checker - Minimal & Clean
# Author: Zoso

# CONFIG
timeout="5"
warning_days="40"
alert_days="20"
html_file="certs_report.html"
current_date=$(date +%s)

# COLORS for terminal
ok_color="\e[38;5;40m"
warning_color="\e[38;5;220m"
alert_color="\e[38;5;208m"
expired_color="\e[38;5;196m"
unknown_color="\e[38;5;246m"
end_of_color="\033[0m"

# FUNCTIONS

print_help() {
    cat <<EOF

Uso: $0 -f archivo -o [html|terminal]

Opciones:
  -f <archivo>      Archivo con lista de sitios (formato dominio:puerto)
  -o <salida>       Modo de salida: html o terminal
  -h                Mostrar ayuda

Ejemplo:
  $0 -f sitios.txt -o terminal

EOF
}

check_cert() {
    local site="$1"
    local host=$(echo "$site" | cut -d ":" -f1)
    local port=$(echo "$site" | cut -d ":" -f2)

    timeout $timeout bash -c "cat < /dev/null > /dev/tcp/$host/$port"
    if [ $? -eq 0 ]; then
        local end_date=$(echo | openssl s_client -servername "$host" -connect "$site" 2>/dev/null |
            openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
        local end_timestamp=$(date -d "$end_date" +%s 2>/dev/null)
        local days_left=$(( (end_timestamp - current_date) / 86400 ))

        echo "$host|$end_date|$days_left"
    else
        echo "$host|n/a|n/a"
    fi
}

generate_html() {
    echo "<html><head><title>SSL Certs Report</title></head><body>" > $html_file
    echo "<h2 style='text-align:center;'>SSL Certificate Expiration Report</h2>" >> $html_file
    echo "<table border='1' style='width:80%;margin:auto;text-align:left;'>" >> $html_file
    echo "<tr><th>Site</th><th>Expiration Date</th><th>Days Left</th><th>Status</th></tr>" >> $html_file

    while IFS= read -r site; do
        result=$(check_cert "$site")
        IFS="|" read host cert_date days_left <<< "$result"

        if [[ "$days_left" == "n/a" ]]; then
            color="#999493"
            status="Unknown"
        elif (( days_left > warning_days )); then
            color="#33FF4F"
            status="Ok"
        elif (( days_left > alert_days )); then
            color="#FFE032"
            status="Warning"
        elif (( days_left > 0 )); then
            color="#FF8F32"
            status="Alert"
        else
            color="#EF3434"
            status="Expired"
        fi

        echo "<tr style='background-color:$color;'><td>$host</td><td>$cert_date</td><td>$days_left</td><td>$status</td></tr>" >> $html_file
    done < "$sites_file"

    echo "</table></body></html>" >> $html_file
    echo "✅ Reporte HTML generado: $html_file"
}

generate_terminal_output() {
    printf "\n| %-25s | %-25s | %-10s | %-8s %s\n" "SITE" "EXPIRATION DATE" "DAYS LEFT" "STATUS"

    while IFS= read -r site; do
        result=$(check_cert "$site")
        IFS="|" read host cert_date days_left <<< "$result"

        if [[ "$days_left" == "n/a" ]]; then
            color="$unknown_color"
            status="Unknown"
        elif (( days_left > warning_days )); then
            color="$ok_color"
            status="Ok"
        elif (( days_left > alert_days )); then
            color="$warning_color"
            status="Warning"
        elif (( days_left > 0 )); then
            color="$alert_color"
            status="Alert"
        else
            color="$expired_color"
            status="Expired"
        fi

        printf "${color}| %-25s | %-25s | %-10s | %-8s %s\n${end_of_color}" "$host" "$cert_date" "$days_left" "$status"
    done < "$sites_file"
}

# MAIN

while getopts ":f:o:h" opt; do
    case $opt in
        f)
            sites_file="$OPTARG"
            ;;
        o)
            output="$OPTARG"
            ;;
        h | *)
            print_help
            exit 0
            ;;
    esac
done

if [[ -z "$sites_file" || -z "$output" ]]; then
    print_help
    exit 1
fi

if [[ ! -f "$sites_file" ]]; then
    echo "❌ Archivo no encontrado: $sites_file"
    exit 1
fi

case $output in
    html)
        generate_html
        ;;
    terminal)
        generate_terminal_output
        ;;
    *)
        echo "❌ Salida no válida. Usa 'html' o 'terminal'."
        exit 1
        ;;
esac
