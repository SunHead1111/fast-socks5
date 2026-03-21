# fast-socks5

基於 [sing-box](https://github.com/SagerNet/sing-box) 核心的輕量級 SOCKS5 代理一鍵安裝與管理腳本。

本腳本可幫助您在 Linux 服務器（如 Debian, Ubuntu, CentOS 等）上快速部署一個安全的 SOCKS5 代理服務，支持自定義端口、帳號與密碼，並提供了一鍵安裝與徹底卸載功能。

## ✨ 功能特點

- **一鍵自動部署**：自動從 GitHub 拉取最新版的 sing-box 核心並進行安裝。
- **自定義配置**：支持在安裝過程中自定義 SOCKS5 代理的**端口 (Port)**、**用戶名 (Username)** 和 **密碼 (Password)**。
- **守護進程管理**：自動創建並註冊 `systemd` 服務，支持開機自動啟動與後台穩定運行。
- **多架構支持**：自動識別 `amd64` (x86_64) 與 `arm64` (aarch64) 系統架構。
- **綠色卸載乾淨乾脆**：提供一鍵卸載選項，自動停止進程並清理所有殘留文件和配置。

## 🚀 一鍵安裝腳本

如果您已經將腳本上傳到了您的 GitHub 倉庫，您可以直接在服務器終端（需 **root** 權限）運行以下命令來一鍵下載並執行：

```bash
# 請將下方的 URL 替換為您自己 GitHub 倉庫中 fast-socks5.sh 的 Raw 連結
bash <(curl -Ls https://raw.githubusercontent.com/您的用戶名/您的倉庫名/main/fast-socks5.sh)
```

*(如果您的默認分支不是 `main` 而是 `master`，請注意修改連結。)*

### 備用安裝方式（手動下載執行）

```bash
wget -O fast-socks5.sh https://raw.githubusercontent.com/您的用戶名/您的倉庫名/main/fast-socks5.sh
chmod +x fast-socks5.sh
sudo ./fast-socks5.sh
```

## 📋 使用說明

運行腳本後，會出現以下互動選單：

```text
========================================
   sing-box SOCKS5 一鍵管理腳本
========================================
 1. 安裝並配置 sing-box SOCKS5
 2. 完全卸載 sing-box
 0. 退出
========================================
請選擇操作 [0-2]:
```

1. 輸入 `1` 開始安裝。
2. 按照提示依次輸入您的自定義 `端口`、`用戶名` 和 `密碼`（直接回車將使用默認值：1080 / admin / 123456）。
3. 安裝完成後，腳本會打印出包含服務器公網 IP 的連接資訊，您可以使用這些資訊在任何支持 SOCKS5 協議的客戶端（如 v2rayN, Clash, Telegram 等）中進行連接。

## ⚙️ 常用指令

- **查看服務狀態**：`systemctl status sing-box`
- **重啟代理服務**：`systemctl restart sing-box`
- **停止代理服務**：`systemctl stop sing-box`
- **查看運行日誌**：`journalctl -u sing-box -f`

## ⚠️ 注意事項

- 本腳本需要 **root** 權限執行。
- 安裝前請確保您的服務器防火牆/安全組已經放行了您所設置的 SOCKS5 端口（默認 1080）。
- 腳本中包含了代理下載加速（`gh-proxy.org`），以確保在某些網絡環境下能順利拉取 GitHub Release 資源。

## 📝 授權協議

本項目基於 MIT License 開源，請自由使用與修改。
