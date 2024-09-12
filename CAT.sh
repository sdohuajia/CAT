#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/CAT.sh"

# 检查是否以 root 用户运行
if [ "$(id -u)" -ne "0" ]; then
    echo "此脚本需要以 root 用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到 root 用户，然后再次运行此脚本。"
    exit 1
fi

# 安装 Docker
install_docker() {
    echo "开始安装 Docker..."
    apt-get update -q && apt-get upgrade -yq
    apt-get install -yq apt-transport-https ca-certificates curl software-properties-common

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    
    apt-get update -q
    apt-get install -yq docker-ce docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker

    echo "Docker 已成功安装并启动。"
}

# 安装 Node.js
install_node() {
    echo "开始安装 Node.js..."
    apt-get update -q
    curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
    apt-get install -yq nodejs

    echo "Node.js 已成功安装。"
}

# 安装 Docker Compose
install_docker_compose() {
    local version="2.20.2"
    echo "开始安装 Docker Compose (版本 $version)..."
    curl -L "https://github.com/docker/compose/releases/download/v$version/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    echo "Docker Compose 已成功安装。"
}

# 查看同步日志
check_node_log() {
    echo "查看同步日志..."
    docker logs -f --tail 100 tracker
    
    echo "按任意键返回主菜单..."
    read -n 1 -s
}

# 导出钱包信息
export_wallet_info() {
    echo "导出钱包信息..."
    wallet_file="/root/cat-token-box/packages/cli/wallet.json"

    if [ ! -f "$wallet_file" ]; then
        echo "钱包文件 $wallet_file 不存在。"
        exit 1
    fi

    echo "钱包信息:"
    echo "Name: $(grep -oP '"name": *"\K[^"]+' "$wallet_file")"
    echo "Mnemonic: $(grep -oP '"mnemonic": *"\K[^"]+' "$wallet_file")"

    echo "按任意键返回主菜单..."
    read -n 1 -s
}

# 执行 mint
execute_mint() {
    echo "执行 mint 操作..."
    cd /root/cat-token-box/packages/cli
    chmod +x script.sh
    ./script.sh

    echo "按任意键返回主菜单..."
    read -n 1 -s
}

# 显示钱包地址
display_address() {
    echo "显示钱包地址..."
    cd /root/cat-token-box/packages/cli || { echo "进入目录失败"; exit 1; }
    yarn cli wallet address

    echo "按任意键返回主菜单..."
    read -n 1 -s
}

# 创建钱包
create_wallet() {
    echo "创建钱包..."
    cd /root/cat-token-box/packages/cli || { echo "进入目录失败"; exit 1; }
    yarn cli wallet create

    echo "按任意键返回主菜单..."
    read -n 1 -s
}

# 安装节点
install_dependencies() {
    echo "开始安装节点..."
    
    if ! command -v docker &> /dev/null; then
        install_docker
    else
        echo "Docker 已安装，跳过安装步骤。"
    fi

    if ! command -v node &> /dev/null; then
        install_node
    else
        echo "Node.js 已安装，跳过安装步骤。"
    fi

    if ! command -v docker-compose &> /dev/null; then
        install_docker_compose
    else
        echo "Docker Compose 已安装，跳过安装步骤。"
    fi

    echo "Docker 状态:"
    systemctl status docker --no-pager

    echo "Docker Compose 版本:"
    docker-compose --version

    echo "克隆 GitHub 仓库..."
    git clone https://github.com/CATProtocol/cat-token-box.git || { echo "克隆失败"; exit 1; }
    cd cat-token-box/ || { echo "进入目录失败"; exit 1; }

    echo "安装依赖并构建项目..."
    yarn install && yarn build

    cd packages/tracker/ || { echo "进入 tracker 目录失败"; exit 1; }
    echo "设置权限..."
    mkdir -p docker/data docker/pgdata
    chmod 777 docker/data
    chmod 777 docker/pgdata

    echo "启动 Docker Compose..."
    docker-compose up -d

    cd ../..
    echo "构建 Docker 镜像..."
    docker build -t tracker:latest .

    echo "运行 Docker 容器..."
    docker run -d \
        --name tracker \
        --add-host="host.docker.internal:host-gateway" \
        -e DATABASE_HOST="host.docker.internal" \
        -e RPC_HOST="host.docker.internal" \
        -p 3000:3000 \
        tracker:latest

    cd packages/cli || { echo "进入 CLI 目录失败"; exit 1; }
    echo "已进入目录 /root/cat-token-box/packages/cli"

    echo "创建或修改 config.json 文件..."
    cat <<EOF > config.json
{
  "network": "fractal-mainnet",
  "tracker": "http://127.0.0.1:3000",
  "dataDir": ".",
  "maxFeeRate": 30,
  "rpc": {
      "url": "http://127.0.0.1:8332",
      "username": "bitcoin",
      "password": "opcatAwesome"
  }
}
EOF

    echo "创建并写入 script.sh 文件..."
    cat <<EOF > script.sh
#!/bin/bash

command="yarn cli mint -i 45ee725c2c5993b3e4d308842d87e973bf1951f5f7a804b21e4dd964ecd12d6b_0 5"

while true; do
    \$command

    if [ \$? -ne 0 ]; then
        echo "命令执行失败，退出循环"
        exit 1
    fi

    sleep 1
done
EOF

    chmod +x script.sh

    echo "按任意键返回主菜单..."
    read -n 1 -s
}

# 主菜单函数
main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1) 安装节点"
        echo "2) 创建钱包"
        echo "3) 导出钱包"
        echo "4) 执行 mint"
        echo "5) 查看同步日志"
        echo "6) 显示地址"
        echo "7) 退出"

        read -p "请输入选项: " option

        case $option in
            1)
                install_dependencies
                ;;
            2)
                create_wallet
                ;;
            3)
                export_wallet_info
                ;;
            4)
                execute_mint
                ;;
            5)
                check_node_log
                ;;
            6)
                display_address
                ;;
            7)
                echo "退出脚本。"
                exit 0
                ;;
            *)
                echo "无效的选项，请重新选择。"
                ;;
        esac
    done
}

# 运行主菜单
main_menu
