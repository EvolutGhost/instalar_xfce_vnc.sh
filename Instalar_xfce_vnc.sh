#!/usr/bin/env bash
# instalar_xfce_vnc.sh
# Instalação mínima XFCE + TigerVNC para Kali (Termux / proot) sem usar SD e sem root do Android.
# Use por sua conta — o script pergunta antes de instalar se não houver espaço suficiente.

set -euo pipefail

REQUIRED_KB=1500000   # ~1.5 GB em KB — ajuste se quiser aceitar menos
GEOMETRY="1024x600"
DEPTH="16"

echo "=== Checando espaço disponível no filesystem atual ==="
AVAILABLE_KB=$(df --output=avail -k . | tail -n1 | tr -d '[:space:]')
echo "Espaço disponível: $((AVAILABLE_KB/1024)) MB"

if [ "$AVAILABLE_KB" -lt "$REQUIRED_KB" ]; then
  echo
  echo "ATENÇÃO: Você tem menos de ~1.5GB livre. A instalação pode falhar por falta de espaço."
  echo "Recomendo limpar caches ou remover pacotes grandes antes de continuar."
  read -p "Deseja continuar mesmo assim? (s/N): " resp
  resp=${resp,,}
  if [ "$resp" != "s" ] && [ "$resp" != "sim" ]; then
    echo "Abortando. Libere espaço e execute novamente."
    exit 1
  fi
fi

echo
echo "=== Atualizando repositórios e limpando caches antigos ==="
sudo apt update
sudo apt -y upgrade
sudo apt clean
sudo apt -y autoremove

echo
echo "=== Instalando pacotes mínimos do XFCE + TigerVNC (sem recomendados) ==="
sudo apt install -y --no-install-recommends \
  xfce4-session xfce4-panel xfce4-terminal xfwm4 xfdesktop \
  dbus-x11 x11-xserver-utils \
  tigervnc-standalone-server

echo
echo "=== Criando arquivo de inicialização do VNC (~/.vnc/xstartup) ==="
mkdir -p ~/.vnc
cat > ~/.vnc/xstartup <<'EOF'
#!/bin/sh
unset DBUS_SESSION_BUS_ADDRESS
export XDG_RUNTIME_DIR=/tmp/runtime-$USER
mkdir -p "$XDG_RUNTIME_DIR"
# Ajuste: usamos dbus-launch para garantir sessão dbus no proot
dbus-launch --exit-with-session startxfce4 &
EOF
chmod +x ~/.vnc/xstartup
echo "Arquivo ~/.vnc/xstartup criado e marcado como executável."

echo
echo "=== Defina a senha do VNC (será solicitado) ==="
echo "(O comando vncpasswd pedirá a senha; não coloque senhas muito longas)"
vncpasswd

echo
echo "=== Iniciando o servidor VNC na tela :1 ==="
echo "Resolução: $GEOMETRY ; profundidade de cor: $DEPTH"
vncserver :1 -geometry $GEOMETRY -depth $DEPTH

echo
echo "=== Pronto! Instruções de conexão ==="
echo "1) No próprio celular, use um app VNC (bVNC, VNC Viewer, RealVNC)."
echo "   Conecte para: 127.0.0.1:5901  (ou localhost:5901)"
echo "2) Caso conecte de outro dispositivo na mesma rede, use o IP do celular:5901"
echo
echo "Comandos úteis:"
echo " - Parar VNC: vncserver -kill :1"
echo " - Ver logs: cat ~/.vnc/*:1.log  ou ls -l ~/.vnc"
echo " - Se precisar reiniciar com outra resolução: vncserver -kill :1 && vncserver :1 -geometry 800x480 -depth 8"
echo
echo "Dicas: use resoluções menores (800x480) e depth 8/16 para reduzir uso de RAM e disco."
echo "Se algo falhar, cole aqui o log de ~/.vnc/*.log que eu te ajudo."

exit 0
