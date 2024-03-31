#!/bin/bash

##############
#### INIT ####
##############

### VARIABLES ###
easymysql_version=1.2
easymysql_author="WisePlace"

. /etc/EasySite/EasySite_env
easymysql_token="$easysite_bin/EasyMySQL_token.txt"

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
easymysql_connection(){
    if output=$(mysql -h $easymysql_host -u $easymysql_user -p$easymysql_password -e "SELECT 1;" 2>&1)
    then
        echo -e "${BOLD}> ${LGREEN}Connection to MySQL Server successful.${RESET}"
    else
        echo -e "${BOLD}> ${RED}Failed to Connect to MySQL Server: ${LRED}$output${RESET}"
        exit 1
    fi
}

easymysql_database_create(){
    if output=$(mysql -h $easymysql_host -u $easymysql_user -p$easymysql_password -e "CREATE DATABASE $1;" 2>&1)
    then
        echo -e "${BOLD}> ${LGREEN}The database ${LYELLOW}$1 ${LGREEN}has been created.${RESET}"
    else
        echo -e "${BOLD}> ${RED}Failed to create database ${LYELLOW}$1${RED}: ${LRED}$output${RESET}"
    fi
}

easymysql_database_drop(){
    if output=$(mysql -h $easymysql_host -u $easymysql_user -p$easymysql_password -e "DROP DATABASE $1;" 2>&1)
    then
        echo -e "${BOLD}> ${LGREEN}The database ${LYELLOW}$1 ${LGREEN}has been deleted.${RESET}"
    else
        echo -e "${BOLD}> ${RED}Failed to delete database ${LYELLOW}$1${RED}: ${LRED}$output${RESET}"
    fi
}

easymysql_database_show(){
    if output=$(mysql -h $easymysql_host -u $easymysql_user -p$easymysql_password -e "SHOW DATABASES;" 2>&1)
    then
        mysql -h $easymysql_host -u $easymysql_user -p$easymysql_password -e "SHOW DATABASES;"
    else
        echo -e "${BOLD}> ${RED}Failed to display databases: ${LRED}$output${RESET}"
    fi
}

easymysql_database_table_show(){
    if output=$(mysql -h $easymysql_host -u $easymysql_user -p$easymysql_password -e "SHOW TABLES FROM $1;" 2>&1)
    then
        mysql -h $easymysql_host -u $easymysql_user -p$easymysql_password -e "SHOW TABLES FROM $1;"
    else
        echo -e "${BOLD}> ${RED}Failed to display tables of ${LYELLOW}$1${RED}: ${LRED}$output${RESET}"
    fi
}

easymysql_database_backup(){
    if [ "$1" == "*" ]
    then
        output=$(mysqldump -h $easymysql_host -u $easymysql_user -p$easymysql_password --all-databases > $2 2>&1)
        if [ "$output" == "" ]
        then
            echo -e "${BOLD}> ${LGREEN}Backup of all databases has been completed: ${LYELLOW}$2${RESET}"
        else
            echo -e "${BOLD}> ${RED}Failed to backup all databases: ${LRED}$output${RESET}"
        fi
    else
        output=$(mysqldump -h $easymysql_host -u $easymysql_user -p$easymysql_password $1 > $2 2>&1)
        if [ "$output" == "" ]
        then
            echo -e "${BOLD}> ${LGREEN}Backup of the database ${LYELLOW}$1 ${LGREEN}has been completed: ${LYELLOW}$2${RESET}"
        else
            echo -e "${BOLD}> ${RED}Failed to backup database ${LYELLOW}$1${RED}: ${LRED}$output${RESET}"
        fi
    fi
}

easymysql_database_import(){
    if [ "$1" == "*" ]
    then
        if output=$(mysql -h $easymysql_host -u $easymysql_user -p$easymysql_password < $2 2>&1)
        then
            echo -e "${BOLD}> ${LGREEN}Import of all databases has been completed.${RESET}"
        else
            echo -e "${BOLD}> ${RED}Failed to import all databases: ${LRED}$output${RESET}"
        fi
    else
        if output=$(mysql -h $easymysql_host -u $easymysql_user -p$easymysql_password $1 < $2 2>&1)
        then
            echo -e "${BOLD}> ${LGREEN}Import of the database ${LYELLOW}$1 ${LGREEN}has been completed.${RESET}"
        else
            echo -e "${BOLD}> ${RED}Failed to import database ${LYELLOW}$1${RED}: ${LRED}$output${RESET}"
        fi
    fi
}

