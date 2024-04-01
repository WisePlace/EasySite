#!/bin/bash

##############
#### INIT ####
##############

### VARIABLES ###
easysite_version=0.22
author="WisePlace"

easysite_etc="/etc/EasySite"
easysite_conf="$easysite_etc/EasySite.conf"
easysite_modules="$easysite_etc/modules"
easysite_bin="$easysite_etc/bin"
easysite_templates="$easysite_etc/templates"
easysite_env="$easysite_etc/EasySite_env"

main_source="https://web.luka-laurent.fr/EasySite"

IP=$(hostname -I)
local_mysql="None"

#### COLORS ####
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
LGRAY="\e[37m"
GRAY="\e[90m"
LRED="\e[91m"
LGREEN="\e[92m"
LYELLOW="\e[93m"
LBLUE="\e[94m"
LMAGENTA="\e[95m"
LCYAN="\e[96m"
WHITE="\e[97m"
RESET="\e[0m"
BOLD="\e[1m"

### FUNCTIONS ###
os_check(){
    . /etc/os-release
    if [ "$ID" == "debian" ] || [ "$ID" == "ubuntu" ]
    then
        echo -e "${LCYAN}Current OS: $ID $VERSION_ID${RESET}"
        echo -e "${LGREEN}OS is compatible.${RESET}"
    else
        echo -e "${LCYAN}Current OS: $ID $VERSION_ID${RESET}"
        echo -e "${RED}OS is not compatible.${RESET}"
        echo -e "${MAGENTA}Exiting..${RESET}"
        exit 1
    fi
}

apache_check(){
    if systemctl status apache2 >/dev/null 2>&1
    then
        echo -e "${LCYAN}Apache2 already installed.${RESET}"
    else
        echo -e "${YELLOW}Apache2 not installed.${RESET}"
        echo -e "${LMAGENTA}Installing Apache2..${RESET}"
        if output=$(apt install apache2 php -y >/dev/null 2>&1)
        then
            echo -e "${LGREEN}Apache2 successfully installed.${RESET}"
            systemctl enable apache2 >/dev/null 2>&1
            systemctl start apache2 >/dev/null 2>&1
            return
        else
            echo -e "${RED}Failed to install Apache2: ${LRED}$output${RESET}"
            exit 1
        fi
    fi
}

mysql_check(){
    if [ "$local_mysql" == "True" ] || [ "$local_mysql" == "None" ]
    then
        if systemctl status mysql >/dev/null 2>&1
        then
            echo -e "${LCYAN}MariaDB already installed.${RESET}"
        else
            echo -e "${YELLOW}MariaDB not installed.${RESET}"
            read -p "$(echo -e "${BLUE}Do you wish to install MariaDB ? [${GREEN}Y${LBLUE}/${LRED}n${BLUE}]:${RESET} ")" mysql_check_choice
            if [ "$mysql_check_choice" == "Y" ] || [ "$mysql_check_choice" == "y" ] || [ "$mysql_check_choice" == "" ]
            then
                local_mysql="True"
                echo -e "${LMAGENTA}Installing MariaDB..${RESET}"
                if output=$(apt install mariadb-server -y >/dev/null 2>&1)
                then
                    echo -e "${LGREEN}MariaDB successfully installed.${RESET}"
                    systemctl enable mariadb >/dev/null 2>&1
                    systemctl start mariadb >/dev/null 2>&1
                    return
                else
                    echo -e "${RED}Failed to install MariaDB: ${LRED}$output${RESET}"
                    exit 1
                fi
            else
                local_mysql="False"
                return
            fi
        fi
    fi
}

