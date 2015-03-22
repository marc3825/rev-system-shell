#!/bin/sh
version=0.81

if [ $# -lt 2 ] ; then
    echo -e "Usage: version.sh <cmd> <file> [option]\nwhere <cmd> can be: add checkout commit diff log revert rm"
    exit
fi

if [ ! -f $2 ] ; then
    echo -e "Error! ’$2’ is not a file."
    exit
fi

case $1 in

    add ) 

        if [ ! -d .version ] ; then 
            mkdir .version
        fi

        if [ ! -d .version/$2.1 ] ; then
            cp -f $2 .version/$2.1
            cp -f $2 .version/$2.latest
            echo -e "Added a new file under versioning: ’$2’"
            echo "`date -R` | Added a new file under versioning: '$2'" > .version/$2.log
        else 
            echo -e "$2 is already in the versioning system."
        fi
        ;;

    checkout | co ) 

        if [ $# -ne 3 ] ; then 
            echo "Usage: version.sh checkout <file> <revision>"
        else
            if [ -f .version/$2.$3 ] ; then
                cp -f .version/$2.1 $2
                patch -p0 < .version/$2.{`seq -s"," 2 $3`} 
                echo -e "Checked out version: $3"
            else
                echo -e "No revision: $3"
            fi
        fi
        ;;

    commit | ci )

        if [ $(cmp -s $2 .version/$2.latest) ] ; then
            echo -e "No change in $2."
            exit
        else
            rev=`expr $(ls .version/$2.* | wc -l) - 2`
            ##diff -u .version/$2.`$rev -1` .version/$2.latest > .version/$2.$rev
            diff -u .version/$2.latest $2 > .version/$2.$rev
            cp -f $2 .version/$2.latest
            if [ $# -eq 3 ] ; then
                echo "`date -R` | $3" >> .version/$2.log
            else
                echo "`date -R` | Committed a new version: $rev" >> .version/$2.log
            fi
            echo -e "Committed a new version: $rev"
        fi
        ;;

    diff ) 

        if [ -f .version/$2.latest ] ; then
            diff -u .version/$2.latest $2
        else
            echo "No previous revision"
        fi
        ;;

    log ) 

        if [ -f .version/$2.log ] ; then
            nl -s": " .version/$2.log
        else
            echo "No log file found for $2"
        fi
        ;;

    revert )

        if [ -f .version/$2.latest ] ; then
            if [ cmp -s $2 .version/$2.latest ] ; then 
                echo "No change in the two version"
                exit
            else
                cp -f .version/$2.latest $2
                echo -e "Reverted to the latest version"
            fi
        else
            echo -e "No previous revision"
            exit
        fi
        ;;

    rm ) 
        echo -n "Are you sure you want to delete ’$2’ from versioning? (yes/no) "
        read yn
        case $yn in
            ##Si $yn commence par yYoO, execute. Permet de faire passer oui/yes/y etc
            o* | O* | y* | Y* ) 
            rm .version/$2.*
            echo -e "’$2’ is not under versioning anymore."
            ##Salon, mais ne s'execute pas si le dossier contient qqchose :p
            ##Redirige la sortie erreur vers le void pour ne pas afficher de message
            rmdir .version 2>/dev/null
    esac
    ;;
* ) echo -e "Error! This command name does not exist: ’$1’" ;;
esac
