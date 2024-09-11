#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/CAT.sh"

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1) 铸造代币"
        echo "2) 导出钱包"
        echo "3) 退出"

        read -p "请输入选项: " option

        case $option in
            1)
                # 执行铸造代币操作
                echo "开始铸造代币..."

                # 检查是否以root用户运行脚本
                if [ "$(id -u)" != "0" ]; then
                    echo "此脚本需要以root用户权限运行。"
                    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
                    exit 1
                fi

                # 检查是否已安装 Docker
                if ! command -v docker &> /dev/null; then
                    echo "Docker 未安装，正在安装 Docker..."

                    # 更新包列表并安装 Docker 所需依赖
                    sudo apt-get update
                    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

                    # 添加 Docker 的 GPG 密钥
                    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

                    # 添加 Docker APT 软件源
                    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

                    # 更新包列表并安装 Docker
                    sudo apt-get update
                    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

                    # 启动并启用 Docker 服务
                    sudo systemctl start docker
                    sudo systemctl enable docker

                    echo "Docker 已成功安装并启动。"
                else
                    echo "Docker 已安装，跳过安装步骤。"
                fi

                # 验证 Docker 状态
                echo "Docker 状态:"
                sudo systemctl status docker --no-pager

                # 检查是否已安装 Node.js
                if ! command -v node &> /dev/null; then
                    echo "Node.js 未安装，正在安装 Node.js..."

                    # 更新包列表并安装 Node.js 依赖
                    sudo apt-get update

                    # 安装 Node.js（此处安装的是 NodeSource 提供的官方版本）
                    curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
                    sudo apt-get install -y nodejs

                    echo "Node.js 已成功安装。"
                else
                    echo "Node.js 已安装，跳过安装步骤。"
                fi

                # 验证 Node.js 版本
                echo "Node.js 版本:"
                node -v

                # 检查是否已安装 Docker Compose
                if ! command -v docker-compose &> /dev/null; then
                    echo "Docker Compose 未安装，正在安装 Docker Compose..."
                    DOCKER_COMPOSE_VERSION="2.20.2"
                    sudo curl -L "https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                    sudo chmod +x /usr/local/bin/docker-compose
                else
                    echo "Docker Compose 已安装，跳过安装步骤。"
                fi

                # 输出 Docker Compose 版本
                echo "Docker Compose 版本:"
                docker-compose --version

                # 拉取 GitHub 仓库并构建项目
                echo "正在克隆 GitHub 仓库..."
                git clone https://github.com/CATProtocol/cat-token-box.git

                # 进入项目目录并安装依赖、构建项目
                cd cat-token-box/
                echo "安装依赖并构建项目..."
                yarn install && yarn build

                # 构建 Docker 镜像
                echo "正在构建 Docker 镜像..."
                sudo docker build -t tracker:latest .

                # 运行 Docker 容器
                echo "正在运行 Docker 容器..."
                sudo docker run -d \
                    --name tracker \
                    --add-host="host.docker.internal:host-gateway" \
                    -e DATABASE_HOST="host.docker.internal" \
                    -e RPC_HOST="host.docker.internal" \
                    -p 3000:3000 \
                    tracker:latest

                # 进入特定目录
                cd packages/cli
                echo "已进入目录 /root/cat-token-box/packages/cli"

                # 自动写入 config.json
                echo "正在创建或修改 config.json 文件..."
                sudo tee config.json > /dev/null <<EOF
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

                # 创建钱包
                echo "正在创建钱包..."
                sudo yarn cli wallet create

                # 创建并写入 script.sh 文件
                echo "正在创建并写入 script.sh 文件..."
                sudo tee script.sh > /dev/null <<EOF
#!/bin/bash

command="sudo yarn cli mint -i 45ee725c2c5993b3e4d308842d87e973bf1951f5f7a804b21e4dd964ecd12d6b_0 5"

while true; do
    \$command

    if [ \$? -ne 0 ]; then
        echo "命令执行失败，退出循环"
        exit 1
    fi

    sleep 1
done
EOF

                # 给予 script.sh 执行权限并执行
                echo "正在赋予 script.sh 执行权限并执行..."
                sudo chmod +x script.sh
                ./script.sh

                echo "操作完成。"
                ;;
            2)
                # 导出钱包信息
                echo "导出钱包信息..."

                # 检查钱包文件是否存在
                if [ ! -f /root/cat-token-box/packages/cli/wallet.json ]; then
                    echo "钱包文件 /root/cat-token-box/packages/cli/wallet.json 不存在。"
                    exit 1
                fi

                # 提取并显示 JSON 内容
                echo "钱包信息:"
                echo "Name: $(grep -oP '"name": *"\K[^"]+' /root/cat-token-box/packages/cli/wallet.json)"
                echo "Mnemonic: $(grep -oP '"mnemonic": *"\K[^"]+' /root/cat-token-box/packages/cli/wallet.json)"
                ;;
            3)
                # 退出脚本
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
