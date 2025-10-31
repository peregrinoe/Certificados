# SSL Certificate Checker 🔒

Script en Bash para verificar la fecha de expiración de certificados SSL/TLS de una lista de sitios web.

## 📌 Características

- Verifica dominios con formato `dominio:puerto`
- Soporte para salida en:
  - 🖥 Terminal con colores
  - 🌐 HTML (visualizable en navegador)
- Solo depende de:
  - `bash`
  - `openssl`
  - `timeout` (comando estándar en Linux)

## 🚀 Uso

### 1. Preparar lista de sitios

Crea un archivo `sitios.txt` con el siguiente formato:

google.com:443

### 2. Ejecutar el script

```bash
chmod +x cert_check.sh
./certificados.sh -f sitios.txt -o terminal    # Modo terminal
./certificados.sh -f sitios.txt -o html        # Modo HTML

