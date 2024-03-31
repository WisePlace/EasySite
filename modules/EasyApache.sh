#!/bin/bash

##############
#### INIT ####
##############

### VARIABLES ###
easyapache_version=0.8
easyapache_author="WisePlace"

. /etc/EasySite/EasySite_env

### FUNCTIONS ###
easyapache_site_list_show(){
    apache_en_list=($(ls "$apache_en_dir"))
    apache_av_list=($(ls "$apache_av_dir"))
    for site in "${apache_av_list[@]}"
    do
        easyapache_site_status_get "${site}"
        if [ "$easyapache_site_status" == "enabled" ]
        then
            echo -e "> ${YELLOW}$site ${LCYAN}- ${LGREEN}$easyapache_site_status${RESET}"
        else
            echo -e "> ${YELLOW}$site ${LCYAN}- ${LRED}$easyapache_site_status${RESET}"
        fi
    done
}

easyapache_site_status_get(){ #$easyapache_site_file
    if [ -e "$apache_av_dir/$1" ] && [ -e "$apache_en_dir/$1" ]
    then
        easyapache_site_status="enabled"
    else
        easyapache_site_status="disabled"
    fi
}

easyapache_site_status_switch(){ #$easyapache_site_file
    easyapache_site_name="${1%.conf}"
    if easysite_file_check "$apache_av_dir/$1"
    then
        easyapache_site_status_get "$1"
        if [ "$easyapache_site_status" == "enabled" ]
        then
            a2dissite "$1" >/dev/null 2>&1
            if easysite_service_reload "apache2"
            then
                echo -e "${BOLD}> ${LGREEN}The site ${LYELLOW}$easyapache_site_name ${LGREEN}has been disabled.${RESET}"
            else
                echo -e "${RED}Failed to reload apache: ${LRED}$output${RESET}"
            fi
        else
            a2ensite "$1" >/dev/null 2>&1
            if easysite_service_reload "apache2"
            then
                echo -e "${BOLD}> ${LGREEN}The site ${LYELLOW}$easyapache_site_name ${LGREEN}has been enabled.${RESET}"
            else
                echo -e "${RED}Failed to reload apache: ${LRED}$output${RESET}"
            fi
        fi
    else
        echo -e "${BOLD}> ${LRED}This site doesn't exists.${RESET}"
    fi
}

easyapache_site_create(){ #$easyapache_site_file $easyapache_site_DocumentRoot $easyapache_site_ServerName $easyapache_site_Alias
    easyapache_site_name="${easyapache_site_file%.conf}"
    if easysite_file_check "$apache_av_dir/$1"
    then
        echo -e "${BOLD}> ${LRED}This site already exists.${RESET}"
    else
        echo "<VirtualHost *:80>" >> "$apache_av_dir/$1"
        echo "        DocumentRoot $2" >> "$apache_av_dir/$1"
        echo "        ServerName $3" >> "$apache_av_dir/$1"
        echo " " >> "$apache_av_dir/$1"
        echo '        ErrorLog ${APACHE_LOG_DIR}/html_error.log' >> "$apache_av_dir/$1"
        echo '        CustomLog ${APACHE_LOG_DIR}/html_access.log combined' >> "$apache_av_dir/$1"
        if [ "$4" != "/n" ]
        then
            echo " " >> "$apache_av_dir/$1"
            echo '        $4 $2' >> "$apache_av_dir/$1"
        fi
        echo "</VirtualHost>" >> "$apache_av_dir/$1"
        if ! easysite_dir_check "$easyapache_site_DocumentRoot"
        then
            easysite_dir_create "$easyapache_site_DocumentRoot"
        fi
        echo -e "${BOLD}> ${LGREEN}The site ${LYELLOW}$easyapache_site_name ${LGREEN}has been created.${RESET}"
    fi
}

easyapache_site_delete(){ #$easyapache_site_file
    easyapache_site_name="${easyapache_site_file%.conf}"
    easyapache_site_DocumentRoot=$(grep 'DocumentRoot' "$apache_av_dir/$easyapache_site_file" 2>/dev/null | awk '{print $2}')
    if easysite_file_check "$apache_av_dir/$1"
    then
        easysite_file_delete "$apache_av_dir/$1" 2>&1
        easysite_file_delete "$apache_en_dir/$1" 2>&1
        easysite_dir_delete "$easyapache_site_DocumentRoot" 2>&1
        echo -e "${BOLD}> ${LGREEN}The site ${LYELLOW}$easyapache_site_name ${LGREEN}has been deleted.${RESET}"
    else
        echo -e "${RED}Failed to delete site: ${LRED}This site doesn't exists.${RESET}"
    fi
}

