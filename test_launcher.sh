#!/bin/bash

OPT_CACHE=0
OPT_FORCE=0
for arg in "$@"; do
	if [ "$arg" == "-c" ] || [ "$arg" == "--allow-cache" ]; then
		OPT_CACHE=1
	elif [ "$arg" == "-f" ] || [ "$arg" == "--force" ]; then
		OPT_FORCE=1
	fi
done

declare -A days

days[00]=Starting
days[01]=Array

days_available="${!days[@]}"

chosen_day=0
function get_user_choice() {
	printf "\033[H\033[2J"
	printf "\033[1;96m ###   Python Piscine Tester   ###\n\n\033[m"

	printf "\033[1m Days available are:\033[m\n"
	for key in $days_available; do
		printf "\t day$key \033[2m${days[$key]}\033[m\n"
	done | sort

	printf "\n"

	while true; do
		printf '\r\033[2K'
		read -n 1 -p 'Enter the wished day [0-1] ' choice 
		if ! [[ -n $choice ]]; then
			continue
		elif ! [[ $choice =~ [0-9] ]]; then
			continue
		elif (( choice <= 1 && choice >= 0 )); then
			break
		fi
		sleep 0.3
	done

	printf "\n"

	chosen_day=$choice
}

function loading() {
    loading_pid=$1
    loading_str=$2
    loading_chars=("⠾" "⠽" "⠻" "⠟" "⠯" "⠷")
    idx=0

	# Hise cursor
	printf "\r\033[K\e[?25l"

    while true; do
        # Check if the process is still running
        if ! kill -0 $loading_pid  2>/dev/null; then
            break
        fi

        # Display the loading string with the current character
        echo -ne " ${loading_chars[$idx]} ${loading_str}\r"

        # Update the index for the next iteration
		if (( idx ==  ${#loading_chars[@]} - 1 )); then
			idx=0
		else
			((idx++))
		fi

        # Wait before updating the display
        sleep  0.2
    done

    # Clear the line after the loop ends
    printf "\r\033[K\e[?25h \033[92;1m✓\033[m $loading_str\n"

} 

function load_files() {
	base_url="https://gitlab.com/ThibaudM13/piscine_py_tester/-/raw/main"
	req="$base_url/day0$chosen_day.req"
	cfg="$base_url/day0$chosen_day.cfg"
	tests="$base_url/day0$chosen_day.test"

	mkdir -p tester_PYscine

	if [ -f tester_PYscine ]; then
		mv tester_launcher.sh ./tester_PYscine/
		ln -sf ./tester_PYscine/tester_launcher.sh tester_launcher.sh
	fi

	if ! [ -f ./tester_PYscine/conftest.py ] || ((OPT_FORCE==1)); then
		wget "$cfg" -O ./tester_PYscine/conftest.py -o /dev/null &
		loading "$!" "Downloading config file"
	else
		sleep 0.05
		loading "$!" "Config file already here (use -f to force)"
	fi
	ln -sf ./tester_PYscine/conftest.py ./conftest.py

	if ! [ -f ./tester_PYscine/tester_requirements.txt ] || ((OPT_FORCE==1)); then
		wget "$req" -O ./tester_PYscine/tester_requirements.txt -o /dev/null &
		loading "$!" "Downloading requirement file"
	else
		sleep 0.05
		loading "$!" "Requirement file already here (use -f to force)"
	fi

	if ! [ -f "./tester_PYscine/ft_tester_day$chosen_day.py" ] || ((OPT_FORCE==1)); then
		wget "$tests" -O "./tester_PYscine/ft_tester_day$chosen_day.py" -o /dev/null &
		loading "$!" "Downloading test script"
	else
		sleep 0.05
		loading "$!" "Test script already here (use -f to force)"
	fi
}

function delete_files() {
	printf "\n"
	kill $(jobs -p)  2>/dev/null &
	loading "$!" "Stopping tester"

	if ((OPT_CACHE == 0)); then
		deactivate 2>/dev/null

		rm -rf ./tester_PYscine tester_launcher.py
		loading "$!" "Clearing directory."
	fi
	rm -f ./conftest.py
	exit 0
}

get_user_choice

trap delete_files INT

load_files

if ! [ -d ./tester_PYscine/.venv_tester ]; then
	python -m venv ./tester_PYscine/.venv_tester &
	loading "$!" "Creating virtual environnement for tester"
else
	sleep 0.1
	loading "$!" "Virtual Env already present"
fi

source ./tester_PYscine/.venv_tester/bin/activate

pip install -r ./tester_PYscine/tester_requirements.txt >/dev/null &
loading "$!" "Downloading dependencies"

pytest -v -rP "./tester_PYscine/ft_tester_day$chosen_day.py"

delete_files
