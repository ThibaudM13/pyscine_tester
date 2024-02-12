#!/bin/bash

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
	base_url="https://gitlab.com/42-projects3/python/piscine_py_tester/-/raw/main"
	req="$base_url/day0$chosen_day.req"
	cfg="$base_url/day0$chosen_day.cfg"
	tests="$base_url/day0$chosen_day.test"

	wget --header="Cookie: _gitlab_session=$GITLAB_SESSION" "$cfg" -O ./conftest.py -o /dev/null &
	loading "$!" "Downloading config file" 
	wget --header="Cookie: _gitlab_session=$GITLAB_SESSION" "$req" -O ./tester_requirements.txt -o /dev/null &
	loading "$!" "Downloading requirement file" 
	wget --header="Cookie: _gitlab_session=$GITLAB_SESSION" "$tests" -O "./ft_tester_day$chosen_day.py" -o /dev/null &
	loading "$!" "Downloading test script" 
}

function delete_files() {
	printf "\n"
	kill $(jobs -p)  2>/dev/null &
	loading "$!" "Stopping tester"

	rm -f ./conftest.py ./tester_requirements.txt "./ft_tester_day$chosen_day.py"
	deactivate 2>/dev/null
	rm -rf .venv_tester .tester.sh &
	loading "$!" "Clearing directory."

	exit 0
}

get_user_choice

trap delete_files INT

load_files

python -m venv .venv_tester &
loading "$!" "Creating virtual environnement for tester"

source ./.venv_tester/bin/activate

pip install -r ./tester_requirements.txt >/dev/null &
loading "$!" "Downloading dependencies"

PYTHONPATH="$PWD:$PYTHONPATH" pytest -v -rP "./ft_tester_day$chosen_day.py"

delete_files
