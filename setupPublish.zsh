#!/bin/zsh

WORKDIR=$PWD

TOOLDIR=${0:A:h}

LIBLIST=($(find $WORKDIR -mindepth 1 -maxdepth 1 -type d \( ! -iname ".*" \) \( ! -iname "app" \) \( ! -iname "gradle" \)))

LIBCOUNT=${#LIBLIST[@]}

if [[ $LIBCOUNT == 0 ]]; then
    printf "No library module found.\n";
    exit 1;
fi

SELECTLIB=""

if [[ $LIBCOUNT == 1 ]]; then
    printf "Module %s is found.\n" $(basename ${LIBLIST[1]})
    SELECTLIB=${LIBLIST[1]}
else
    printf "Modules found:\n"

    for index in {1..$LIBCOUNT} ; do
        lib=${LIBLIST[index]}
        printf "<%d> %s\n" index $(basename $lib)
    done

    while :; do
        read "number?Input 1 to $LIBCOUNT to set the module: "
        [[ $number =~ ^[0-9]+$ ]] || { echo "Enter a valid number"; continue; }
        if (($number >= 1 && $number <= $LIBCOUNT)) ; then
            SELECTLIB=${LIBLIST[$number]}
            break
        else
            printf "Invalid module, try again.\n"
        fi
    done
fi

BASE=$(basename $SELECTLIB)
printf "Start setup module: %s\n" $BASE

cd $BASE

# define default value
GROUPID="group.id"
ARTIFACTID=$BASE

# Check gradle file exist.
if [ ! -f build.gradle.kts ]; then
    printf "No gradle kotlin DSL file! Stop set up.\n"
    exit 1
fi

# Parse Group ID from Git repo
GITREMOTE=$(git config --get remote.origin.url)

# Test statements
# printf "Git: %s\n" $GITREMOTE
# GITREMOTE="https://github.com/chenhaiteng/ASLLogger.git"

# Remove url scheme
GITREMOTE=${GITREMOTE#*@}
GITREMOTE=${GITREMOTE#*://}
# printf "base : %s\n" $GITREMOTE

# ${name%pattern} match from end of the value of name, and remove right side.
# ${name%%pattern} largest match of above.
# ${name#pattern} match from beginning of the value of name, and remove left side.
# ${name##pattern} larget match of above.
DOMAIN=${GITREMOTE%/*} # ex: a.b/c/d --> a.b/c

# Extract workspace name for following format: 
# - domain.com/workspace
# - domain.com:workspace
WORKSPACE=${DOMAIN##*/} # ex: a.b/c/d --> d
WORKSPACE=${WORKSPACE##*:} # ex: a.b:c/d --> c/d

# Remove workspace from domain: domain.com/workspace -> domain.com
DOMAIN=${DOMAIN%:*} 
DOMAIN=${DOMAIN%/*}

# Create reversed domain from domain: domain.com -> com.domain 
REVERSED_DOMAIN=(${(@s:.:)DOMAIN})
REVERSED_DOMAIN=${(@j:.:)${(Oa)REVERSED_DOMAIN}}

# Create group ID
GROUPID="$REVERSED_DOMAIN.$WORKSPACE"

# Custom Group ID and Artifact ID
printf "Suggested group ID: %s\n" $GROUPID
read "groupID?Press <Enter> to accept it or input a new one: "
if [[ ! $groupID == "" ]]; then
    GROUPID=$groupID
fi

printf "Suggested artifact ID: %s\n" $ARTIFACTID
read "artifactID?Press <Enter> to accept it or input a new one: "
if [[ ! $artifactID == "" ]]; then
    ARTIFACTID=$artifactID
fi

# Show Publishing Information
printf "\n"
printf "--- Publishing Information ---\n"
printf "| group ID    : %s\n" $GROUPID
printf "| artifact ID : %s\n" $ARTIFACTID
printf "------------------------------\n"
printf "\n"

# Add maven publishing plugins
sed -i '.bak' -e '/plugins {/a\
    id("maven-publish")
    ' build.gradle.kts

# Add publishing block
sed -i '' -e "\$ a\\
\\
\\
publishing { \\
    publications { \\
        register<MavenPublication>(\"release\") { \\
            groupId = \"$GROUPID\" \\
            artifactId = \"$ARTIFACTID\" \\
            version = \"0.0.1\" \\
            afterEvaluate { \\
                from(components[\"release\"]) \\
            } \\
        } \\
    } \\
}" build.gradle.kts

cd ..

if [[ ! -f $TOOLDIR/setupDemoApp.zsh ]]; then
    printf "the script setupDemoApp.zsh is not exist. Ignore it.\n"
else
    $TOOLDIR/setupDemoApp.zsh $BASE
fi

if [[ ! -f $TOOLDIR/updateSDK.zsh ]]; then
    printf "the script updateSDK.zsh is not exist. Ignore it.\n"
else
    $TOOLDIR/updateSDK.zsh $BASE
    $TOOLDIR/updateSDK.zsh app
fi

printf "Set up finished. %s is publishable now." $BASE