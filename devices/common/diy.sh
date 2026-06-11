#!/bin/bash
#=================================================
shopt -s extglob

sed -i '$a src-git kiddin9 https://github.com/kiddin9/op-packages.git;main' feeds.conf.default
sed -i "/telephony/d" feeds.conf.default

sed -i "s?targets/%S/packages?targets/%S/\$(LINUX_VERSION)?" include/feeds.mk

sed -i '/	refresh_config();/d' scripts/feeds

sed -i "s?git.openwrt.org/\(project\|feed\)?github.com/openwrt?g" feeds.conf.default

./scripts/feeds update -a
./scripts/feeds install -a -p kiddin9 -f
./scripts/feeds install -a

sed --follow-symlinks -i "s#%C\"#%C by Kiddin'\"#" package/base-files/files/etc/os-release
sed -i -e '$a /etc/bench.log' \
        -e '/\/etc\/profile/d' \
        -e '/\/etc\/shinit/d' \
        package/base-files/files/lib/upgrade/keep.d/base-files-essential
sed -i -e '/^\/etc\/profile/d' \
        -e '/^\/etc\/shinit/d' \
        package/base-files/Makefile
sed -i "s/192.168.1.1/192.168.1.200/" package/base-files/files/bin/config_generate

sed -i "s#false; \\\#true; \\\#" include/download.mk

wget -N https://github.com/immortalwrt/immortalwrt/raw/refs/heads/openwrt-25.12/package/kernel/linux/modules/video.mk -P package/kernel/linux/modules/
wget -N https://github.com/immortalwrt/immortalwrt/raw/refs/heads/openwrt-25.12/package/network/utils/nftables/patches/002-nftables-add-fullcone-expression-support.patch -P package/network/utils/nftables/patches/
wget -N https://github.com/immortalwrt/immortalwrt/raw/refs/heads/openwrt-25.12/package/libs/libnftnl/patches/001-libnftnl-add-fullcone-expression-support.patch -P package/libs/libnftnl/patches/
wget -N https://github.com/immortalwrt/immortalwrt/raw/refs/heads/openwrt-25.12/package/firmware/wireless-regdb/patches/600-custom-change-txpower-and-dfs.patch -P package/firmware/wireless-regdb/patches/
wget -N  https://github.com/coolsnowwolf/lede/raw/refs/heads/master/package/system/fstools/patches/0200-ntfs3-with-utf8.patch -P package/system/fstools/patches/
wget -N https://github.com/immortalwrt/immortalwrt/raw/refs/heads/openwrt-25.12/config/Config-kernel.in -P config/

rm -rf package/libs/openssl package/network/services/ppp
git_clone_path openwrt-25.12 https://github.com/immortalwrt/immortalwrt package/libs/openssl package/network/services/ppp

echo "$(date +"%s")" >version.date
sed -i '/$(curdir)\/compile:/c\$(curdir)/compile: package/opkg/host/compile' package/Makefile
sed -i "s/DEFAULT_PACKAGES:=/DEFAULT_PACKAGES:=luci-app-advancedplus luci-app-firewall luci-app-package-manager luci-app-upnp luci-app-syscontrol \
luci-app-wizard luci-base luci-compat luci-lib-ipkg luci-lib-fs \
coremark wget-ssl curl autocore htop nano zram-swap kmod-lib-zstd kmod-tcp-bbr bash openssh-sftp-server block-mount resolveip ds-lite swconfig luci-app-fan luci-app-wifihistory /" include/target.mk

sed -i "s/^.*vermagic$/\techo '1' > \$(LINUX_DIR)\/.vermagic/" include/kernel-defaults.mk

status=$(curl -H "Authorization: token $REPO_TOKEN" -s "https://api.github.com/repos/kiddin9/op-packages/actions/runs" | jq -r '.workflow_runs[0].status')
echo "$status"
while [[ "$status" == "in_progress" || "$status" == "queued" ]];do
	echo "wait 5s"
	sleep 5
	status=$(curl -H "Authorization: token $REPO_TOKEN" -s "https://api.github.com/repos/kiddin9/op-packages/actions/runs" | jq -r '.workflow_runs[0].status')