easyapache_site_get(){ #$easyapache_site_file
    easyapache_site_name="${easyapache_site_file%.conf}"
    easysite_site="$apache_av_dir/$1"
    easyapache_site_DocumentRoot=$(grep 'DocumentRoot' "$easysite_site" 2>/dev/null | awk '{print $2}')
    easyapache_site_ServerName=$(grep 'ServerName' "$easysite_site" 2>/dev/null | awk '{print $2}')
    easyapache_site_ErrorLog=$(grep 'ErrorLog' "$easysite_site" 2>/dev/null | awk '{print $2}')
    easyapache_site_CustomLog=$(grep 'CustomLog' "$easysite_site" 2>/dev/null | awk '{print $2}')
    temp=$(grep -i 'SSLEngine' "$easysite_site")
    easyapache_site_SSLEngine=$(echo "$temp" 2>/dev/null | cut -d' ' -f2)
    easyapache_site_SSLCertificateFile=$(grep -i 'SSLCertificateFile' "$easysite_site" 2>/dev/null | awk '{print $2}')
    easyapache_site_SSLCertificateKeyFile=$(grep -i 'SSLCertificateKeyFile' "$easysite_site" 2>/dev/null | awk '{print $2}')
    easyapache_site_Alias=$(grep -iE 'Alias\s+(/\S+)' "$easysite_site" 2>/dev/null | awk '{print $2}')
    easyapache_site_AliasDir=$(grep -iE 'Alias\s+(/\S+)\s+(\S+)' "$easysite_site" 2>/dev/null | awk '{print $3}')
}

easyapache_site_show(){ #$easyapache_site_file
    if easysite_file_check "$apache_av_dir/$1"
    then
        easyapache_site_get "$1"
        echo -e "> ${LMAGENTA}Configuration file: ${YELLOW}$easyapache_site_file${RESET}"
        echo -e "> ${LMAGENTA}Site files Directory: ${YELLOW}$easyapache_site_DocumentRoot${RESET}"
        echo -e "> ${LMAGENTA}Site URL: ${YELLOW}$easyapache_site_ServerName${RESET}"
        echo " "
        echo -e "> ${LMAGENTA}File for error logs: ${YELLOW}$easyapache_site_ErrorLog${RESET}"
        echo -e "> ${LMAGENTA}File for custom logs: ${YELLOW}$easyapache_site_CustomLog${RESET}"
        if [ "$easyapache_site_SSLEngine" != "" ] && [ "$easyapache_site_SSLEngine" != " " ]
        then
            echo " "
            echo -e "> ${LMAGENTA}SSL: ${YELLOW}$easyapache_site_SSLEngine${RESET}"
            echo -e "> ${LMAGENTA}SSL certificate: ${YELLOW}$easyapache_site_SSLCertificateFile${RESET}"
            echo -e "> ${LMAGENTA}SSL key: ${YELLOW}$easyapache_site_SSLCertificateKeyFile${RESET}"
        fi
        if [ "$easyapache_site_Alias" != "" ] && [ "$easyapache_site_Alias" != " " ]
        then
            echo " "
            echo -e "> ${LMAGENTA}Site alias: ${YELLOW}$easyapache_site_Alias${RESET}"
            echo -e "> ${LMAGENTA}Site alias directory: ${YELLOW}$easyapache_site_AliasDir${RESET}"
        fi
    else
        echo -e "${RED}Failed to get site informations: ${LRED}This site doesn't exists.${RESET}"
    fi
}


easyapache_site_enable_ssl(){ #$easyapache_site_file
    echo "Yes"
}