easysite_check(){
    if [ -d "$easysite_etc" ]
    then
        echo -e "${LCYAN}EasySite already installed.${RESET}"
	echo -e "${LMAGENTA}Checking for updates..${RESET}"
        wget -qO "$easysite_bin/EasyMySQL.sh" "$main_source/modules/EasyMySQL.sh" >/dev/null 2>&1
	wget -qO "$easysite_bin/EasyApache.sh" "$main_source/modules/EasyApache.sh" >/dev/null 2>&1
        wget -qO "$easysite_bin/EasySite.sh" "$main_source/EasySite.sh" >/dev/null 2>&1
	easymysql_latest_version=$(awk -F 'easymysql_version=' '/easymysql_version/{print $2;exit}' $easysite_bin/EasyMySQL.sh | awk -F "'" '{print $1}')
        easyapache_latest_version=$(awk -F 'easyapache_version=' '/easyapache_version/{print $2;exit}' $easysite_bin/EasyApache.sh | awk -F "'" '{print $1}')
        easysite_latest_version=$(awk -F 'easysite_version=' '/easysite_version/{print $2;exit}' $easysite_bin/EasySite.sh | awk -F "'" '{print $1}')
	easymysql_version=$(EasySite mysql version-raw)
        easyapache_version=$(EasySite apache version-raw)
	easysite_version=$(EasySite version-raw)
	rm "$easysite_bin/EasyMySQL.sh"
        rm "$easysite_bin/EasyApache.sh"
	rm "$easysite_bin/EasySite.sh"
        if (( $(echo "$easymysql_version < $easymysql_latest_version" | bc -l) ))
	then
            rm "$easysite_modules/EasyMySQL.sh"
            wget -O "$easysite_modules/EasyMySQL.sh" "$main_source/modules/EasyMySQL.sh" >/dev/null 2>&1 || { echo -e "${LRED}Error while downloading EasyMySQL update.${RESET}"; exit 1; }
	    chmod +x "$easysite_modules/EasyMySQL.sh"
	    echo -e "${LGREEN}EasyMySQL module successfully updated from ${LYELLOW}V$easymysql_version ${LGREEN}to ${LYELLOW}V$easymysql_latest_version${LGREEN}.${RESET}"
	fi
        if (( $(echo "$easyapache_version < $easyapache_latest_version" | bc -l) ))
	then
            rm "$easysite_modules/EasyApache.sh"
            wget -O "$easysite_modules/EasyApache.sh" "$main_source/modules/EasyApache.sh" >/dev/null 2>&1 || { echo -e "${LRED}Error while downloading EasyApache update.${RESET}"; exit 1; }
	    chmod +x "$easysite_modules/EasyApache.sh"
	    echo -e "${LGREEN}EasyApache module successfully updated from ${LYELLOW}V$easyapache_version ${LGREEN}to ${LYELLOW}V$easyapache_latest_version${LGREEN}.${RESET}"
	fi
        if (( $(echo "$easysite_version < $easysite_latest_version" | bc -l) ))
	then
            rm "$easysite_etc/EasySite.sh"
            wget -O "$easysite_etc/EasySite.sh" "$main_source/EasySite.sh" >/dev/null 2>&1 || { echo -e "${LRED}Error while downloading EasySite update.${RESET}"; exit 1; }
	    chmod +x "$easysite_etc/EasySite.sh"
	    echo -e "${LGREEN}EasySite successfully updated from ${LYELLOW}V$easysite_version ${LGREEN}to ${LYELLOW}V$easysite_latest_version${LGREEN}.${RESET}"
            cp -f "$easysite_etc/EasySite.sh" "$0"
	fi
        echo -e "${LCYAN}Up to Date.${RESET}"
    else
        echo -e "${YELLOW}EasySite not installed.${RESET}"
        echo -e "${LMAGENTA}Installing EasySite..${RESET}"
        mkdir -p "$easysite_modules" "$easysite_bin" "$easysite_templates"
        touch "$easysite_conf"
        echo "local_mysql=$local_mysql" >> "$easysite_conf"
	wget -O "$easysite_etc/EasySite_env" "$main_source/bin/EasySite_env" >/dev/null 2>&1 || { echo -e "${LRED}Error while downloading EasySite environment variables.${RESET}"; exit 1; }
        cp -f "$0" "$easysite_etc/EasySite.sh"
        ln -f -s "$easysite_etc/EasySite.sh" "/usr/local/bin/EasySite"
        wget -O "$easysite_modules/EasyMySQL.sh" "$main_source/modules/EasyMySQL.sh" >/dev/null 2>&1 || { echo -e "${LRED}Error while downloading EasyMySQL module.${RESET}"; exit 1; }
        chmod +x "$easysite_modules/EasyMySQL.sh"
        wget -O "$easysite_modules/EasyApache.sh" "$main_source/modules/EasyApache.sh" >/dev/null 2>&1 || { echo -e "${LRED}Error while downloading EasyApache module.${RESET}"; exit 1; }
        chmod +x "$easysite_modules/EasyApache.sh"
        echo -e "${LGREEN}EasySite successfully installed.${RESET}"
    fi
}

