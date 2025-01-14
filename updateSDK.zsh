#!/bin/zsh

MODULE=$1

if [[ ! -d $MODULE ]]; then
    printf "Module %s is not exist.\n" $MODULE
    exit 1
fi

cd $MODULE

printf "===============Setup Java Version for %s===============\n" $MODULE

if [[ ! -f build.gradle.kts ]]; then
    printf "%s is not a android module, check if build.gradle.kts exist.\n" $MODULE
    exit 1
fi

SDK_VERSION=$(cat build.gradle.kts | grep -n "compileSdk")
SDK_LINE=${SDK_VERSION%:*}
SDK_VERSION=${SDK_VERSION#*:}
SDK_VERSION=${SDK_VERSION//[!0-9]/}

printf "> Default compile SDK : %s \n" $SDK_VERSION

while :; do
    read "version?Input new sdk version<Enter to ignore>: "
    if [[ $version == "" ]]; then
        break
    fi
    [[ $version =~ ^[0-9]+$ ]] || { echo "Enter a valid number"; continue; }
    SDK_VERSION=$version
    break
done

printf "> Check and update java version for sdk %s\n" SDK_VERSION

JAVA_VERSIONS=()

SOURCE_JAVA=$(cat build.gradle.kts | grep -n "sourceCompatibility" | xargs)
if [[ -n $SOURCE_JAVA ]]; then 
    SOURCE_LINE=${SOURCE_JAVA%:*}
    SOURCE_JAVA=${SOURCE_JAVA#*:}
    [[ $SOURCE_JAVA =~ (1_[0-9]|[0-9]+) ]]
    SOURCE_JAVA=$MATCH
    SOURCE_JAVA_NEW=$SOURCE_JAVA
    if [[ $SDK_VERSION -lt 34 && $SDK_VERSION -gt 31 ]]; then
        if [[ $SOURCE_JAVA =~ 1_[0-9] ]]; then
            SOURCE_JAVA_NEW=11
        fi
    elif [[ $SDK_VERSION -ge 34 ]]; then
        if [[ $SOURCE_JAVA =~ 1_[0-9] ]]; then
            SOURCE_JAVA_NEW=17
        elif [[ $SOURCE_JAVA -lt 17 ]]; then
            SOURCE_JAVA_NEW=17
        fi
    fi
    printf "Update source java version from %s to %s\n" $SOURCE_JAVA $SOURCE_JAVA_NEW
    sed -i '' -E "${SOURCE_LINE}s/(1_[0-9]|[0-9]+)/${SOURCE_JAVA_NEW}/g" build.gradle.kts
    JAVA_VERSIONS+=($SOURCE_JAVA_NEW)
fi

TARGET_JAVA=$(cat build.gradle.kts | grep -n "targetCompatibility" | xargs)
if [[ -n $TARGET_JAVA ]]; then
    TARGET_LINE=${TARGET_JAVA%:*}
    TARGET_JAVA=${TARGET_JAVA#*:}
    [[ $TARGET_JAVA =~ (1_[0-9]|[0-9]+) ]]
    TARGET_JAVA=$MATCH
    TARGET_JAVA_NEW=$TARGET_JAVA
    if [[ $SDK_VERSION -lt 34 && $SDK_VERSION -gt 31 ]]; then
        if [[ $TARGET_JAVA =~ 1_[0-9] ]]; then
            TARGET_JAVA_NEW=11
        fi
    elif [[ $SDK_VERSION -ge 34 ]]; then
        if [[ $TARGET_JAVA =~ 1_[0-9] ]]; then
            TARGET_JAVA_NEW=17
        elif [[ $TARGET_JAVA -lt 17 ]]; then
            TARGET_JAVA_NEW=17
        fi
    fi

    printf "Update target java version from %s to %s\n" $TARGET_JAVA $TARGET_JAVA_NEW
    sed -i '' -E "${TARGET_LINE}s/(1_[0-9]|[0-9]+)/${TARGET_JAVA_NEW}/g" build.gradle.kts
    JAVA_VERSIONS+=($TARGET_JAVA_NEW)
fi

JVM=$(cat build.gradle.kts | grep -n "jvmTarget" | xargs)
if [[ -n $JVM ]]; then
    JVM_LINE=${JVM%:*}
    JVM_JAVA=${JVM#*:}
    [[ $JVM_JAVA =~ (1.[0-9]|[0-9]+) ]]
    JVM_JAVA=$MATCH
    JVM_JAVA_NEW=$JVM_JAVA
    if [[ $SDK_VERSION -lt 34 && $SDK_VERSION -gt 31 ]]; then
        if [[ $JVM_JAVA -lt 11 ]]; then
            JVM_JAVA_NEW=11
        fi
    elif [[ $SDK_VERSION -ge 34 ]]; then
        if [[ $JVM_JAVA -lt 17 ]]; then
            JVM_JAVA_NEW=17
        fi
    fi
    printf "Update jvmTarget java version from %s to %s\n" $JVM_JAVA $JVM_JAVA_NEW
    sed -i '' -E "${JVM_LINE}s/(1.[0-9]|[0-9]+)/${JVM_JAVA_NEW}/g" build.gradle.kts
    JAVA_VERSIONS+=($JVM_JAVA_NEW)
fi

TOOLCHAIN=$(cat build.gradle.kts | grep -n "JavaLanguageVersion" | xargs)
if [[ -n $TOOLCHAIN ]]; then
    printf "toolchain raw: %s\n" $TOOLCHAIN
    TOOLCHAIN_LINE=${TOOLCHAIN%:*}
    TOOLCHAIN_JAVA=${TOOLCHAIN#*:}
    [[ $TOOLCHAIN_JAVA =~ [0-9]+ ]]
    TOOLCHAIN_JAVA=$MATCH
    TOOLCHAIN_JAVA_NEW=$TOOLCHAIN_JAVA
    if [[ $SDK_VERSION -lt 34 && $SDK_VERSION -gt 31 ]]; then
        if [[ $TOOLCHAIN_JAVA -lt 11 ]]; then
            TOOLCHAIN_JAVA_NEW=11
        fi
    elif [[ $SDK_VERSION -ge 34 ]]; then
        if [[ $TOOLCHAIN_JAVA -lt 17 ]]; then
            TOOLCHAIN_JAVA_NEW=17
        fi
    fi
        printf "Update toolchain java version from %s to %s\n" $TOOLCHAIN_JAVA $TOOLCHAIN_JAVA_NEW
    sed -i '' -E "${TOOLCHAIN_LINE}s/[0-9]+/${TOOLCHAIN_JAVA_NEW}/g" build.gradle.kts
    JAVA_VERSIONS+=($TOOLCHAIN_JAVA_NEW)
fi

sed -i '' -E "${SDK_LINE}s/[0-9]+/${SDK_VERSION}/g" build.gradle.kts

cd ..

JAVA_VERSIONS=(${(Oi)JAVA_VERSIONS})
MAX_JAVA=$JAVA_VERSIONS[1]
if [[ $MAX_JAVA -gt 1.8 ]]; then
    printf "check jitpack.yml\n"
    if [[ ! -f jitpack.yml ]]; then
        echo "jdk:\n  - openjdk${MAX_JAVA}" > jitpack.yml
    else 
        JIT_JAVA=$(cat jitpack.yml | grep -n "openjdk" | xargs)
        JIT_LINE=${JIT_JAVA%:*}
        JIT_JAVA=${JIT_JAVA#*:}
        [[ $JIT_JAVA =~ [0-9]+ ]]
        JIT_JAVA=$MATCH
        if [[ $JIT_JAVA -lt $MAX_JAVA ]]; then
            sed -i '' -E "${JIT_LINE}s/[0-9]+/${MAX_JAVA}/g" jitpack.yml
        fi
    fi
fi
