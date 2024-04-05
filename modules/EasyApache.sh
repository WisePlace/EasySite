#!/bin/bash

##############
#### INIT ####
##############

### VARIABLES ###
easyapache_version=1.03
easyapache_author="WisePlace"

. /etc/EasySite/EasySite_env

### FUNCTIONS ###

easyapache_check(){
    if systemctl status apache2 >/dev/null 2>&1
    then
        return 0
    else
        echo -e "${YELLOW}Apache2 not installed.${RESET}"
        read -p "$(echo -e "${BLUE}Do you wish to install Apache2 ? [${GREEN}Y${LBLUE}/${LRED}n${BLUE}]:${RESET} ")" choice
        if [ "$choice" == "Y" ] || [ "$choice" == "y" ] || [ "$choice" == "" ]
        then
            echo -e "${LMAGENTA}Installing Apache2..${RESET}"
            if output=$(sudo apt install apache2 php -y >/dev/null 2>&1)
            then
                echo -e "${LGREEN}Apache2 successfully installed.${RESET}"
                systemctl enable apache2 >/dev/null 2>&1
                systemctl start apache2 >/dev/null 2>&1
                return
            else
	            sources_lines=$(wc -l < "/etc/apt/sources.list")
	            if [ "$sources_lines" == "1" ]
                then
	                echo -e "${RED}Failed to install Apache2: ${LRED}Your Linux sources seem wrong.${RESET}"
	                read -p "$(echo -e "${BLUE}Do you want to repear them using WisePlace tools ? [${GREEN}Y${LBLUE}/${LRED}n${BLUE}]:${RESET} ")" choice
	                if [ "$choice" == "Y" ] || [ "$choice" == "y" ] || [ "$choice" == "" ]
	                then
	                    echo -e "${LYELLOW}Getting Linux sources tool..${RESET}"
	                    wget --no-check-certificate -qO "/etc/apt/linux_sources.sh" "https://raw.githubusercontent.com/WisePlace/Tools/main/linux_sources.sh" >/dev/null 2>&1 || { echo -e "${LRED}Error while downloading linux sources tool.${RESET}"; exit 1; }
	                    sudo chmod +x "/etc/apt/linux_sources.sh" >/dev/null 2>&1
	                    . /etc/apt/linux_sources.sh
	                    . EasySite.sh
	                else
		            echo -e "${LMAGENTA}Exiting.${RESET}"
	                    exit 1
	                fi
	            else
                    echo -e "${RED}Failed to install Apache2: ${LRED}$output${RESET}"
                    echo -e "${LMAGENTA}Exiting.${RESET}"
                    exit 1
	            fi
            fi
        else
            echo -e "${LMAGENTA}Exiting.${RESET}"
            exit 0
        fi
    fi
}

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

easyapache_site_status_get(){
    if [ -e "$apache_av_dir/$1" ] && [ -e "$apache_en_dir/$1" ]
    then
        easyapache_site_status="enabled"
    else
        easyapache_site_status="disabled"
    fi
}

easyapache_site_status_switch(){
    easyapache_site_name="${1%.conf}"
    if easysite_file_check "$apache_av_dir/$1"
    then
        easyapache_site_status_get "$1"
        if [ "$easyapache_site_status" == "enabled" ]
        then
            sudo a2dissite "$1" >/dev/null 2>&1
            if easysite_service_reload "apache2"
            then
                echo -e "${BOLD}> ${LGREEN}The site ${LYELLOW}$easyapache_site_name ${LGREEN}has been disabled.${RESET}"
            else
                echo -e "${BOLD}> ${RED}Failed to reload apache: ${LRED}$output${RESET}"
            fi
        else
            sudo a2ensite "$1" >/dev/null 2>&1
            if easysite_service_reload "apache2"
            then
                echo -e "${BOLD}> ${LGREEN}The site ${LYELLOW}$easyapache_site_name ${LGREEN}has been enabled.${RESET}"
            else
                echo -e "${BOLD}> ${RED}Failed to reload apache: ${LRED}$output${RESET}"
            fi
        fi
    else
        echo -e "${BOLD}> ${LRED}This site doesn't exists.${RESET}"
    fi
}

