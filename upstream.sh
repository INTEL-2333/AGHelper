#!/usr/bin/env bash

#====================================================
#	System Request:Debian 9+/Ubuntu 18.04+/Centos 7+/OpenWrt R18.06+
#	Author:	INTEL-2333
#	Dscription: AdGuardHome Helper
#	Github: https://github.com/INTEL-2333/AGHelper/
#====================================================

# Font color
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[36m"
Font="\033[0m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
OK="${Green}[OK]${Font}"
ERROR="${Red}[ERROR]${Font}"

# Variable
shell_version="0.0.1"

function print_ok() {
  echo -e "${OK} ${Blue} $1 ${Font}"
}

function print_error() {
  echo -e "${ERROR} ${RedBG} $1 ${Font}"
}

function update_sh(){
  ol_version=$(curl -L -s https://cdn.statically.io/gh/INTEL-2333/ | grep "shell_version=" | head -1 | awk -F '=|"' '{print $3}')
  if [[ "$shell_version" != "$(echo -e "$shell_version\n$ol_version" | sort -rV | head -1)" ]]; then
    print_ok "存在新版本，是否更新 [Y/N]?"
    read -r update_confirm
    case $update_confirm in
    [yY][eE][sS] | [yY])
      wget -N --no-check-certificate https://testingcf.jsdelivr.net/gh/INTEL-2333/AGHelper/upstream.sh
      print_ok "更新完成"
      print_ok "您可以通过 bash $0 执行本程序"
      exit 0
      ;;
    *) 
      ;;
    esac
  else
    print_ok "当前版本为最新版本"
    print_ok "您可以通过 bash $0 执行本程序"
  fi
}

function automated_AGH() {
  source '/etc/os-release'
  if [[ "${ID}" == "centos" && ${VERSION_ID} -ge 7 ]]; then
    print_ok "当前系统为 Centos ${VERSION_ID} ${VERSION}"
    yum install -y curl
    curl -s -S -L https://testingcf.jsdelivr.net/gh/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- $automated_option
  elif [[ "${ID}" == "ol" ]]; then
    print_ok "当前系统为 Oracle Linux ${VERSION_ID} ${VERSION}"
    yum install -y curl
    curl -s -S -L https://testingcf.jsdelivr.net/gh/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- $automated_option
  elif [[ "${ID}" == "openwrt" ]]; then
    print_ok "当前系统为 OpenWRT ${VERSION_ID} ${VERSION}"
    if [[ "${automated_option}" == "-v" ]]; then
      opkg install https://endpoint.fastgit.org/https://github.com/rufengsuixing/luci-app-adguardhome/releases/download/1.8-9/luci-app-adguardhome_1.8-9_all.ipk
    else
      opkg remove luci-app-adguardhome -autoremove
    fi
  elif [[ "${ID}" == "debian" && ${VERSION_ID} -ge 9 ]]; then
    print_ok "当前系统为 Debian ${VERSION_ID} ${VERSION}"
    apt install -y curl
    curl -s -S -L https://testingcf.jsdelivr.net/gh/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- $automated_option
  elif [[ "${ID}" == "ubuntu" && $(echo "${VERSION_ID}" | cut -d '.' -f1) -ge 18 ]]; then
    print_ok "当前系统为 Ubuntu ${VERSION_ID} ${UBUNTU_CODENAME}"
    apt install -y curl
    curl -s -S -L https://testingcf.jsdelivr.net/gh/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- $automated_option
  else
    print_error "当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内"
    exit 1
  fi
}

function create_upstream(){
  read -rp "请输入生成路径[默认:/opt/AdGuardHome/upstream.txt]:" upstream_path
  [ -z "$upstream_path" ] && upstream_path="/opt/AdGuardHome/upstream.txt"
  read -rp "请输入境内DNS数量[默认:1]:" Num1
  [ -z "$Num1" ] && Num1="1"
  > $upstream_path
  for ((i=1; i<=Num1; i++))
  do
    read -rp "请输入境内DNS$i[默认:tls://223.5.5.5]:" DNS
    [ -z "$DNS" ] && DNS="tls://223.5.5.5"
    curl -s 'https://endpoint.fastgit.org/https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/direct-list.txt' | sed '/regexp:/d' | sed 's/full://g' | tr "\n" "/" | sed -e 's|^|/|' -e 's|\(.*\)|[\1]'${DNS}'|' >> $upstream_path
    echo -n -e "\n" >> $upstream_path
  done
  read -rp "请输入境外DNS数量[默认:1]:" Num2
  [ -z "$Num2" ] && Num2="1"
  for ((i=1; i<=Num2; i++))
  do
    read -rp "请输入境外DNS$i[默认:tls://8.8.8.8]:" DNS
    [ -z "$DNS" ] && DNS="tls://8.8.8.8"
    echo "$DNS" >> $upstream_path
  done
  print_ok "分流配置文件[$upstream_path]生成完毕"
  sleep 2s
  menu
}

function service_AGH(){
  service AdGuardHome $service_option
  print_ok "命令[$service_option]已执行"
}

