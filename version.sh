#!/bin/sh
version=1.1

script_loc=`readlink -f $0`
INSTALL_LOC=/usr/local/bin/version.sh

if [ $1 ] ; then
    if [ $1 = hide ] ; then
        sed -i '4,6s/^/#/' $script_loc 
        echo -e "Installation message disabled.\nUse version.sh unhide to get it back\n"
    elif [ $1 = unhide ] ; then
        sed -i '4,6s/#//' $script_loc
        echo -e "Installation message enabled.\n"
    elif [ $1 = install ] ; then
        if [ `whoami` != root ] ; then
            echo -e "To be installed, this script need root access.\nPlease run sudo ./version.sh install"
            exit
        else
            cp -f $script_loc $INSTALL_LOC
            echo "Script installed as $INSTALL_LOC"
            chown root:root $INSTALL_LOC
            echo "Script owner changed to root."
            chmod 755 $INSTALL_LOC
            echo -e "Script permission set to 755\nScript installation success!"
            exit
        fi
    fi
fi

if [ $script_loc != $INSTALL_LOC ] ; then
    echo -e "It seems this script isn't installed\nRun version.sh install with root privilege to install it.\nUse version.sh hide to hide this message.\n"
fi

if [ $# -lt 2 ] ; then
    echo -e "Usage: version.sh <cmd> <file> [option]\nwhere <cmd> can be: add checkout commit diff log revert rm"
    exit
fi

if [ ! -f $2 ] ; then
    echo -e "Error! ’$2’ is not a file."
    exit
fi

file_loc=`readlink -f $2`
file_dir=`dirname $file_loc`
version_dir=$file_dir/.version

case $1 in

    add | a ) 

        if [ ! -d $version_dir ] ; then 
            mkdir $version_dir
        fi

        if [ ! -f $version_dir/$2.1 ] ; then
            cp -f $file_loc $version_dir/$2.1
            cp -f $file_loc $version_dir/$2.latest
            echo -e "Added a new file under versioning: ’$2’"
            echo "`date -R` | Added a new file under versioning: '$2'" >> .version/$2.log
        else 
            echo -e "$2 is already in the versioning system."
        fi
        ;;

    checkout | co ) 

        if [ ! -d $version_dir ] ; then
            echo -e "There is no file in the versionning system.\nPlease use version.sh add <file> to add one."
            exit
        fi

        if [ $# -ne 3 ] ; then 
            echo "Usage: version.sh checkout <file> <revision>"
        else
            if [ -f $version_dir/$2.$3 ] ; then
                cp -f $version_dir/$2.1 $2
                for n in `seq 2 $3` ; do patch $2 .version/$2.$n; done
                echo -e "Checked out version: $3"
            else
                rev=`expr $(ls $version_dir/$2.* | wc -l) - 2`
                echo -e "No revision: $3, the latest one is $rev."
            fi
        fi
        ;;

    commit | ci )

        if [ ! -d $version_dir ] ; then
            echo -e "There is no file in the versionning system.\nPlease use version.sh add <file> to add one."
            exit
        fi

        if $(cmp -s $2 .version/$2.latest) ; then
            echo -e "No change in $2"
        else
            rev=`expr $(ls $version_dir/$2.* | wc -l) - 1`
            diff -u $version_dir/$2.latest $2 > $version_dir/$2.$rev
            cp -f $2 $version_dir/$2.latest
            if [ $# -eq 3 ] ; then
                echo "`date -R` | $3" >> $version_dir/$2.log
            else
                echo "`date -R` | Committed a new version: $rev" >> $version_dir/$2.log
            fi
            echo -e "Committed a new version: $rev"
        fi
        ;;

    diff | d ) 

        if [ -f $version_dir/$2.latest ] ; then
            diff -u $version_dir/$2.latest $file_loc
        else
            echo "No previous revision"
        fi
        ;;

    log | l ) 

        if [ -f $version_dir/$2.log ] ; then
            nl -s": " $version_dir/$2.log
        else
            echo "No log file found for $2"
        fi
        ;;

    revert | r )

        if [ -f $version_dir/$2.latest ] ; then
            if $(cmp -s $file_loc $version_dir/$2.latest) ; then 
                echo "No change in the two version"
            else
                cp -f $version_dir/$2.latest $2
                echo -e "Reverted to the latest version"
            fi
        else
            echo -e "No previous revision"
        fi
        ;;

    rm )

        if [ ! -f $version_dir/$2.1 ] ; then
            echo -e "$2 isn't in the versionning system."
            exit
        fi

        echo -n "Are you sure you want to delete ’$2’ from versioning? (yes/no) "
        read yn
        case $yn in
            o* | O* | y* | Y* ) 
                rm $version_dir/$2.*
                echo -e "’$2’ is not under versioning anymore."
                rmdir $version_dir 2>/dev/null
        esac
        ;;

    * ) echo -e "Error! This command name does not exist: ’$1’" ;;
esac