easymysql_user_create(){
    if [ "$2" == "" ]
    then
        easymysql_user_host="localhost"
    else
        easymysql_user_host=$2
    fi
    if output=$(mysql -h $easymysql_host -u $easymysql_user -p$easymysql_password -e "CREATE USER '$1'@'$easymysql_user_host' IDENTIFIED BY '$3';" 2>&1)
    then
        echo -e "${BOLD}> ${LGREEN}The user ${LCYAN}$1${WHITE}@${LMAGENTA}$easymysql_user_host ${LGREEN}has been created.${RESET}"
    else
        echo -e "${BOLD}> ${RED}Failed to create user ${LCYAN}$1${WHITE}@${LMAGENTA}$easymysql_user_host${RED}: ${LRED}$output${RESET}"
    fi
}

easymysql_user_drop(){
    if [ "$2" == "" ]
    then
        easymysql_user_host="localhost"
    else
        easymysql_user_host=$2
    fi
    if output=$(mysql -h $easymysql_host -u $easymysql_user -p$easymysql_password -e "DROP USER '$1'@'$easymysql_user_host';" 2>&1)
    then
        echo -e "${BOLD}> ${LGREEN}The user ${LCYAN}$1${WHITE}@${LMAGENTA}$easymysql_user_host ${LGREEN}has been deleted.${RESET}"
    else
        echo -e "${BOLD}> ${RED}Failed to delete user ${LCYAN}$1${WHITE}@${LMAGENTA}$easymysql_user_host${RED}: ${LRED}$output${RESET}"
    fi
}

easymysql_user_show(){
    if output=$(mysql -h $easymysql_host -u $easymysql_user -p$easymysql_password -e "SELECT user, host FROM mysql.user;" 2>&1)
    then
        mysql -h $easymysql_host -u $easymysql_user -p$easymysql_password -e "SELECT user, host FROM mysql.user;"
    else
        echo -e "${BOLD}> ${RED}Failed to display users: ${LRED}$output${RESET}"
    fi
}

easymysql_user_grant(){
    if [ "$2" == "" ]
    then
        easymysql_user_host="localhost"
    else
        easymysql_user_host=$2
    fi
    if output=$(mysql -h $easymysql_host -u $easymysql_user -p$easymysql_password -e "GRANT ALL PRIVILEGES ON $3.* TO '$1'@'$easymysql_user_host' WITH GRANT OPTION;" 2>&1)
    then
        echo -e "${BOLD}> ${LGREEN}The user ${LCYAN}$1 ${LGREEN}has been granted permissions on database ${LYELLOW}$3${LGREEN}.${RESET}"
    else
        echo -e "${BOLD}> ${RED}Failed to grant permissions to ${LCYAN}$1${WHITE}@${LMAGENTA}$easymysql_user_host${RED}: ${LRED}$output${RESET}"
    fi
}

easymysql_flush(){
    if output=$(mysql -h $easymysql_host -u $easymysql_user -p$easymysql_password -e "FLUSH PRIVILEGES;" 2>&1)
    then
        return
    else
        echo -e "${BOLD}> ${RED}Failed to flush privileges: ${LRED}$output${RESET}"
    fi
}

easymysql_token_check(){
    if [ -f "$easymysql_token" ]
    then
        . "$easymysql_token"
    else
        touch "$easymysql_token"
        echo "easymysql_session=" >> $easymysql_token
        echo "easymysql_host=" >> $easymysql_token
        echo "easymysql_user=" >> $easymysql_token
        echo "easymysql_password=" >> $easymysql_token
    fi
}

easymysql_session_check(){
    if [ "$easymysql_session" == "True" ]
    then
        easymysql_connection
        easymysql_menu_main
    else
        easymysql_menu_connection
        easymysql_connection
        easymysql_session="True"
        echo "easymysql_session=True" > $easymysql_token
        echo "easymysql_host=$easymysql_host" >> $easymysql_token
        echo "easymysql_user=$easymysql_user" >> $easymysql_token
        echo "easymysql_password=$easymysql_password" >> $easymysql_token
        easymysql_menu_main
    fi
}