function update_yaml(){
  read -rp "请输入AdGuardHome.yaml路径[默认:/opt/AdGuardHome/AdGuardHome.yaml]:" yaml_path
  [ -z "$yaml_path" ] && yaml_path="/opt/AdGuardHome/AdGuardHome.yaml"
  if [[ "${upstream_status}" == "enable" ]]; then
    read -rp "请输入分流文件路径[默认:/opt/AdGuardHome/upstream.txt]:" upstream_path
    [ -z "$upstream_path" ] && upstream_path="/opt/AdGuardHome/upstream.txt"
    sed -i "/upstream_dns_file:/c\  upstream_dns_file: $upstream_path" $yaml_path
  else
    sed -i "/upstream_dns_file:/c\  upstream_dns_file: \"\"" $yaml_path
  fi
  print_ok "配置文件[$yaml_path]已修改"
  sleep 2s
  menu
}

function update_crontab(){
  if [[ "${crontab_status}" == "enable" ]]; then
    read -rp "请输入生成路径[默认:/opt/AdGuardHome/upstream.txt]:" upstream_path
    [ -z "$upstream_path" ] && upstream_path="/opt/AdGuardHome/upstream.txt"
    echo -e "#!/usr/bin/env bash\n> $upstream_path" > /etc/update4AGH.sh
    read -rp "请输入境内DNS数量[默认:1]:" Num1
    [ -z "$Num1" ] && Num1="1"
    for ((i=1; i<=Num1; i++))
    do
      read -rp "请输入境内DNS$i[默认:tls://223.5.5.5]:" DNS
      [ -z "$DNS" ] && DNS="tls://223.5.5.5"
      echo -e "curl -s 'https://endpoint.fastgit.org/https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/direct-list.txt' | sed '/regexp:/d' | sed 's/full://g' | tr "\n" "/" | sed -e 's|^|/|' -e 's|\(.*\)|[\1]$DNS|' >> $upstream_path" >> /etc/update4AGH.sh
    done
    read -rp "请输入境外DNS数量[默认:1]:" Num2
    [ -z "$Num2" ] && Num2="1"
    for ((i=1; i<=Num2; i++))
    do
      read -rp "请输入境外DNS$i[默认:tls://8.8.8.8]:" DNS
      [ -z "$DNS" ] && DNS="tls://8.8.8.8"
      echo -e "$DNS >> $upstream_path" >> /etc/update4AGH.sh
    done
    echo "0 0 * * 0 bash /etc/update4AGH.sh" >> /etc/crontab
  else
    sed -i '/update4AGH.sh/d' /etc/crontab
    rm /etc/update4AGH.sh
  fi
  service cron reload || service crond reload
  print_ok "定时任务已设置为[$crontab_status]"
  sleep 2s
  menu
}

function disable_fiewall(){
  systemctl stop firewalld
  systemctl disable firewalld
  systemctl stop nftables
  systemctl disable nftables
  systemctl stop ufw
  systemctl disable ufw
}

menu() {
  clear
  echo && echo -e "
    AdGuard分流助手 安装管理脚本 ${Red}[${shell_version}]${Font}
    ---Authored by INTEL-2333---
    https://github.com/INTEL-2333/AGHelper/

  —————————————— 安装向导 ——————————————
  ${Green}0.${Font}  升级 脚本
  ${Green}1.${Font}  安装 AdGuardHome
  ${Green}2.${Font}  卸载 AdGuardHome
  —————————————— 配置更改 ——————————————
  ${Green}11.${Font} 生成 分流文件
  ${Green}12.${Font} 使用 分流文件
  ${Green}13.${Font} 取消 分流文件
  ${Green}14.${Font} 开启 上游文件自动更新
  ${Green}15.${Font} 移除 上游文件自动更新
  —————————————— 其他选项 ——————————————
  ${Green}21.${Font} 查看 AdGuardHome状态
  ${Green}22.${Font} 开启 AdGuardHome服务
  ${Green}23.${Font} 关闭 AdGuardHome服务
  ${Green}24.${Font} 重启 AdGuardHome服务
  ${Green}25.${Font} 关闭 防火墙(不建议)
  ${Green}99.${Font} 退出 脚本
  --------------------------------------"
  read -rp "请输入数字:" menu_num
  case $menu_num in
  0)
    update_sh
    ;;
  1)
    automated_option=-v
    automated_AGH
    ;;
  2)
    automated_option=-u
    automated_AGH
    ;;
  11)
    create_upstream
    ;;
  12)
    upstream_status=enable
    update_yaml
    ;;
  13)
    upstream_status=disable
    update_yaml
    ;;
  14)
    crontab_status=enable
    update_crontab
    ;;
  15)
    crontab_status=remove
    update_crontab
    ;;
  21)
    service_option=status
    service_AGH
    ;;
  22)
    service_option=start
    service_AGH
    ;;
  23)
    service_option=stop
    service_AGH
    ;;
  24)
    service_option=restart
    service_AGH
    ;;
  25)
    disable_fiewall
    ;;
  99)
    exit 1
    ;;
  *)
    print_error "请输入正确数字 [0-99]"
    sleep 2s
    menu
    ;;
  esac
}
menu "$@"