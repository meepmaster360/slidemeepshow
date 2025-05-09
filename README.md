# slidemeepshow

Para iniciar o slideshow remotamente via SSH, você pode usar os seguintes métodos:

Método 1: Execução Direta (Melhor para testes rápidos)
bash
ssh pi@ip_do_seu_raspberry './slideshow.sh --start'

Método 2: Modo Kiosk com Redirecionamento X11 (Se precisar de GUI)
bash
ssh -X pi@ip_do_seu_raspberry 'export DISPLAY=:0 && ./slideshow.sh --fullscreen'
Método 3: Sessão Persistente (Para execução contínua)
bash
ssh -t pi@ip_do_seu_raspberry 'tmux new-session -d -s slideshow "./slideshow.sh --start"'
Método 4: Com Controle Remoto Avançado
bash
ssh pi@ip_do_seu_raspberry << 'EOF'
  cd ~/slideshow
  nohup ./slideshow.sh --start > slideshow.log 2>&1 &
  disown
EOF
Configuração Recomendada:
Configure login sem senha (opcional):

bash
ssh-copy-id pi@ip_do_seu_raspberry
Adicione ao cron para iniciar na reinicialização:

bash
ssh pi@ip_do_seu_raspberry 'crontab -l | { cat; echo "@reboot /home/pi/slideshow.sh --start"; } | crontab -'
Verifique se está rodando:

bash
ssh pi@ip_do_seu_raspberry 'pgrep -f slideshow.sh'