easyapache_site_create(){
    easyapache_site_name="${easyapache_site_file%.conf}"
    if easysite_file_check "$apache_av_dir/$1"
    then
        echo -e "${BOLD}> ${LRED}The site ${LYELLOW}$1 ${LRED}already exists.${RESET}"
    else
        echo "<VirtualHost *:80>" >> "$apache_av_dir/$1"
        echo "        DocumentRoot $2" >> "$apache_av_dir/$1"
        echo "        ServerName $3" >> "$apache_av_dir/$1"
        if [ "$4" != "n" ] && [ "$4" != "N" ] && [ "$4" != "/" ] && [ "$4" != "/ " ] && [ "$4" != "/n" ] && [ "$4" != "/N" ]
        then
            echo "        Alias $4 $2" >> "$apache_av_dir/$1"
        fi
        echo " " >> "$apache_av_dir/$1"
        echo '        ErrorLog ${APACHE_LOG_DIR}/html_error.log' >> "$apache_av_dir/$1"
        echo '        CustomLog ${APACHE_LOG_DIR}/html_access.log combined' >> "$apache_av_dir/$1"
        echo "</VirtualHost>" >> "$apache_av_dir/$1"
        if ! easysite_dir_check "$easyapache_site_DocumentRoot"
        then
            easysite_dir_create "$easyapache_site_DocumentRoot"
        fi
        echo -e "${BOLD}> ${LGREEN}The site ${LYELLOW}$easyapache_site_name ${LGREEN}has been created.${RESET}"
    fi
}

easyapache_site_delete(){
    easyapache_site_name="${easyapache_site_file%.conf}"
    easyapache_site_DocumentRoot=$(grep 'DocumentRoot' "$apache_av_dir/$easyapache_site_file" 2>/dev/null | awk '{print $2}')
    if easysite_file_check "$apache_av_dir/$1"
    then
        a2dissite "$1" >/dev/null 2>&1
        easysite_file_delete "$apache_av_dir/$1"
        easysite_dir_delete "$easyapache_site_DocumentRoot"
        echo -e "${BOLD}> ${LGREEN}The site ${LYELLOW}$easyapache_site_name ${LGREEN}has been deleted.${RESET}"
    else
        echo -e "${BOLD}> ${RED}Failed to delete site: ${LRED}This site doesn't exists.${RESET}"
    fi
}

easyapache_site_get(){
    easyapache_site_name="${easyapache_site_file%.conf}"
    easyapache_site_path="$apache_av_dir/$1"
    easyapache_site_DocumentRoot=$(grep 'DocumentRoot' "$easyapache_site_path" 2>/dev/null | awk '{print $2}')
    easyapache_site_ServerName=$(grep 'ServerName' "$easyapache_site_path" 2>/dev/null | awk '{print $2}')
    easyapache_site_ErrorLog=$(grep 'ErrorLog' "$easyapache_site_path" 2>/dev/null | awk '{print $2}')
    easyapache_site_CustomLog=$(grep 'CustomLog' "$easyapache_site_path" 2>/dev/null | awk '{print $2}')
    easyapache_site_SSLEngine=$(grep -oP '\b\s*SSLEngine\s*\K\S+' "$easyapache_site_path" 2>/dev/null)
    easyapache_site_SSLCertificateFile=$(grep -i 'SSLCertificateFile' "$easyapache_site_path" 2>/dev/null | awk '{print $2}')
    easyapache_site_SSLCertificateKeyFile=$(grep -i 'SSLCertificateKeyFile' "$easyapache_site_path" 2>/dev/null | awk '{print $2}')
    easyapache_site_Alias=$(grep -iE 'Alias\s+(/\S+)' "$easyapache_site_path" 2>/dev/null | awk '{print $2}')
    easyapache_site_AliasDir=$(grep -iE 'Alias\s+(/\S+)\s+(\S+)' "$easyapache_site_path" 2>/dev/null | awk '{print $3}')
}

easyapache_site_show(){
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
        echo -e "${BOLD}> ${RED}Failed to get site informations: ${LRED}This site doesn't exists.${RESET}"
    fi
}


