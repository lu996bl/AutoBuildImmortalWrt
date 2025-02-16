#!/bin/bash

# 日志文件
LOGFILE="/tmp/uci-defaults-log.txt"
exec > >(tee -a "$LOGFILE") 2>&1

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log "Starting 99-custom.sh"
log "编译固件大小为: $PROFILE MB"
log "Include Docker: $INCLUDE_DOCKER"

# 创建 PPPoE 配置文件
mkdir -p /home/build/immortalwrt/files/etc/config

if [[ "$ENABLE_PPPOE" == "yes" && -n "$PPPOE_ACCOUNT" && -n "$PPPOE_PASSWORD" ]]; then
    cat << EOF > /home/build/immortalwrt/files/etc/config/pppoe-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF
    chmod 644 /home/build/immortalwrt/files/etc/config/pppoe-settings
    log "PPPoE 配置文件已生成"
else
    log "未启用 PPPoE 或缺少账号/密码，跳过生成配置文件"
fi

# 定义软件包列表
PACKAGES=(
    "curl"
    "luci-i18n-diskman-zh-cn"
    "luci-i18n-firewall-zh-cn"
    "luci-i18n-filebrowser-zh-cn"
    "luci-app-argon-config"
    "luci-i18n-argon-config-zh-cn"
    "luci-i18n-opkg-zh-cn"
    "luci-i18n-ttyd-zh-cn"
    "luci-i18n-passwall-zh-cn"
    "luci-app-openclash"
    "luci-i18n-homeproxy-zh-cn"
    "openssh-sftp-server"
    "fdisk"
    "script-utils"
    "luci-i18n-samba4-zh-cn"
)

# 添加 Docker 插件
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES+=("luci-i18n-dockerman-zh-cn")
    log "Adding package: luci-i18n-dockerman-zh-cn"
fi

# 构建固件
set -e  # 严格错误处理

log "Building image with the following packages:"
log "${PACKAGES[@]}"

make image PROFILE="generic" PACKAGES="${PACKAGES[*]}" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE=$PROFILE

if [ $? -eq 0 ]; then
    log "Build completed successfully."
else
    log "Error: Build failed!"
    exit 1
fi
