#!/bin/bash


function help {
echo ""
echo "You must have id_rsa key in $HOME/.ssh/ folder"
echo ""
echo "Arguments is empty."
echo ""
echo "--host (Сервер с которого надо бэкапить)"
echo "--backup_folder |Y default(No) (Включить бэкап папки с удаленного сервера)"
echo "--from (Папка которую надо бэкапить с сервера)"
echo "--to | default($HOME/HOST) (Папка куда будет проводится бэкап)"
echo "--backup_db |Y default(No) (Включить бэкап Базы данных)"
echo "-f|--database_folder | default ($HOME/HOST/DB)"
echo "-d|--database (Имя базы данных)"
echo "-u|--user (Имя пользователя БД)"
echo "-p|--pasword (Пароль от БД)"
echo "Example:"
echo "./backups.sh --host example.com --backup_folder Y --from /var/www/example.com --backup_db Y -d example_db -u ***** -p *****"
echo "./backups.sh --host example.com --backup_folder Y --from /var/www/example.com"
echo "./backups.sh --host example.com --backup_folder Y --from /etc/nginx --to /mnt/backups/example.com/conf"
echo "./backups.sh --host example.com --backup_db Y -d example_db -u ***** -p *****"
exit 0
}

if [[ $# == 0 ]]
then
help
fi

while [[ $# -gt 1 ]]
do
key="$1"

#echo $1" "$2
case $key in
    --host)
    REMOTE_HOST="$2"
    shift # past argument
    ;;
    --backup_folder)
    BACKUP_FOLDER="$2"
    shift # past argument
    ;;
    --from)
    FOLDER_FROM="$2"
    shift # past argument
    ;;
    --to)
    FOLDER_TO="$2"
    shift # past argument
    ;;
    --backup_db)
    BACKUP_DB="$2"
    shift # past argument
    ;;
    -f|--database_folder)
    DATABASE_FOLDER="$2"
    shift # past argument
    ;;
    -d|--database)
    DATABASE="$2"
    shift # past argument
    ;;
    -u|--user)
    USER_DB="$2"
    shift # past argument
    ;;
    -p|--password)
    PASSWORD_DB="$2"
    shift # past argument
    ;;
    *)
    echo "$@ Unknown option"
    exit 0        # unknown option
    ;;
esac
shift # past argument or value
done

DATE=`date +%F_%H-%M`

# Check option remote host
if [[ -z $REMOTE_HOST ]]
then
	echo "--host is empty"
	exit 0
fi


# Folder to copy
if [[ -z $FOLDER_TO ]]
then
	FOLDER_TO=$HOME$REMOTE_HOST
fi


# Folder to copy Database
if [[ -z $DATABASE_FOLDER ]]
then
	DATABASE_FOLDER=$HOME$REMOTE_HOST/db
fi

echo $FOLDER_TO" "$DATABASE_FOLDER
# Check backup option
if [[ ! $BACKUP_FOLDER == "Y" ]] && [[ ! $BACKUP_DB == "Y" ]]
then
	echo "--backup_folder and --backup_db not used"
	exit 0
fi


# Check options --from and --to
if [[ $BACKUP_FOLDER == "Y" ]]
then
	if [[ ! -z $FOLDER_FROM ]] && [[ ! -z $FOLDER_TO ]]
	then
		echo "--from = $FOLDER_FROM, --to = $FOLDER_TO"
		mkdir -p $FOLDER_TO
	else
		echo "You not set params --from or --to"
		exit 0
	fi
fi


# Check db options
if [[ $BACKUP_DB == "Y" ]]
then
	if [[ $BACKUP_DB == "Y" ]] && [ ! -z $DATABASE ] && [ ! -z $USER_DB ] && [ ! -z $PASSWORD_DB ] && [ ! -z $DATABASE_FOLDER ]
	then
		echo "DB_BACKUP_OPTS: database - "$DATABASE", user - "$USER_DB", pass - "$PASSWORD_DB", database folder - "$DATABASE_FOLDER
		mkdir -p $DATABASE_FOLDER
	else
		echo "Options for BACKUP_DB is not full"
		echo "Use -backup_db Y -d database -f /backup/db/ -u user -p password"
		exit 0
	fi
fi


# Start ssh-agent
echo ""
echo ""

echo -e "Create agent\n"
eval `ssh-agent -s`

#sleep 60

env
echo ""
echo ""

# Start expect for SSH-ADD
echo -e "Expect ssh key\n"
SCRIPT_FOLDER=`dirname $0`
$SCRIPT_FOLDER/expect-ssh-add.exp

#sleep 60

echo ""
echo ""
ssh-add -l
echo ""
ssh-add -L

echo ""
echo -e "Try ssh\n"
ssh -vvv $REMOTE_HOST "ls $FOLDER_FROM"

#sleep 60

#if [[ $BACKUP_FOLDER == "Y" ]]
#then
#	rsync --archive --one-file-system $REMOTE_HOST:$FOLDER_FROM --delete $FOLDER_TO/origin/
#	cp --archive --link $FOLDER_TO/origin/ $FOLDER_TO/origin-$DATE
#fi

#if [[ $BACKUP_DB == "Y" ]]
#then
#
#	ssh $REMOTE_HOST "mysqldump -u$USER_DB  -p$PASSWORD_DB  $DATABASE" | gzip -c | cat > $DATABASE_FOLDER/$DATABASE-$DATE.sql.gz
#
#fi


echo -e "Kill ssh-agent\n"
eval `ssh-agent -k`