easyapache_site_SSL_enable(){
    if [ "$2" == "1" ]
    then
        sudo a2enmod ssl >/dev/null 2>&1
        sudo apt install certbot python3-certbot-apache -y >/dev/null 2>&1
	if output=$(sudo certbot --apache)
        then
 	    clear
            echo " "
	    bin="true"
            easyapache_site_SSLEngine="on"
	    echo -e "${BOLD}> ${LGREEN}SSL has been enabled successfully.${RESET}"
        else
	    echo -e "${BOLD}> ${RED}Failed to generate SSL certificate/key: ${LRED}$output${RESET}"
	fi
    elif [ "$2" == "2" ]
    then
        sudo a2enmod ssl >/dev/null 2>&1
	sudo apt install openssl >/dev/null 2>&1
        if output=$(openssl req -x509 -newkey rsa:2048 -keyout /etc/ssl/certs/$1_key.pem -out /etc/ssl/certs/$1_cert.pem -days 365)
        then
	    sed -i 's/<VirtualHost \*:80>/<VirtualHost *:443>/' "$apache_av_dir/$1" 2>&1
            sed -i '1i\ ' "$apache_av_dir/$1" 2>&1
            sed -i '1i\</VirtualHost>' "$apache_av_dir/$1"
            sed -i "1i\        Redirect permanent / https://$easyapache_site_ServerName/" "$apache_av_dir/$1" 2>&1
            sed -i '1i\<VirtualHost *:80>' "$apache_av_dir/$1" 2>&1
            sed -i "/CustomLog/a\        SSLCertificateKeyFile /etc/ssl/certs/$1_key.pem" "$apache_av_dir/$1" 2>&1
            sed -i "/CustomLog/a\        SSLCertificateFile /etc/ssl/certs/$1_cert.pem" "$apache_av_dir/$1" 2>&1
            sed -i "/CustomLog/a\        SSLEngine on" "$apache_av_dir/$1" 2>&1
            sed -i "/CustomLog/a\ " "$apache_av_dir/$1" 2>&1
	    if output=$(sudo systemctl reload apache2 2>&1)
            then
	        clear
                echo " "
		bin="true"
                easyapache_site_SSLEngine="on"
	        echo -e "${BOLD}> ${LGREEN}SSL has been enabled successfully.${RESET}"
            else
	        clear
                echo " "
	        echo -e "${BOLD}> ${RED}Failed to enable SSL. ${LRED}$output${RESET}"
            fi
	else
 	    clear
            echo " "
            echo -e "${BOLD}> ${RED}Failed to generate SSL certificate/key. ${LRED}$output${RESET}"
        fi
    fi
}

easyapache_site_SSL_disable(){
    sed -i '/<VirtualHost \*:80>/,/<\/VirtualHost>/d' "$apache_av_dir/$1" 2>&1
    sed -i '1{/^[[:space:]]*$/d}' "$apache_av_dir/$1" 2>&1
    sed -i 's/<VirtualHost \*:443>/<VirtualHost *:80>/' "$apache_av_dir/$1" 2>&1
    sed -i '/^ *$/N;/\n *SSLEngine/d' "$apache_av_dir/$1" 2>&1
    sed -i '/SSLCertificate/d' "$apache_av_dir/$1" 2>&1
    if output=$(sudo systemctl reload apache2 2>&1)
    then
	clear
        echo " "
	bin="false"
	easyapache_site_SSLEngine=""
	echo -e "${BOLD}> ${LGREEN}SSL has been removed successfully.${RESET}"
    else
	clear
        echo " "
        echo -e "${BOLD}> ${RED}Failed to remove SSL: ${LRED}$output${RESET}"
    fi
}

easyapache_site_modify_file(){
    if easysite_file_rename "$apache_av_dir/$easyapache_site_file" "$apache_av_dir/$1"
    then
        easyapache_site_file="$1"
        easysite_service_reload "apache2"
        easyapache_menu_modify "$easyapache_site_file"
    else
        echo -e "${BOLD}> ${LRED}An error occured while renaming the configuration file.${RESET}"
    fi
}

easyapache_site_modify_DocumentRoot(){
    if output=$(sed -i "s#^\(\s*\)DocumentRoot\s\+.*#\1DocumentRoot $1#" "$apache_av_dir/$easyapache_site_file" 2>&1)
    then
        easyapache_site_DocumentRoot="$1"
        echo -e "${BOLD}> ${LGREEN}The Files Directory has been modified successfully.${RESET}"
        easysite_service_reload "apache2"
    else
        echo -e "${BOLD}> ${RED}Failed to modify Files Directory: ${LRED}$output${RESET}"
    fi
}