easymysql_menu_connection(){
    read -p "$(echo -e "${LCYAN}MySQL Server (Default: ${LYELLOW}localhost${LCYAN}):${RESET} ")" easymysql_host
    read -p "$(echo -e "${LCYAN}Username (Default: ${LYELLOW}root${LCYAN}):${RESET} ")" easymysql_user
    read -p "$(echo -e "${LCYAN}Password:${RESET} ")" easymysql_password
    if [ "$easymysql_host" == "" ]
    then
        easymysql_host="localhost"
    fi
    if [ "$easymysql_user" == "" ]
    then
        easymysql_user="root"
    fi
}

easymysql_menu_main(){
    clear
    while true
    do
        echo " "
        easymysql_database_show
        echo " "
        echo -e "${LCYAN}Main Menu:${RESET}"
        echo -e "${LYELLOW}1. Create Database${RESET}"
        echo -e "${LYELLOW}2. Drop Database${RESET}"
        echo -e "${LYELLOW}3. Show Database Tables${RESET}"
        echo -e "${LYELLOW}4. Backup Database(s)${RESET}"
        echo -e "${LYELLOW}5. Import Database(s)${RESET}"
        echo -e "${LYELLOW}6. Manage Users${RESET}"
        echo -e "${LYELLOW}7. Clear Session${RESET}"
        echo -e "${YELLOW}8. Exit${RESET}"
        echo " "

        read -p "$(echo -e "${LCYAN}Select an option (1-8):${RESET} ")" easymysql_menu_main_choice
        case $easymysql_menu_main_choice in
            1)
                read -p "$(echo -e "${LCYAN}Enter database name to create:${RESET} ")" easymysql_database_name
                clear
                echo " "
                easymysql_database_create "$easymysql_database_name"
                ;;
            2)
                read -p "$(echo -e "${LCYAN}Enter database name to drop:${RESET} ")" easymysql_database_name
                read -p "$(echo -e "${LCYAN}The database ${LYELLOW}$easymysql_database_name ${LCYAN}will be deleted, are you sure ? ${LYELLOW}[Y/n]${LCYAN}:${RESET} ")" choice
                if [ "$choice" == "Y" ] || [ "$choice" == "y" ]
                then
                    clear
                    echo " "
                    easymysql_database_drop "$easymysql_database_name"
                else
                    easymysql_menu_main
                fi
                ;;
            3)
                read -p "$(echo -e "${LCYAN}Enter database name:${RESET} ")" easymysql_database_name
                clear
                echo " "
                easymysql_database_table_show "$easymysql_database_name"
                ;;
            4)
                read -p "$(echo -e "${LCYAN}Enter database name to backup (${LYELLOW}* for all${LCYAN}):${RESET} ")" easymysql_database_name
                if [ "$easymysql_database_name" == "*" ]
                then
                    temp="full_backup"
                else
                    temp="$easymysql_database_name"
                fi
                read -p "$(echo -e "${LCYAN}Enter backup file name (Default: ${LYELLOW}$temp.sql${LCYAN}):${RESET} ")" easymysql_backup_File
                if [ "$easymysql_backup_File" == "" ]
                then
                    easymysql_backup_File="$temp.sql"
                fi
                clear
                echo " "
                easymysql_database_backup "$easymysql_database_name" "$easymysql_backup_File"
                ;;
            5)
                read -p "$(echo -e "${LCYAN}Enter database name to import (${LYELLOW}* for all${LCYAN}):${RESET} ")" easymysql_database_name
                if [ "$easymysql_database_name" == "*" ]
                then
                    temp="full_backup"
                else
                    temp="$easymysql_database_name"
                fi
                read -p "$(echo -e "${LCYAN}Enter backup file name (Default: ${LYELLOW}$temp.sql${LCYAN}):${RESET} ")" easymysql_backup_File
                if [ "$easymysql_backup_File" == "" ]
                then
                    easymysql_backup_File="$temp.sql"
                fi
                clear
                echo " "
                easymysql_database_import "$easymysql_database_name" "$easymysql_backup_File"
                ;;
            6)
                easymysql_menu_user
                ;;
            7)
                echo "easymysql_session=" > "$easymysql_token"
                echo "easymysql_host=" >> "$easymysql_token"
                echo "easymysql_host=" >> "$easymysql_token"
                echo "easymysql_host=" >> "$easymysql_token"
                exit 0
                ;;
            8)
                echo -e "${LMAGENTA}Exiting.${RESET}"
                exit 0
                ;;
            *)
                clear
                echo " "
                echo -e "${BOLD}> ${LRED}Invalid option. Please enter a number from 1 to 8.${RESET}"
                ;;
        esac
    done
}

