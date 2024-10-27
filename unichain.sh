download_node() {
  echo 'Начинаю установку...'

  sudo apt update -y && sudo apt upgrade -y
  sudo apt-get install make build-essential unzip lz4 gcc git jq -y
  
  sudo apt install docker.io -y

  sudo systemctl start docker
  sudo systemctl enable docker

  sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose

  git clone https://github.com/Uniswap/unichain-node
  cd unichain-node || { echo -e "Не получилось зайти в директорию"; return; }
  
  if [[ -f .env.sepolia ]]; then
    sed -i 's|^OP_NODE_L1_ETH_RPC=.*$|OP_NODE_L1_ETH_RPC=https://ethereum-sepolia-rpc.publicnode.com|' .env.sepolia
    sed -i 's|^OP_NODE_L1_BEACON=.*$|OP_NODE_L1_BEACON=https://ethereum-sepolia-beacon-api.publicnode.com|' .env.sepolia
  else
    echo -e "Sepolia ENV не было найдено"
    return
  fi

  sudo docker-compose up -d
}

restart_node() {
  HOMEDIR="$HOME"
  sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" down
  sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" up -d

  echo 'Unichain был перезагружен'
}

check_node() {
  response=$(curl -s -d '{"id":1,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
    -H "Content-Type: application/json" http://localhost:8545)

  echo -e "${BLUE}RESPONSE:${RESET} $response"
}

check_logs_op_node() {
  sudo docker logs unichain-node-op-node-1
}

check_logs_unichain() {
  sudo docker logs unichain-node-execution-client-1
}

stop_node() {
  HOMEDIR="$HOME"
  sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" down
}

exit_from_script() {
  exit 0
}

while true; do
    echo -e "\n\nМеню:"
    echo "1. Установить ноду"
    echo "2. Перезагрузить ноду"
    echo "3. Проверить ноду"
    echo "4. Посмотреть логи Unichain (OP)"
    echo "5. Посмотреть логи Unichain"
    echo "6. Остановить ноду"
    echo -e "7. Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        restart_node
        ;;
      3)
        check_node
        ;;
      4)
        check_logs_op_node
        ;;
      5)
        check_logs_unichain
        ;;
      6)
        stop_node
        ;;
      7)
        exit_from_script
        ;;
      *)
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done