easyapache_site_modify_ServerName(){
    if output=$(sed -i "s#^\(\s*\)ServerName\s\+.*#\1ServerName $1#" "$apache_av_dir/$easyapache_site_file" 2>&1)
    then
        easyapache_site_ServerName="$1"
        echo -e "${BOLD}> ${LGREEN}The URL has been modified successfully.${RESET}"
        easysite_service_reload "apache2"
    else
        echo -e "${BOLD}> ${RED}Failed to modify URL: ${LRED}$output${RESET}"
    fi
}

easyapache_site_modify_Alias(){
    if [ -z "$easyapache_site_Alias" ]
    then
        if [ "$1" == "n" ] || [ "$1" == "N" ] || [ "$1" == "/" ] || [ "$1" == "/ " ] || [ "$1" == "/n" ] || [ "$1" == "/N" ]
        then
            echo -e "${BOLD}> ${RED}Failed to modify Alias: ${LRED}The current Alias is already empty.${RESET}"
        else
            if output=$(sed -i -e "/^\(\s*\)ServerName\s\+.*$/a\\        Alias $1 $easyapache_site_DocumentRoot" "$apache_av_dir/$easyapache_site_file" 2>&1)
            then
                easyapache_site_Alias="$1"
                echo -e "${BOLD}> ${LGREEN}The Alias has been modified successfully.${RESET}"
                easysite_service_reload "apache2"
            else
                echo -e "${BOLD}> ${RED}Failed to modify Alias: ${LRED}$output${RESET}"
            fi
        fi
    else
        if [ "$1" == "n" ] || [ "$1" == "N" ] || [ "$1" == "/" ] || [ "$1" == "/ " ] || [ "$1" == "/n" ] || [ "$1" == "/N" ]
        then
            if output=$(sed -i "\#Alias $easyapache_site_Alias#d" "$apache_av_dir/$easyapache_site_file" 2>&1)
            then
                easyapache_site_Alias=""
                easyapache_site_AliasDir=""
                echo -e "${BOLD}> ${LGREEN}The Alias has been removed successfully.${RESET}"
                easysite_service_reload "apache2"
            else
                echo -e "${BOLD}> ${RED}Failed to remove Alias: ${LRED}$output${RESET}"
            fi
        else
            if output=$(sed -i "s#^\(\s*\)Alias\s\+.*#\1Alias $1 $easyapache_site_AliasDir#" "$apache_av_dir/$easyapache_site_file" 2>&1)
            then
                easyapache_site_Alias="$1"
                echo -e "${BOLD}> ${LGREEN}The Alias has been modified successfully.${RESET}"
                easysite_service_reload "apache2"
            else
                echo -e "${BOLD}> ${RED}Failed to modify Alias: ${LRED}$output${RESET}"
            fi
        fi
    fi
}

easyapache_site_modify_SSLCertificateFile(){
    if output=$(sed -i "s#^\(\s*\)SSLCertificateFile\s\+.*#\1SSLCertificateFile $1#" "$apache_av_dir/$easyapache_site_file" 2>&1)
    then
        easyapache_site_SSLCertificateFile="$1"
        echo -e "${BOLD}> ${LGREEN}The SSL Certificate Path has been modified successfully.${RESET}"
        easysite_service_reload "apache2"
    else
        echo -e "${BOLD}> ${RED}Failed to modify SSL Certificate Path: ${LRED}$output${RESET}"
    fi
}

