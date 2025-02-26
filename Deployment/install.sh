aiur() { arg="$( cut -d ' ' -f 2- <<< "$@" )" && curl -sL https://github.com/AiursoftWeb/AiurScript/raw/master/$1.sh | sudo bash -s $arg; }

install_Moonglade()
{

    aiur console/success "Updating..."
    apt-get update --allow-releaseinfo-change
    apt upgrade -y
    server="$1"
    db_type="$2"
    
    aiur console/success "Checking..."
    # Valid domain is required
    if [[ $(curl -sL ifconfig.me) == "$(dig +short $server)" ]]; 
    then
        echo "IP is correct."
    else
        echo "$server is not your current machine IP!"
        return 9
    fi

    # Valid database type mssql(default) and mysql 8.0
    if [ "$db_type" != "mssql" ] && [ "$db_type" != "mysql" ];
    then 
        echo "$db_type is not supported database in this script! try mssql or mysql."
        return 9
    fi

    port=$(aiur network/get_port)
    dbPassword=$(uuidgen)
    
    cd ~

    # Enable BBR
    aiur network/enable_bbr

    # Install basic packages
    aiur console/success "Installing..."

    apt install -y git vim ufw
    aiur install/jq
    aiur install/dotnet
    aiur install/caddy
    if [ "$db_type" == "mssql" ];
    then
        aiur install/sql_server $dbPassword
    else
        apt install mysql-server -y
    fi
    #aiur install/node

    aiur console/success "Cloning..."
    ls | grep -q Moonglade && rm ./Moonglade -rf
    mkdir Storage
    chmod -R 777 ~/Storage/
    git clone -b release https://github.com/EdiWang/Moonglade.git

    # Build the code
    aiur console/success 'Building...'
    moonglade_path="$(pwd)/apps/moongladeApp"
    #rm ./Moonglade/src/Moonglade.Web/libman.json # Remove libman because it is easy to crash.
    dotnet publish -c Release -o $moonglade_path -r linux-x64 --no-self-contained ./Moonglade/src/Moonglade.Web/Moonglade.Web.csproj
    cp ~/Moonglade/build/OpenSans-Regular.ttf /usr/share/fonts/OpenSans-Regular.ttf
    rm ~/Moonglade -rf
    cat $moonglade_path/appsettings.json > $moonglade_path/appsettings.Production.json

    # Configure appsettings.json
    aiur console/success 'Configuring...'

    # Configure different database type
    if [ "$db_type" == "mssql" ];
    then    
        connectionString="Server=tcp:127.0.0.1,1433;Database=Moonglade;uid=sa;Password=$dbPassword;MultipleActiveResultSets=True;"
        db_name="SqlServer"
    else    
        connectionString="Server=localhost;Port=3306;Database=Moonglade;uid=root;Password=$dbPassword;"
        db_name="MySql"
    fi
    aiur text/edit_json "ConnectionStrings.DatabaseType" $db_name $moonglade_path/appsettings.Production.json
    aiur text/edit_json "ConnectionStrings.MoongladeDatabase" "$connectionString" $moonglade_path/appsettings.Production.json
    aiur text/edit_json "ImageStorage.FileSystemPath" '\/root\/Storage' $moonglade_path/appsettings.Production.json
    aiur text/edit_json "ImageStorage.FileSystemSettings.Path" '\/root\/Storage' $moonglade_path/appsettings.Production.json
        
    #npm install web-push -g

    # Create database.
    if [ "$db_type" == "mssql" ];
    then
        aiur console/success 'Seeding...'
        aiur mssql/create_db "Moonglade" $dbPassword
    else
        # Initiate mysql root password and create database Moonglade
        mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password by '$dbPassword'"
        mysql -uroot -e "create database Moonglade" -p"$dbPassword"
    fi

    # Register Moonglade service
    aiur console/success "Registering..."
    aiur services/register_aspnet_service "moonglade" $port $moonglade_path "Moonglade.Web"
    sleep 2

    # Config caddy
    aiur console/success 'Proxying...'
    aiur caddy/add_proxy $server $port
    sleep 2

    # Config firewall
    aiur console/success 'Porting...'
    aiur firewall/open_port 443
    aiur firewall/open_port 80
    aiur firewall/enable_firewall
    sleep 2

    aiur console/success 'Finlization...'
    # Finish the installation
    if [ "$db_type" == "mssql" ];
    then
        db_port="1433"   
        db_user="sa"
        db_data_dir="/var/opt/mssql/"
    else   
        db_port="3306"
        db_user="root"
        db_data_dir="/var/lib/mysql/"
    fi
    echo "Successfully installed Moonglade as a service in your machine! Please open https://$server to try it now!"
    echo "Default management user name is "admin" and default password is "admin123". Please open https://$server/admin to try it now!"
    echo "Successfully installed $db_type as a service in your machine! The port is not opened so you can't connect!"
    echo "Successfully installed caddy as a service in your machine!"
    sleep 1
    echo "You can open your database to public via: sudo ufw allow $db_port/tcp"
    echo "You can access your database via: $server:$db_port with username: $db_user and password: $dbPassword"
    echo "Your database data file is located at: $db_data_dir. Please back up them regularly."
    echo "Your web data file is located at: $moonglade_path"
    echo "Your web server config file is located at: /etc/caddy/Caddyfile"
    echo "Strongly maintain your own configuration at $moonglade_path/appsettings.Production.json"
    echo "Strongly suggest run 'sudo apt upgrade' and reboot when convience!"
}

install_Moonglade "$@"