easyapache_menu_main(){
    clear
    while true
    do
        echo " "
        easyapache_site_list_show
        echo " "
        echo -e "${LCYAN}Main Menu:${RESET}"
        echo -e "${LYELLOW}1. Create Site${RESET}"
        echo -e "${LYELLOW}2. Delete Site${RESET}"
        echo -e "${LYELLOW}3. Modify Site${RESET}"
        echo -e "${LYELLOW}4. Enable/Disable Site${RESET}"
        echo -e "${LYELLOW}5. Show Site infos${RESET}"
        echo -e "${YELLOW}6. Exit${RESET}"
        echo " "

        read -p "$(echo -e "${LCYAN}Select an option (1-6):${RESET} ")" easyapache_menu_main_choice
        case $easyapache_menu_main_choice in
            1)
                read -p "$(echo -e "${LCYAN}Enter site name to create:${RESET} ")" easyapache_site_file
                if [ "$easyapache_site_file" == "" ] || [ "$easyapache_site_file" == " " ] || [ "$easyapache_site_file" == " .conf" ] || [ "$easyapache_site_file" == ".conf" ]
                then
                    clear
                    echo " "
                    echo -e "${RED}Site name can't be empty.${RESET}"
                elif [[ "$easyapache_site_file" == *.conf ]]
                then
                    easyapache_site_name="${easyapache_site_file%.conf}"
                else
                    easyapache_site_name="$easyapache_site_file"
                    easyapache_site_file="$easyapache_site_file.conf"
                fi
                read -p "$(echo -e "${LCYAN}Enter site Files Directory (Default: ${LYELLOW}/var/www/html/$easyapache_site_name${LCYAN}):${RESET} ")" easyapache_site_DocumentRoot
                if [ "$easyapache_site_DocumentRoot" == "" ]
                then
                    easyapache_site_DocumentRoot="/var/www/html/$easyapache_site_name"
                fi
                read -p "$(echo -e "${LCYAN}Enter site URL (Default: ${LYELLOW}$IP${LCYAN}):${RESET} ")" easyapache_site_ServerName
                if [ "$easyapache_site_ServerName" == "" ]
                then
                    easyapache_site_ServerName="$IP"
                fi
                read -p "$(echo -e "${LCYAN}Enter site Alias (Default: ${LYELLOW}/$easyapache_site_name${LCYAN}) (${LYELLOW}n for None${LCYAN}):${RESET} ")" easyapache_site_Alias
                if [ "$easyapache_site_Alias" == "" ]
                then
                    easyapache_site_Alias="/$easyapache_site_name"
                fi
                clear
                echo " "
                easyapache_site_create "$easyapache_site_file" "$easyapache_site_DocumentRoot" "$easyapache_site_ServerName" "$easyapache_site_Alias"
                ;;
            2)
                read -p "$(echo -e "${LCYAN}Enter site name to delete:${RESET} ")" easyapache_site_file
                if [[ "$easyapache_site_file" == *.conf ]]
                then
                    easyapache_site_name="${easyapache_site_file%.conf}"
                else
                    easyapache_site_name="$easyapache_site_file"
                    easyapache_site_file="$easyapache_site_file.conf"
                fi
                read -p "$(echo -e "${LCYAN}The site ${LYELLOW}$easyapache_site_name ${LCYAN}will be deleted, are you sure ? ${LYELLOW}[Y/n]${LCYAN}:${RESET} ")" choice
                if [ "$choice" == "Y" ] || [ "$choice" == "y" ]
                then
                    clear
                    echo " "
                    easyapache_site_delete "$easyapache_site_file"
                else
                    easyapache_menu_main
                fi
                ;;
            3)
                read -p "$(echo -e "${LCYAN}Enter site name to modify:${RESET} ")" easyapache_site_file
                if [[ "$easyapache_site_file" != *.conf ]]
                then
                    easyapache_site_file="$easyapache_site_file.conf"
                fi
                if easysite_file_check "$apache_av_dir/$easyapache_site_file"
                then
                    easyapache_menu_modify "$easyapache_site_file"
                else
                    clear
                    echo " "
                    echo -e "${RED}Failed to modify site: ${LRED}This site doesn't exists.${RESET}"
                fi
                ;;
            4)
                read -p "$(echo -e "${LCYAN}Enter site name to enable/disable:${RESET} ")" easyapache_site_file
                if [[ "$easyapache_site_file" != *.conf ]]
                then
                    easyapache_site_file="$easyapache_site_file.conf"
                fi
                clear
                echo " "
                easyapache_site_status_switch "$easyapache_site_file"
                ;;
            5)
                read -p "$(echo -e "${LCYAN}Enter site name to display its informations:${RESET} ")" easyapache_site_file
                if [[ "$easyapache_site_file" != *.conf ]]
                then
                    easyapache_site_file="$easyapache_site_file.conf"
                fi
                clear
                echo " "
                easyapache_site_show "$easyapache_site_file"
                ;;
            6)
                echo -e "${LMAGENTA}Exiting.${RESET}"
                exit 0
                ;;
            *)
                clear
                echo " "
                echo -e "${BOLD}> ${LRED}Invalid option. Please enter a number from 1 to 6.${RESET}"
                ;;
        esac
    done
}

