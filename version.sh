#!/bin/sh

#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.

#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.


## Vars: script location and install location
## INSTALL_LOC can be changed to any dir, but it need to be in $PATH
## to work everywhere (other standard: /bin, /usr/bin)
script_loc=`readlink -f $0`
INSTALL_LOC=/usr/local/bin/version.sh

## Manage the installation/installation request
if [ $1 ] ; then
    if [ $1 = hide ] ; then
        ## To hide the text, we comment the lines of the test and the echo
        sed -i '53,55s/^/#/' $script_loc 
        echo -e "Installation message disabled.\nUse version.sh unhide to get it back\n"
        ## To get it back we remove the #
    elif [ $1 = unhide ] ; then
        sed -i '53,55s/#//' $script_loc
        echo -e "Installation message enabled.\n"
        ## Installer
    elif [ $1 = install ] ; then
        ## Check for the root right to write and chown/mod
        if [ `whoami` != root ] ; then
            echo -e "To be installed, this script need root access.\nPlease run sudo ./version.sh install"
            exit
        else
            ## We' ve the right, so copy and set secure rights
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

## Installation status check, commented/uncommented by hide/unhide  
if [ $script_loc != $INSTALL_LOC ] ; then
    echo -e "It seems this script isn't installed\nRun version.sh install with root privilege to install it.\nUse version.sh hide to hide this message.\n"
fi

## If there is under 2 arguments, tell how's working the program
if [ $# -lt 2 ] ; then
    echo -e "Usage: version.sh <cmd> <file> [option]\nwhere <cmd> can be: add checkout commit diff log revert rm"
    exit
fi

## Check if the second argument is a file
if [ ! -f $2 ] ; then
    echo -e "Error! ’$2’ is not a file."
    exit
fi

## Some other vars after the lasts check
## file_loc is the full path to the file $2
## file_dir is the directory of the file $2
## file_name is the name of the file $2
## version_dir is the versionning folder
file_loc=`readlink -f $2`
file_dir=`dirname $file_loc`
file_name=`basename $2`
version_dir=$file_dir/.version

case $1 in

    ## Add a file to the versionning manager
    add | a ) 

    ## Create the .version folder if he didn't exist
    if [ ! -d $version_dir ] ; then 
        mkdir $version_dir
    fi

    ## If the file isn't already here, we add the file and write an entry in the logs.
    if [ ! -f $version_dir/$file_name.1 ] ; then
        cp -f $file_loc $version_dir/$file_name.1
        cp -f $file_loc $version_dir/$file_name.latest
        echo -e "Added a new file under versioning: ’$file_name’"
        echo "`date -R` | Added a new file under versioning: '$file_name'" >> $version_dir/$file_name.log
        ## Handle if the file's already here
    else 
        echo -e "$file_name is already in the versioning system."
    fi
    ;;

    ## Apply incremental patch to the desired revision
    checkout | co ) 

    ## Check if the versionning system has been initialized
    if [ ! -d $version_dir ] ; then
        echo -e "There is no file in the versionning system.\nPlease use version.sh add <file> to add one."
        exit
    fi

    ## Check if there's a 3rd arg for the rev number
    if [ $# -ne 3 ] ; then 
        echo "Usage: version.sh checkout <file> <revision>"
    else
        ## Get the current rev number, -2 to counterbalance $2.log and $2.latest
        rev=`expr $(ls $version_dir/$file_name.* | wc -l) - 2`
        ## Check if the desired rev exist
        if [ $3 -le $rev ] ; then
            ## Revert $2 to his original state
            cp -f $version_dir/$file_name.1 $file_loc
            ## Apply patch from 2 to $3 consecutively
            for n in `seq 2 $3` ; do patch $file_loc $version_dir/$file_name.$n; done
            echo -e "Checked out version: $3"
            ## If the desired rev is > of the latest saved, print the latest
        else
            echo -e "No revision: $3, the latest one is $rev."
        fi
    fi
    ;;

    ## Make a snapshot of $2
    commit | ci )

    ## Check if the versionning system has been initialized.
    if [ ! -d $version_dir ] ; then
        echo -e "There is no file in the versionning system.\nPlease use version.sh add <file> to add one."
        exit
    fi

    ## Check if there are change between $2 and the latest rev
    ## cmp -s to get a boolean return instead of a detailed output
    if $(cmp -s $file_loc $version_dir/$file_name.latest) ; then
        echo -e "No change in $file_name"
    else
        ## $rev is this rev number.
        rev=`expr $(ls $version_dir/$file_name.* | wc -l) - 1`
        ## Create a patch with the diff between the latest saved rev and the atual one.
        diff -u $version_dir/$file_name.latest $file_loc > $version_dir/$file_name.$rev
        ## Store the actual file to .version/$2.latest
        cp -f $file_loc $version_dir/$file_name.latest
        ## If there's a 3rd arg, add it in the log, or add the default one
        if [ $# -eq 3 ] ; then
            echo "`date -R` | $3" >> $version_dir/$file_name.log
        else
            echo "`date -R` | Committed a new version: $rev" >> $version_dir/$file_name.log
        fi
        echo -e "Committed a new version: $rev"
    fi
    ;;

    ## Disp the diff patch between the actual file and the latest snapshot
    diff | d ) 

    if [ -f $version_dir/$file_name.latest ] ; then
        diff -u $version_dir/$file_name.latest $file_loc
    else
        echo "No previous revision"
    fi
    ;;

    ## Disp the logs
    log | l ) 

    if [ -f $version_dir/$file_name.log ] ; then
        ## line numerator, ": " set as separator
        nl -s": " $version_dir/$file_name.log
    else
        echo "No log file found for $file_name"
    fi
    ;;

    ## Revert the actual file to the latest snapshot
    revert | r )

    if [ -f $version_dir/$file_name.latest ] ; then
        if $(cmp -s $file_loc $version_dir/$file_name.latest) ; then 
            echo "No change in the two version"
        else
            cp -f $version_dir/$file_name.latest $file_loc
            echo -e "Reverted to the latest version"
        fi
    else
        echo -e "No previous revision"
    fi
    ;;

    ## Remove a file from the versionning system
    rm )

    if [ ! -f $version_dir/$file_name.1 ] ; then
        echo -e "$file_name isn't in the versionning system."
        exit
    fi

    ## Ask for a confirmation before deleting
    echo -n "Are you sure you want to delete ’$file_name’ from versioning? (yes/no) "
    read yn
    case $yn in
        ## Allow all words beginning by yY, it's faster
        y* | Y* ) 
        rm $version_dir/$file_name.*
        echo -e "’$file_name’ is not under versioning anymore."
        ## rm the folder, don' t work if it's not empty. stderr throwed to the void
        rmdir $version_dir 2>/dev/null
esac
;;

## Ignore all other case
* ) echo -e "Error! This command name does not exist: ’$1’" ;;
esac
