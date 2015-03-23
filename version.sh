#!/bin/sh
version=1.1

if [ ! -f /usr/local/version.sh ] ; then
    echo -e "It seems this script isn't installed\nRun version.sh install with root privilege to install it.\nUse version.sh hide to hide this message.\n"
fi

if [ $1 ] ; then
    if [ $1 = hide ] ; then
        sed -i '4s/^/#/' $0
        sed -i '5s/^/#/' $0
        sed -i '6s/^/#/' $0
        echo -e "Installation message disabled.\nUse version.sh unhide to get it back\n"
    elif [ $1 = unhide ] ; then
        sed -i '4s/#//' $0
        sed -i '5s/#//' $0
        sed -i '6s/#//' $0
        echo -e "Installation message enabled.\n"
    elif [ $1 = install ] ; then
        if [ `whoami` != root ] ; then
            echo -e "To be installed, this script need root access.\nPlease run sudo ./version.sh install"
            exit
        else
            cp -f version.sh /usr/local/bin/version.sh
            echo "Script installed as /usr/local/bin/version.sh"
            chown root:root /usr/local/bin/version.sh
            echo "Script owner changed to root."
            chmod 755 /usr/local/bin/version.sh
            echo -e "Script permission set to 755\nScript installation success!"
            exit
        fi
    fi
fi

if [ $# -lt 2 ] ; then
    echo -e "Usage: version.sh <cmd> <file> [option]\nwhere <cmd> can be: add checkout commit diff log revert rm"
    exit
fi

if [ ! -f $2 ] ; then
    echo -e "Error! ’$2’ is not a file."
    exit
fi

case $1 in

    add | a ) 

        if [ ! -d .version ] ; then 
            mkdir .version
        fi

        if [ ! -f .version/$2.1 ] ; then
            cp -f $2 .version/$2.1
            cp -f $2 .version/$2.latest
            echo -e "Added a new file under versioning: ’$2’"
            echo "`date -R` | Added a new file under versioning: '$2'" >> .version/$2.log
        else 
            echo -e "$2 is already in the versioning system."
        fi
        ;;

    checkout | co ) 

        if [ ! -d .version ] ; then
            echo -e "There is no file in the versionning system.\nPlease use version.sh add <file> to add one."
            exit
        fi

        if [ $# -ne 3 ] ; then 
            echo "Usage: version.sh checkout <file> <revision>"
        else
            if [ -f .version/$2.$3 ] ; then
                cp -f .version/$2.1 $2
                for n in `seq 2 $3` ; do patch $2 .version/$2.$n; done
                echo -e "Checked out version: $3"
            else
                rev=`expr $(ls .version/$2.* | wc -l) - 2`
                echo -e "No revision: $3, the latest one is $rev."
            fi
        fi
        ;;

    commit | ci )

        if [ ! -d .version ] ; then
            echo -e "There is no file in the versionning system.\nPlease use version.sh add <file> to add one."
            exit
        fi

        if $(cmp -s $2 .version/$2.latest) ; then
            echo -e "No change in $2"
        else
            rev=`expr $(ls .version/$2.* | wc -l) - 1`
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

    diff | d ) 

        if [ -f .version/$2.latest ] ; then
            diff -u .version/$2.latest $2
        else
            echo "No previous revision"
        fi
        ;;

    log | l ) 

        if [ -f .version/$2.log ] ; then
            nl -s": " .version/$2.log
        else
            echo "No log file found for $2"
        fi
        ;;

    revert | r )

        if [ -f .version/$2.latest ] ; then
            if $(cmp -s $2 .version/$2.latest) ; then 
                echo "No change in the two version"
            else
                cp -f .version/$2.latest $2
                echo -e "Reverted to the latest version"
            fi
        else
            echo -e "No previous revision"
        fi
        ;;

    rm )

        if [ ! -f .version/$2.1 ] ; then
            echo -e "$2 isn't in the versionning system."
            exit
        fi

        echo -n "Are you sure you want to delete ’$2’ from versioning? (yes/no) "
        read yn
        case $yn in
            o* | O* | y* | Y* ) 
                rm .version/$2.*
                echo -e "’$2’ is not under versioning anymore."
                rmdir .version 2>/dev/null
        esac
        ;;

    * ) echo -e "Error! This command name does not exist: ’$1’" ;;
esac