easyapache_menu_modify(){ #$easyapache_site_file
    clear
    while true
    do
        easyapache_site_status_get "$1"
        echo " "
        easyapache_site_show "$1"
        echo " "
        echo -e "${LCYAN}Site Management Menu:${RESET}"
        echo -e "${LYELLOW}1. Configuration File${RESET}"
        echo -e "${LYELLOW}2. Files directory${RESET}"
        echo -e "${LYELLOW}3. URL${RESET}"
        if [ "$easyapache_site_SSLEngine" == "on" ] || [ "$easyapache_site_SSLEngine" == "On" ] || [ "$easyapache_site_SSLEngine" == "ON" ]
        then
            bin="true"
            echo -e "${LYELLOW}4. SSL Certificate Path${RESET}"
            echo -e "${LYELLOW}5. SSL Key Path${RESET}"
            if [ "$easyapache_site_status" == "enabled" ]
            then
                echo -e "${LYELLOW}6. Disable Site${RESET}"
            else
                echo -e "${LYELLOW}6. Enable Site${RESET}"
            fi
            echo -e "${LYELLOW}7. Open in File Editor${RESET}"
            echo -e "${YELLOW}8. Back${RESET}"
        else
            bin="fulse"
            echo -e "${LYELLOW}4. Enable SSL${RESET}"
            if [ "$easyapache_site_status" == "enabled" ]
            then
                echo -e "${LYELLOW}5. Disable Site${RESET}"
            else
                echo -e "${LYELLOW}5. Enable Site${RESET}"
            fi
            echo -e "${LYELLOW}6. Open in File Editor${RESET}"
            echo -e "${YELLOW}7. Back${RESET}"
        fi
        echo " "
        read -p "$(echo -e "${LCYAN}Select an option to modify(1-6):${RESET} ")" easyapache_menu_modify_choice
        case $easyapache_menu_modify_choice in
            1)
                clear
                echo " "
                echo "Coming next update.."
                ;;
            2)
                clear
                echo " "
                echo "Coming next update.."
                ;;
            3)
                clear
                echo " "
                echo "Coming next update.."
                ;;
            4)
                if [ "$bin" == "true" ]
                then
                    clear
                    echo " "
                    echo "Coming next update.."
                else
                    clear
                    echo " "
                    echo "Coming next update.."
                fi
                ;;
            5)
                if [ "$bin" == "true" ]
                then
                    clear
                    echo " "
                    echo "Coming next update.."
                else
                    clear
                    echo " "
                    echo "Coming next update.."
                fi
                ;;
            6)
                if [ "$bin" == "true" ]
                then
                    clear
                    echo " "
                    echo "Coming next update.."
                else
                    clear
                    echo " "
                    echo "Coming next update.."
                fi
                ;;
            7)
                if [ "$bin" == "true" ]
                then
                    clear
                    echo " "
                    echo "Coming next update.."
                else
                    easyapache_menu_main
                fi
                ;;
            8)
                if [ "$bin" == "true" ]
                then
                    easyapache_menu_main
                else
                    clear
                    echo " "
                    echo -e "${BOLD}> ${LRED}Invalid option. Please enter a number from 1 to 7.${RESET}"
                fi
                ;;
            *)
                if [ "$bin" == "true" ]
                then
                    clear
                    echo " "
                    echo -e "${BOLD}> ${LRED}Invalid option. Please enter a number from 1 to 8.${RESET}"
                else
                    clear
                    echo " "
                    echo -e "${BOLD}> ${LRED}Invalid option. Please enter a number from 1 to 7.${RESET}"
                fi
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
    echo -e "${LCYAN}EasyApache ${LBLUE}V$easyapache_version${RESET}"
    exit 0
elif [ "$1" == "version-raw" ]
then
    echo "$easyapache_version"
    exit 0
elif [ "$1" == "help" ] || [ "$1" == "-h" ] || [ "$1" == "--h" ] || [ "$1" == "--help" ]
then
    echo ""
    echo -e "${LCYAN}Usage: ${MAGENTA}EasySite apache [${BLUE}options${MAGENTA}]${RESET}"
    echo ""
    echo -e "${LCYAN}Options:${RESET}"
    echo -e "${BLUE}help      ${YELLOW}Display commands${RESET}"
    echo -e "${BLUE}version   ${YELLOW}Show current Version${RESET}"
    echo ""
    exit 0
else
    echo -e "${RED}Unknown argument: ${LRED}Do ${MAGENTA}EasySite apache help ${LRED}for more informations.${RESET}"
    exit 1
fi

### GLOBAL ###
easyapache_menu_main
