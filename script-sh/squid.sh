#!/bin/bash
# squid安装脚本

# 代理服务器账户(不要修改，只需在配置文件中配置，程序自动修改)
squid_proxy_user=myproxy
squid_proxy_passwd=N2PYOnRDk5gKInqQ
squid_proxy_port=3100


check_os_type(){
        # Get OS Type
    if [ -e /etc/redhat-release ]; then
      OS=CentOS
      PM=yum
    elif [ -n "$(grep 'Amazon Linux' /etc/issue)" -o -n "$(grep 'Amazon Linux' /etc/os-release)" ]; then
      OS=CentOS
      PM=yum
    elif [ -n "$(grep 'bian' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == "Debian" ]; then
      OS=Debian
      PM=apt
    elif [ -n "$(grep 'Deepin' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == "Deepin" ]; then
      OS=Debian
      PM=apt
    elif [ -n "$(grep -w 'Kali' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == "Kali" ]; then
      OS=Debian
      PM=apt
    elif [ -n "$(grep 'Ubuntu' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == "Ubuntu" -o -n "$(grep 'Linux Mint' /etc/issue)" ]; then
      OS=Ubuntu
      PM=apt
    elif [ -n "$(grep 'elementary' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'elementary' ]; then
      OS=Ubuntu
      PM=apt
    fi
}



init_sys(){
    echo 'init system !'
    if [ "${PM}" == 'yum' ]; then
        # 关闭SELinux
        setenforce 0
        sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux
        sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
        sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/sysconfig/selinux
        sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/selinux/config
        # 开启包转发
        echo 1 > /proc/sys/net/ipv4/ip_forward
        if [ -e /etc/sysctl.conf ]; then
            # 如果值本身就为1，则不会被修改
            sed -i "s/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g" /etc/sysctl.conf
            sed -i "s/net.ipv4.tcp_syncookies = 0/net.ipv4.tcp_syncookies = 1/g" /etc/sysctl.conf
            sed -i "s/net.ipv4.tcp_tw_reuse = 0/net.ipv4.tcp_tw_reuse = 1/g" /etc/sysctl.conf
            sed -i "s/net.ipv4.tcp_tw_recycle = 0/net.ipv4.tcp_tw_recycle = 1/g" /etc/sysctl.conf
            sed -i "s/net.ipv4.tcp_fin_timeout = 60/net.ipv4.tcp_fin_timeout = 30/g" /etc/sysctl.conf
        else
            echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
            echo 'net.ipv4.tcp_syncookies = 1' >> /etc/sysctl.conf
            echo 'net.ipv4.tcp_tw_reuse = 1' >> /etc/sysctl.conf
            echo 'net.ipv4.tcp_tw_recycle = 1' >> /etc/sysctl.conf
            echo 'net.ipv4.tcp_fin_timeout = 30' >> /etc/sysctl.conf
        fi
    fi
    if [ "${PM}" == 'apt' ]; then
        # 开启包转发
        echo 1 > /proc/sys/net/ipv4/ip_forward
        if [ -e /etc/sysctl.conf ]; then
            # 如果值本身就为1，则不会被修改
            sed -i "s/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g" /etc/sysctl.conf
            sed -i "s/net.ipv4.tcp_syncookies = 0/net.ipv4.tcp_syncookies = 1/g" /etc/sysctl.conf
            sed -i "s/net.ipv4.tcp_tw_reuse = 0/net.ipv4.tcp_tw_reuse = 1/g" /etc/sysctl.conf
            sed -i "s/net.ipv4.tcp_tw_recycle = 0/net.ipv4.tcp_tw_recycle = 1/g" /etc/sysctl.conf
            sed -i "s/net.ipv4.tcp_fin_timeout = 60/net.ipv4.tcp_fin_timeout = 30/g" /etc/sysctl.conf
        else
            echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
            echo 'net.ipv4.tcp_syncookies = 1' >> /etc/sysctl.conf
            echo 'net.ipv4.tcp_tw_reuse = 1' >> /etc/sysctl.conf
            echo 'net.ipv4.tcp_tw_recycle = 1' >> /etc/sysctl.conf
            echo 'net.ipv4.tcp_fin_timeout = 30' >> /etc/sysctl.conf
        fi
    fi
    /sbin/sysctl -p
}


yum_squid(){
    echo 'start install squid !'
    yum install squid httpd-tools curl -y
    # 修改配置
    conf_path=/etc/squid
    basic_auth=/usr/lib64/squid
    echo "auth_param basic program ${basic_auth}/basic_ncsa_auth /etc/squid/passwords" >> ${conf_path}/squid.conf
    echo 'auth_param basic realm proxy' >> ${conf_path}/squid.conf
    echo 'acl authenticated proxy_auth REQUIRED' >> ${conf_path}/squid.conf
    echo 'http_access allow authenticated' >> ${conf_path}/squid.conf   # 允许所有认证通过的客户端
    sed -i "s/http_port 3128/http_port ${squid_proxy_port}/g" ${conf_path}/squid.conf
    sed -i "s/http_access deny all/#http_access deny all/g" ${conf_path}/squid.conf
    # 高匿设置
    echo 'request_header_access Via deny all' >> ${conf_path}/squid.conf
    echo 'request_header_access X-Forwarded-For deny all' >> ${conf_path}/squid.conf
    # 生成密钥
    htpasswd -bc  ${conf_path}/passwords ${squid_proxy_user} ${squid_proxy_passwd}
    chmod o+r ${conf_path}/passwords
    systemctl enable squid
    start_squid
}


apt_squid(){
	echo 'start install squid !'
    apt-get update -y && apt-get install squid apache2-utils curl -y
    # 修改配置
    if [ "${OS}" == 'Ubuntu' ]; then
        conf_path=/etc/squid3
        basic_auth=/usr/lib/squid3
        start_squid="sed -i '/By default this script does nothing/a\squid3' /etc/rc.local"
    elif [ "${OS}" == 'Debian' ]; then
        conf_path=/etc/squid
        basic_auth=/usr/lib/squid
        start_squid="service squid enable"
    fi
    echo "auth_param basic program ${basic_auth}/basic_ncsa_auth /etc/squid/passwords" >> ${conf_path}/squid.conf
    echo 'auth_param basic realm proxy' >> ${conf_path}/squid.conf
    echo 'acl authenticated proxy_auth REQUIRED' >> ${conf_path}/squid.conf
    echo 'http_access allow authenticated' >> ${conf_path}/squid.conf   # 允许所有认证通过的客户端
    sed -i "s/http_port 3128/http_port ${squid_proxy_port}/g" ${conf_path}/squid.conf
    sed -i "s/http_access deny all/#http_access deny all/g" ${conf_path}/squid.conf
    # 高匿设置
    echo 'request_header_access Via deny all' >> ${conf_path}/squid.conf
    echo 'request_header_access X-Forwarded-For deny all' >> ${conf_path}/squid.conf
    # 生成密钥
    htpasswd -bc  ${conf_path}/passwords ${squid_proxy_user} ${squid_proxy_passwd}
    chmod o+r ${conf_path}/passwords
    ${start_squid}
    start_squid
}


# 删除拨号软件，视服务商而定。
clean_sys(){
    if [ "${OS}" == 'CentOS' ]; then
        yum remove squid -y
        rm -rf /etc/squid
    elif [ "${OS}" == 'Ubuntu' ]; then
        apt-get remove squid3 -y && apt-get autoremove
        rm -rf /etc/squid3
    elif [ "${OS}" == 'Debian' ]; then
        apt-get remove squid -y && apt-get autoremove
        rm -rf /etc/squid
    fi
}


start_squid(){
    # 重启Squid
    if [ "${OS}" == 'CentOS' ]; then
        systemctl restart squid
    elif [ "${OS}" == 'Ubuntu' ]; then
        pgrep squid3 |xargs kill -9 && sleep 1 && squid3
    elif [ "${OS}" == 'Debian' ]; then
        service squid restart
    fi
}



install_squid(){
    if [ "${OS}" == 'CentOS' ]; then
        init_sys
        yum_squid
    elif [ "${OS}" == 'Ubuntu' ]; then
        init_sys
        apt_squid
    elif [ "${OS}" == 'Debian' ]; then
        init_sys
        apt_squid
    fi
}




case "${1}" in
  install)
    check_os_type
    install_squid
    ;;
  uninstall)
    check_os_type
    clean_sys
    ;;
  restart)
    check_os_type
    start_squid
    ;;
  *)
    echo "请使用 $0 [install|uninstall|restart] 执行脚本！"
    ;;
esac


# 内核配置参考资料：https://blog.csdn.net/he_jian1/article/details/40787269
# squid参考资料：https://blog.csdn.net/lucien_cc/article/details/7920510
# http://www.squid-cache.org/Versions/v3/3.5/cfgman/