done

wget -N https://raw.githubusercontent.com/openwrt/packages/master/lang/golang/golang/Makefile -P feeds/packages/lang/golang/golang/

#sed -i "/call Build\/check-size,\$\$(KERNEL_SIZE)/d" include/image.mk

sed -i "/+= targz/d" include/image.mk

git_clone_path master https://github.com/coolsnowwolf/lede mv target/linux/generic/hack-6.12

rm -rf target/linux/generic/hack-6.12/767-net-phy-realtek-add-led*
wget -N https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/generic/pending-6.12/613-netfilter_optional_tcp_window_check.patch -P target/linux/generic/pending-6.12/

# find target/linux/x86 -name "config*" -exec bash -c 'cat kernel.conf >> "{}"' \;
sed -i 's/max_requests 3/max_requests 20/g' package/network/services/uhttpd/files/uhttpd.config
#rm -rf ./feeds/packages/lang/{golang,node}
sed -i "s/tty\(0\|1\)::askfirst/tty\1::respawn/g" target/linux/*/base-files/etc/inittab

date=`date +%m.%d.%Y`
sed -i -e "/\(# \)\?REVISION:=/c\REVISION:=$date" -e '/VERSION_CODE:=/c\VERSION_CODE:=$(REVISION)' include/version.mk

sed -i 's/option timeout 30/option timeout 60/g' package/system/rpcd/files/rpcd.config

sed -i \
	-e "s/+\(luci\|luci-ssl\|uhttpd\)\( \|$\)/\2/" \
	-e "s/+nginx\( \|$\)/+nginx-ssl\1/" \
	-e 's/+python\( \|$\)/+python3/' \
	-e 's?../../lang?$(TOPDIR)/feeds/packages/lang?' \
	package/feeds/kiddin9/*/Makefile

sed -i "s/OpenWrt/Kwrt/g" package/base-files/files/bin/config_generate package/base-files/image-config.in package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc config/Config-images.in Config.in include/u-boot.mk include/version.mk || true

sed -i -e "s/set \${s}.country='\${country || ''}'/set \${s}.country='\${country || \"CN\"}'/g" -e "s/set \${s}.disabled=.*/set \${s}.disabled='0'/" package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc

rm -rf package/feeds/packages/jool

# =========================================================
# 定制：清理广告、修改后台密码与IP
# =========================================================

# 将 Kiddin9 默认设置里的 10.0.0.1 全部替换为 192.168.1.200
sed -i 's/10.0.0.1/192.168.1.200/g' feeds/kiddin9/my-default-settings/files/etc/uci-defaults/99-default-settings

# 1. 删除默认赞助广告链接
rm -rf feeds/kiddin9/my-default-settings/files/usr/lib/lua/luci/view/admin_status/index/links.htm

# 2. 修改后台默认 root 密码为 12345678
sed -i 's|echo "root"|echo "12345678"|g' feeds/kiddin9/my-default-settings/files/etc/uci-defaults/99-default-settings

# =========================================================
# 定制：Wi-Fi 强制开启与密码设置
# =========================================================
# 创建一个在首次开机时自动运行的底层脚本
mkdir -p diy/package/base-files/files/etc/uci-defaults
cat > diy/package/base-files/files/etc/uci-defaults/zz-custom-wifi <<EOF
#!/bin/sh

uci set wireless.default_radio0.encryption='sae-mixed'
uci set wireless.default_radio0.key='12345678'
uci set wireless.default_radio1.encryption='psk2'
uci set wireless.default_radio1.key='12345678'

uci commit wireless
exit 0
EOF
# 赋予该脚本开机执行权限
chmod +x diy/package/base-files/files/etc/uci-defaults/zz-custom-wifi
