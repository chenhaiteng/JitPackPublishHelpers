#!/bin/zsh


if [[ -z $1 ]]; then
    printf "Invalid argument.\n"
    exit 1
fi

WORKDIR=$PWD

DEMOAPP="$PWD/app"

if [[ ! -d $DEMOAPP ]]; then
    printf "%s is not a directory.\n" $DEMOAPP
    exit 1
fi

cd $DEMOAPP

# Check gradle file exist.
if [ ! -f build.gradle.kts ]; then
    printf "No gradle kotlin DSL file! Stop set up.\n"
    exit 1
fi

sed -i '.bak' -e "/dependencies {/a \\
    implementation(project(\":$1\"))" build.gradle.kts