#################
### EXECUTION ###
#################

#### SUDO ####
if [ "$(id -u)" != "0" ]
then
    echo -e "${CYAN}This script must be run by root or with sudo.${RESET}" >&2
    exit 1
fi

### OPTIONS ###
if [ "$1" == "" ] || [ "$1" == " " ]
then
    bin="True"
elif [ "$1" == "remove" ]
then
    if [ -d "$easysite_etc" ]
    then
        rm -r "$easysite_etc"
        rm -r "/usr/local/bin/EasySite"
        echo -e "${LMAGENTA}Uninstalling EasySite..${RESET}"
        echo -e "${BLUE}EasySite successfully removed.${RESET}"
    else
        echo -e "${LCYAN}EasySite is currently not installed.${RESET}"
    fi
    exit 0
elif [ "$1" == "apache" ] || [ "$1" == "APACHE" ] || [ "$1" == "Apache" ] || [ "$1" == "apache2" ] || [ "$1" == "APACHE2" ] || [ "$1" == "Apache2" ]
then
    $easysite_modules/EasyApache.sh
    exit 0
elif [ "$1" == "mysql" ] || [ "$1" == "MySQL" ] || [ "$1" == "Mysql" ] || [ "$1" == "mySQL" ] || [ "$1" == "MYSQL" ]
then
    $easysite_modules/EasyMySQL.sh
    exit 0
elif [ "$1" == "help" ] || [ "$1" == "-h" ] || [ "$1" == "--h" ] || [ "$1" == "--help" ]
then
    echo ""
    echo -e "${LCYAN}Usage: ${MAGENTA}EasySite [${BLUE}options${MAGENTA}]${RESET}"
    echo ""
    echo -e "${LCYAN}Options:${RESET}"
    echo -e "${BLUE}help      ${YELLOW}Display commands${RESET}"
    echo -e "${BLUE}version   ${YELLOW}Show current Version${RESET}"
    echo -e "${BLUE}apache    ${YELLOW}Start Apache2 module${RESET}"
    echo -e "${BLUE}mysql     ${YELLOW}Start MySQL module${RESET}"
    echo -e "${BLUE}remove    ${YELLOW}Uninstall EasySite${RESET}"
    echo ""
    exit 0
elif [ "$1" == "version" ] || [ "$1" == "-v" ] || [ "$1" == "--v" ] || [ "$1" == "--version" ]
then
    echo -e "${LCYAN}EasySite ${LBLUE}V$easysite_version${RESET}"
    exit 0
elif [ "$1" == "version-raw" ]
then
    echo "$easysite_version"
    exit 0
else
    echo -e "${RED}Unknown argument: ${LRED}Do ${MAGENTA}EasySite help ${LRED}for more informations.${RESET}"
    exit 1
fi

### GLOBAL ###
. "$easysite_conf" >/dev/null 2>&1

os_check
apache_check
mysql_check
easysite_check