easyapache_site_modify_SSLCertificateKeyFile(){
    if output=$(sed -i "s#^\(\s*\)SSLCertificateKeyFile\s\+.*#\1SSLCertificateKeyFile $1#" "$apache_av_dir/$easyapache_site_file" 2>&1)
    then
        easyapache_site_SSLCertificateKeyFile="$1"
        echo -e "${BOLD}> ${LGREEN}The SSL Key Path has been modified successfully.${RESET}"
        easysite_service_reload "apache2"
    else
        echo -e "${BOLD}> ${RED}Failed to modify SSL Key Path: ${LRED}$output${RESET}"
    fi
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
                read -p "$(echo -e "${LCYAN}Enter site name to create (${LYELLOW}c to cancel${LCYAN}):${RESET} ")" easyapache_site_file
                if [ "$easyapache_site_file" == "c" ] || [ "$easyapache_site_file" == "C" ]
                then
                    easyapache_menu_main
                elif [ "$easyapache_site_file" == "" ] || [ "$easyapache_site_file" == " " ] || [ "$easyapache_site_file" == " .conf" ] || [ "$easyapache_site_file" == ".conf" ]
                then
                    clear
                    echo " "
                    echo -e "${BOLD}> ${LRED}Site name can't be empty.${RESET}"
                else
                    if [[ "$easyapache_site_file" == *.conf ]]
                    then
                        easyapache_site_name="${easyapache_site_file%.conf}"
                    else
                        easyapache_site_name="$easyapache_site_file"
                        easyapache_site_file="$easyapache_site_file.conf"
                    fi
                    read -p "$(echo -e "${LCYAN}Enter site Files Directory (Default: ${LYELLOW}/var/www/html/$easyapache_site_name${LCYAN})(${LYELLOW}c to cancel${LCYAN}):${RESET} ")" easyapache_site_DocumentRoot
                    if [ "$easyapache_site_DocumentRoot" == "c" ] || [ "$easyapache_site_DocumentRoot" == "C" ]
                    then
                        easyapache_menu_main
                    else
                        if [ "$easyapache_site_DocumentRoot" == "" ]
                        then
                            easyapache_site_DocumentRoot="/var/www/html/$easyapache_site_name"
                        elif [[ "$easyapache_site_DocumentRoot" != /* ]]
                        then
                            easyapache_site_DocumentRoot="/$easyapache_site_DocumentRoot"
                        fi
                        read -p "$(echo -e "${LCYAN}Enter site URL (Default: ${LYELLOW}$IP${LCYAN})(${LYELLOW}c to cancel${LCYAN}):${RESET} ")" easyapache_site_ServerName
                        if [ "$easyapache_site_ServerName" == "c" ] || [ "$easyapache_site_ServerName" == "C" ]
                        then
                            easyapache_menu_main
                        else
                            if [ "$easyapache_site_ServerName" == "" ]
                            then
                                easyapache_site_ServerName="$IP"
                            fi
                            read -p "$(echo -e "${LCYAN}Enter site Alias (Default: ${LYELLOW}/$easyapache_site_name${LCYAN})(${LYELLOW}n for None${LCYAN})(${LYELLOW}c to cancel${LCYAN}):${RESET} ")" easyapache_site_Alias
                            if [ "$easyapache_site_Alias" == "c" ] || [ "$easyapache_site_Alias" == "C" ]
                            then
                                easyapache_menu_main
                            else
                                if [ "$easyapache_site_Alias" == "" ]
                                then
                                    easyapache_site_Alias="/$easyapache_site_name"
                                elif [[ "$easyapache_site_Alias" != /* ]]
                                then
                                    easyapache_site_Alias="/$easyapache_site_Alias"
                                fi
                                clear
                                echo " "
                                easyapache_site_create "$easyapache_site_file" "$easyapache_site_DocumentRoot" "$easyapache_site_ServerName" "$easyapache_site_Alias"
                            fi
                        fi
                    fi
                fi
                ;;
            2)
                read -p "$(echo -e "${LCYAN}Enter site name to delete (${LYELLOW}c to cancel${LCYAN}):${RESET} ")" easyapache_site_file
                if [ "$easyapache_site_file" == "c" ] || [ "$easyapache_site_file" == "C" ]
                then
                    easyapache_menu_main
                else
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
                fi
                ;;
            3)
                read -p "$(echo -e "${LCYAN}Enter site name to modify (${LYELLOW}c to cancel${LCYAN}):${RESET} ")" easyapache_site_file
                if [ "$easyapache_site_file" == "c" ] || [ "$easyapache_site_file" == "C" ]
                then
                    easyapache_menu_main
                else
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
                        echo -e "${BOLD}> ${RED}Failed to modify site: ${LRED}This site doesn't exists.${RESET}"
                    fi
                fi
                ;;
            4)
                read -p "$(echo -e "${LCYAN}Enter site name to enable/disable (${LYELLOW}c to cancel${LCYAN}):${RESET} ")" easyapache_site_file
                if [ "$easyapache_site_file" == "c" ] || [ "$easyapache_site_file" == "C" ]
                then
                    easyapache_menu_main
                else
                    if [[ "$easyapache_site_file" != *.conf ]]
                    then
                        easyapache_site_file="$easyapache_site_file.conf"
                    fi
                    clear
                    echo " "
                    easyapache_site_status_switch "$easyapache_site_file"
                fi
                ;;
            5)
                read -p "$(echo -e "${LCYAN}Enter site name to display its informations (${LYELLOW}c to cancel${LCYAN}):${RESET} ")" easyapache_site_file
                if [ "$easyapache_site_file" == "c" ] || [ "$easyapache_site_file" == "C" ]
                then
                    easyapache_menu_main
                else
                    if [[ "$easyapache_site_file" != *.conf ]]
                    then
                        easyapache_site_file="$easyapache_site_file.conf"
                    fi
                    clear
                    echo " "
                    easyapache_site_show "$easyapache_site_file"
                fi
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

easyapache_menu_modify(){
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
        echo -e "${LYELLOW}4. Alias${RESET}"
        if [ "$easyapache_site_SSLEngine" == "on" ] || [ "$easyapache_site_SSLEngine" == "On" ] || [ "$easyapache_site_SSLEngine" == "ON" ]
        then
            bin="true"
            echo -e "${LYELLOW}5. Disable SSL${RESET}"
            echo -e "${LYELLOW}6. SSL Certificate Path${RESET}"
            echo -e "${LYELLOW}7. SSL Key Path${RESET}"
            echo -e "${LYELLOW}8. Open in File Editor${RESET}"
            echo -e "${YELLOW}9. Back${RESET}"
        else
            bin="false"
            echo -e "${LYELLOW}5. Enable SSL${RESET}"
            echo -e "${LYELLOW}6. Open in File Editor${RESET}"
            echo -e "${YELLOW}7. Back${RESET}"
        fi
        echo " "
        if [ "$bin" == "true" ]
        then
            read -p "$(echo -e "${LCYAN}Select an option to modify(1-9):${RESET} ")" easyapache_menu_modify_choice
        else
            read -p "$(echo -e "${LCYAN}Select an option to modify(1-7):${RESET} ")" easyapache_menu_modify_choice
        fi
        case $easyapache_menu_modify_choice in
            1)
                read -p "$(echo -e "${LCYAN}Enter new Configuration File name (${LYELLOW}c to cancel${LCYAN}):${RESET} ")" easyapache_site_new_file
                if [ "$easyapache_site_new_file" == "c" ] || [ "$easyapache_site_new_file" == "C" ]
                then
                    easyapache_menu_modify "$easyapache_site_file"
                else
                    if [[ "$easyapache_site_new_file" != *.conf ]]
                    then
                        easyapache_site_new_file="$easyapache_site_new_file.conf"
                    fi
                    clear
                    echo " "
                    easyapache_site_modify_file "$easyapache_site_new_file"
                fi
                ;;
            2)
                read -p "$(echo -e "${LCYAN}Enter new Files Directory (${LYELLOW}c to cancel${LCYAN}):${RESET} ")" easyapache_site_new_DocumentRoot
                if [ "$easyapache_site_new_DocumentRoot" == "c" ] || [ "$easyapache_site_new_DocumentRoot" == "C" ]
                then
                    easyapache_menu_modify "$easyapache_site_file"
                else
                    if [ "$easyapache_site_new_DocumentRoot" == "" ]
                    then
                        easyapache_site_new_DocumentRoot="/"
                    elif [[ "$easyapache_site_new_DocumentRoot" != /* ]]
                    then
                        easyapache_site_new_DocumentRoot="/$easyapache_site_new_DocumentRoot"
                    fi
                    clear
                    echo " "
                    easyapache_site_modify_DocumentRoot "$easyapache_site_new_DocumentRoot"
                fi
                ;;
            3)
                read -p "$(echo -e "${LCYAN}Enter new URL (${LYELLOW}c to cancel${LCYAN}):${RESET} ")" easyapache_site_new_ServerName
                if [ "$easyapache_site_new_ServerName" == "c" ] || [ "$easyapache_site_new_ServerName" == "C" ]
                then
                    easyapache_menu_modify "$easyapache_site_file"
                else
                    clear
                    echo " "
                    easyapache_site_modify_ServerName "$easyapache_site_new_ServerName"
                fi
                ;;
            4)
                read -p "$(echo -e "${LCYAN}Enter new Alias (${LYELLOW}n for None${LCYAN})(${LYELLOW}c to cancel${LCYAN}):${RESET} ")" easyapache_site_new_Alias
                if [ "$easyapache_site_new_Alias" == "c" ] || [ "$easyapache_site_new_Alias" == "C" ]
                then
                    easyapache_menu_modify "$easyapache_site_file"
                else
                    if [ "$easyapache_site_new_Alias" == "" ]
                    then
                        easyapache_site_new_Alias="/"
                    elif [[ "$easyapache_site_new_Alias" != /* ]]
                    then
                        easyapache_site_new_Alias="/$easyapache_site_new_Alias"
                    fi
                    clear
                    echo " "
                    easyapache_site_modify_Alias "$easyapache_site_new_Alias"
                fi
                ;;
            5)
                if [ "$bin" == "true" ]
                then
		    read -p "$(echo -e "${LCYAN}The path to your current certificate/key will be removed, are you sure ? ${LYELLOW}[Y/n]${LCYAN}:${RESET} ")" choice
                    if [ "$choice" == "Y" ] || [ "$choice" == "y" ]
		    then
                        clear
                        echo " "
                        easyapache_site_SSL_disable "$easyapache_site_file"
		    fi
                else
		    echo -e "${BLUE}1. Let's Encrypt (domain name required)${RESET}"
                    echo -e "${BLUE}2. OpenSSL (non trusted HTTPS)${RESET}"
		    read -p "$(echo -e "${LCYAN}Choose an SSL solution (${LYELLOW}c to cancel${LCYAN}):${RESET} ")" choice
                    if [ "$choice" == "1" ]
		    then
                        clear
			echo " "
                        easyapache_site_SSL_enable "$easyapache_site_file" 1
		    elif [ "$choice" == "2" ]
		    then
                        clear
			echo " "
                        easyapache_site_SSL_enable "$easyapache_site_file" 2
		    fi
                fi
                ;;
            6)
                if [ "$bin" == "true" ]
                then              
                    read -p "$(echo -e "${LCYAN}Enter new SSL Certificate Path (${LYELLOW}c to cancel${LCYAN}):${RESET} ")" easyapache_site_new_SSLCertificateFile
                    if [ "$easyapache_site_new_SSLCertificateFile" == "c" ] || [ "$easyapache_site_new_SSLCertificateFile" == "C" ]
                    then
                        easyapache_menu_modify "$easyapache_site_file"
                    else
                        clear
                        echo " "
                        easyapache_site_modify_SSLCertificateFile "$easyapache_site_new_SSLCertificateFile"
                    fi
                else
                    clear
                    echo " "
                    nano "$apache_av_dir/$easyapache_site_file"
                fi
                ;;
            7)
                if [ "$bin" == "true" ]
                then
                    read -p "$(echo -e "${LCYAN}Enter new SSL Key Path (${LYELLOW}c to cancel${LCYAN}):${RESET} ")" easyapache_site_new_SSLCertificateKeyFile
                    if [ "$easyapache_site_new_SSLCertificateKeyFile" == "c" ] || [ "$easyapache_site_new_SSLCertificateKeyFile" == "C" ]
                    then
                        easyapache_menu_modify "$easyapache_site_file"
                    else
                        clear
                        echo " "
                        easyapache_site_modify_SSLCertificateKeyFile "$easyapache_site_new_SSLCertificateKeyFile"
                    fi
                else
                    easyapache_menu_main
                fi
                ;;
            8)
                if [ "$bin" == "true" ]
                then
                    clear
                    echo " "
                    nano "$apache_av_dir/$easyapache_site_file"
                else
                    clear
                    echo " "
                    echo -e "${BOLD}> ${LRED}Invalid option. Please enter a number from 1 to 7.${RESET}"
                fi
                ;;
            9)
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
                    echo -e "${BOLD}> ${LRED}Invalid option. Please enter a number from 1 to 9.${RESET}"
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
easyapache_check
easyapache_menu_main
