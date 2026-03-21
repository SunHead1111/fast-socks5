#!/bin/bash

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 檢查 root 權限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}錯誤：請使用 root 權限執行此腳本！${NC}"
        exit 1
    fi
}

# 安裝與配置
install_sing_box() {
    echo -e "${GREEN}開始安裝 sing-box SOCKS5 代理...${NC}"

    # 獲取使用者輸入
    read -p "請輸入 SOCKS5 端口 [默認 1080]: " PORT
    PORT=${PORT:-1080}
    read -p "請輸入 用戶名 [默認 admin]: " USERNAME
    USERNAME=${USERNAME:-admin}
    read -p "請輸入 密碼 [默認 123456]: " PASSWORD
    PASSWORD=${PASSWORD:-123456}

    # 安裝依賴 (適配 Debian/Ubuntu 和 CentOS/RHEL)
    echo -e "${YELLOW}正在安裝必要依賴...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update -y && apt-get install -y curl wget jq tar
    elif command -v yum &> /dev/null; then
        yum install -y curl wget jq tar
    else
        echo -e "${RED}不支持的系統包管理器，請手動安裝 curl, wget, jq, tar${NC}"
        exit 1
    fi

    # 獲取最新版本
    echo -e "${YELLOW}正在獲取 sing-box 最新版本...${NC}"
    LATEST_VERSION=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | jq -r .tag_name)
    if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" == "null" ]; then
        echo -e "${RED}獲取最新版本失敗，請檢查網絡連接或 GitHub API 限制！${NC}"
        exit 1
    fi
    
    # 去除 'v' 前綴以用於文件名匹配
    VERSION_NUM=${LATEST_VERSION#v}
    
    # 根據系統架構下載
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) DL_ARCH="amd64" ;;
        aarch64) DL_ARCH="arm64" ;;
        *) echo -e "${RED}不支持的架構: $ARCH${NC}"; exit 1 ;;
    esac

    FILE_NAME="sing-box-${VERSION_NUM}-linux-${DL_ARCH}"
    DOWNLOAD_URL="https://hk.gh-proxy.org/https://github.com/SagerNet/sing-box/releases/download/${LATEST_VERSION}/${FILE_NAME}.tar.gz"

    echo -e "${YELLOW}正在下載 ${DOWNLOAD_URL}...${NC}"
    wget -qO sing-box.tar.gz "$DOWNLOAD_URL"
    if [ $? -ne 0 ]; then
        echo -e "${RED}下載失敗，請檢查網絡或下載鏈接！${NC}"
        exit 1
    fi

    echo -e "${YELLOW}正在解壓並安裝二進制文件...${NC}"
    tar -xzf sing-box.tar.gz
    mv ${FILE_NAME}/sing-box /usr/local/bin/
    chmod +x /usr/local/bin/sing-box
    rm -rf sing-box.tar.gz ${FILE_NAME}

    # 配置目錄
    echo -e "${YELLOW}生成配置文件...${NC}"
    mkdir -p /etc/sing-box

    # 生成 SOCKS5 配置文件
    cat > /etc/sing-box/config.json <<EOF
{
  "log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "socks",
      "tag": "socks-in",
      "listen": "::",
      "listen_port": ${PORT},
      "users": [
        {
          "username": "${USERNAME}",
          "password": "${PASSWORD}"
        }
      ]
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
EOF

    # 創建 systemd 服務
    echo -e "${YELLOW}配置 Systemd 服務...${NC}"
    cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
Description=sing-box service
Documentation=https://sing-box.sagernet.org
After=network.target nss-lookup.target

[Service]
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

    # 啟動並設置開機自啟
    systemctl daemon-reload
    systemctl enable --now sing-box

    # 獲取公網 IP
    PUBLIC_IP=$(curl -s ifconfig.me)

    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN} sing-box SOCKS5 代理安裝並啟動成功！${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo -e "${YELLOW} 服務器 IP: ${PUBLIC_IP}${NC}"
    echo -e "${YELLOW} 端口 (Port): ${PORT}${NC}"
    echo -e "${YELLOW} 用戶名 (User): ${USERNAME}${NC}"
    echo -e "${YELLOW} 密碼 (Passwd): ${PASSWORD}${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo -e "您可以使用如 v2rayN、Clash 或 Telegram 的 Proxy 設置來連接"
    echo -e "查看運行日誌：${YELLOW}journalctl -u sing-box -f${NC}"
}

# 卸載
uninstall_sing_box() {
    echo -e "${YELLOW}正在卸載 sing-box...${NC}"
    
    # 停止並禁用服務
    if systemctl is-active --quiet sing-box; then
        systemctl stop sing-box
    fi
    if systemctl is-enabled --quiet sing-box; then
        systemctl disable sing-box
    fi
    
    # 刪除相關文件
    rm -f /etc/systemd/system/sing-box.service
    systemctl daemon-reload
    
    rm -rf /etc/sing-box
    rm -f /usr/local/bin/sing-box
    
    echo -e "${GREEN}卸載完成！${NC}"
}

# 主選單
menu() {
    clear
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   sing-box SOCKS5 一鍵管理腳本${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${YELLOW} 1.${NC} 安裝並配置 sing-box SOCKS5"
    echo -e "${YELLOW} 2.${NC} 完全卸載 sing-box"
    echo -e "${YELLOW} 0.${NC} 退出"
    echo -e "${GREEN}========================================${NC}"
    read -p "請選擇操作 [0-2]: " choice

    case $choice in
        1)
            check_root
            install_sing_box
            ;;
        2)
            check_root
            uninstall_sing_box
            ;;
        0)
            echo -e "${GREEN}退出腳本。${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}輸入錯誤，請重新選擇！${NC}"
            sleep 2
            menu
            ;;
    esac
}

# 執行主選單
menu
