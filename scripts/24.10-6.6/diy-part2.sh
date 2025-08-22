#!/bin/bash
#
# 版权所有 (c) 2019-2020 P3TERX <https://p3terx.com>
#
# 这是一个自由软件，根据 MIT 许可证授权。
# 详细信息请参见 /LICENSE。
#
# https://github.com/P3TERX/Actions-OpenWrt

# 修改默认 IP
CONFIG_FILE="package/base-files/files/bin/config_generate"
if [ -f "$CONFIG_FILE" ]; then
  if ! grep -q "192.168.2.1" "$CONFIG_FILE"; then
    sed -i 's/192\.168\.6\.1/192.168.2.1/g; s/192\.168\.1\.1/192.168.2.1/g' "$CONFIG_FILE"
    echo "IP 地址已更新为 192.168.2.1"
  else
    echo "IP 地址已是 192.168.2.1，无需修改"
  fi
else
  echo "警告：$CONFIG_FILE 不存在，跳过 IP 修改"
fi

# 预装
# OpenClash
echo "CONFIG_PACKAGE_luci-app-openclash=y" >> .config
# 微信推送
echo "CONFIG_PACKAGE_luci-app-wechatpush=y" >> .config
echo "CONFIG_PACKAGE_luci-i18n-wechatpush-zh-cn=y" >> .config

sed -i 's/max-frequency = <52000000>;/max-frequency = <26000000>;/g' /workdir/openwrt/target/linux/mediatek/dts/mt7981b-cmcc-rax3000m-emmc.dts
sed -i "s/if (\$sum ne \$file_hash)/if (\$sum ne \$file_hash \&\& 1==2)/g" /workdir/openwrt/scripts/download.pl

cat /workdir/openwrt/target/linux/mediatek/dts/mt7981b-cmcc-rax3000m-emmc.dts
cat /workdir/openwrt/scripts/download.pl

# 删除 package/mtk/drivers/mt_wifi/files/mt7981-default-eeprom/e2p
rm -f package/mtk/drivers/mt_wifi/files/mt7981-default-eeprom/e2p
if [ $? -eq 0 ]; then
  echo "已删除 package/mtk/drivers/mt_wifi/files/mt7981-default-eeprom/e2p"
else
  echo "错误：删除 package/mtk/drivers/mt_wifi/files/mt7981-default-eeprom/e2p 失败"
fi

# 创建 MT7981 固件符号链接
EEPROM_FILE="package/mtk/drivers/mt_wifi/files/mt7981-default-eeprom/MT7981_iPAiLNA_EEPROM.bin"
if [ -f "$EEPROM_FILE" ]; then
  mkdir -p files/lib/firmware
  ln -sf /lib/firmware/MT7981_iPAiLNA_EEPROM.bin files/lib/firmware/e2p
  echo "符号链接已创建"
  ls -l files/lib/firmware/e2p || { echo "错误：符号链接创建失败"; exit 1; }
else
  echo "错误：$EEPROM_FILE 不存在，无法创建符号链接"
  exit 1
fi

echo ">>> 启用 keepalived和kmod-nf-ipvs 模块"
cat <<EOF >> .config
CONFIG_PACKAGE_keepalived=y
CONFIG_PACKAGE_libnl-genl200=y
CONFIG_PACKAGE_libmagic=y
CONFIG_PACKAGE_kmod-macvlan=y
CONFIG_PACKAGE_libnl-route200=y
CONFIG_PACKAGE_libnfnetlink0=y
CONFIG_PACKAGE_libip4tc2=y
CONFIG_PACKAGE_libip6tc2=y
CONFIG_PACKAGE_libxtables12=y
CONFIG_PACKAGE_libipset13=y
CONFIG_PACKAGE_keepalived-sync=y
CONFIG_PACKAGE_kmod-nf-ipvs=y
CONFIG_PACKAGE_kmod-ipvs=y
CONFIG_PACKAGE_kmod-ipvs-core=y
CONFIG_PACKAGE_kmod-ipvs-rr=y
CONFIG_PACKAGE_kmod-ipvs-wrr=y
CONFIG_PACKAGE_kmod-ipvs-sh=y

CONFIG_PACKAGE_aria2=y
EOF

make defconfig

echo ">>> 已执行 make defconfig，确保模块依赖被解析"