easymysql_menu_user(){
    clear
    while true
    do
        echo " "
        easymysql_user_show
        echo " "
        echo -e "${LCYAN}User Management Menu:${RESET}"
        echo -e "${LYELLOW}1. Create User${RESET}"
        echo -e "${LYELLOW}2. Drop User${RESET}"
        echo -e "${LYELLOW}3. Grant Permissions${RESET}"
        echo -e "${YELLOW}4. Back to Main Menu${RESET}"
        echo " "

        read -p "$(echo -e "${LCYAN}Select an option (1-4): ${RESET}")" easymysql_menu_user_choice
        case $easymysql_menu_user_choice in
            1)
                read -p "$(echo -e "${LCYAN}Enter username: ${RESET}")" easymysql_user_name
                read -p "$(echo -e "${LCYAN}Enter host (Default: ${LYELLOW}localhost${LCYAN}):${RESET} ")" easymysql_user_host
                if [ "$easymysql_user_host" == "" ]
                then
                    easymysql_user_host="localhost"
                fi
                read -p "$(echo -e "${LCYAN}Enter password:${RESET} ")" easymysql_user_password
                clear
                echo " "
                easymysql_user_create "$easymysql_user_name" "$easymysql_user_host" "$USER_Password"
                ;;
            2)
                read -p "$(echo -e "${LCYAN}Enter username:${RESET} ")" easymysql_user_name
                read -p "$(echo -e "${LCYAN}Enter host (Default: ${LYELLOW}localhost${LCYAN}):${RESET} ")" easymysql_user_host
                if [ "$easymysql_user_host" == "" ]
                then
                    easymysql_user_host="localhost"
                fi
                clear
                echo " "
                easymysql_user_drop "$easymysql_user_name" "$easymysql_user_host"
                ;;
            3)
                read -p "$(echo -e "${LCYAN}Enter username:${RESET} ")" easymysql_user_name
                read -p "$(echo -e "${LCYAN}Enter host (Default: ${LYELLOW}localhost${LCYAN}):${RESET} ")" easymysql_user_host
                if [ "$easymysql_user_host" == "" ]
                then
                    easymysql_user_host="localhost"
                fi
                read -p "$(echo -e "${LCYAN}Enter database name (${LCYELLOW}* for all${LCYAN}):${RESET} ")" easymysql_database_name
                clear
                echo " "
                easymysql_user_grant "$easymysql_user_name" "$easymysql_user_host" "$easymysql_database_name"
                ;;
            4)
                clear
                echo " "
                echo -e "${BOLD}> ${LCYAN}Returning to Main Menu.${RESET}"
                return
                ;;
            *)
                clear
                echo " "
                echo -e "${BOLD}> ${LRED}Invalid option. Please enter a number from 1 to 5.${RESET}"
                ;;
        esac
    done
}

#################
### EXECUTION ###
#################

### OPTIONS ###
if [ "$1" == "" ] || [ "$1" == " " ]
then
    bin="True"
elif [ "$1" == "version" ] || [ "$1" == "-v" ] || [ "$1" == "--v" ] || [ "$1" == "--version" ]
then
    echo -e "${LCYAN}EasyMySQL ${LBLUE}V$easymysql_version${RESET}"
    exit 0
elif [ "$1" == "version-raw" ]
then
    echo "$easymysql_version"
    exit 0
elif [ "$1" == "help" ] || [ "$1" == "-h" ] || [ "$1" == "--h" ] || [ "$1" == "--help" ]
then
    echo ""
    echo -e "${LCYAN}Usage: ${MAGENTA}EasySite mysql [${BLUE}options${MAGENTA}]${RESET}"
    echo ""
    echo -e "${LCYAN}Options:${RESET}"
    echo -e "${BLUE}help      ${YELLOW}Display commands${RESET}"
    echo -e "${BLUE}version   ${YELLOW}Show current Version${RESET}"
    echo ""
    exit 0
else
     echo -e "${RED}Unknown argument: ${LRED}Do ${MAGENTA}EasySite mysql help ${LRED}for more informations.${RESET}"
    exit 1
fi
### GLOBAL ###
easymysql_token_check
easymysql_session_check