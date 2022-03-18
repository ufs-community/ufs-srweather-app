a_function(){
    echo "$1"
    if [ "$1" = "1" ];
    then
        echo "hello"
    fi
}

a_function "0"

a_function "1"

if [ "a" = "a" ];
then
    echo "hit"
else
    echo "missed"
fi
