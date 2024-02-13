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

function error() {
	printf "\033[91;1m$1\033[m\n"
	OPT_CACHE=0
	delete_files
}

function check_dependencies() {
	python3 --version 2>/dev/null 1>/dev/null
	if (($? != 0)); then
		error "Python3 is not installed."
	fi

	python3 -c "import venv" 2>/dev/null 1>/dev/null
	if (($? != 0)); then
		error "Virtual env python package (venv) not installed."
	fi
}

chosen_day=0
function get_user_choice() {
	printf "\033[H\033[2J"
<<<<<<< HEAD
	printf "\033[1;96m ###   python3 Piscine Tester   ###\n\n\033[m"
=======
	printf "\033[1;92m
  ┌──────────────────────────────────────────────────────────────┐
  │  ╔═╗┬ ┬┌┬┐┬ ┬┌─┐┌┐┌  ╔═╗┬┌─┐┌─┐┬ ┌┐┌┌─┐  ╔╦╗┌─┐┌─┐┌┬┐┌─┐┬─┐  │
  │  ╠═╝└┬┘ │ ├─┤│ ││││  ╠═╝│└─┐│  │ │││├┤    ║ ├┤ └─┐ │ ├┤ ├┬┘  │
  │  ╩   ┴  ┴ ┴ ┴└─┘┘└┘  ╩  ┴└─┘└─┘┴ ┘└┘└─┘   ╩ └─┘└─┘ ┴ └─┘┴└─  │
  └──────────────────────────────────────────────────────────────┘
\n\033[m"
>>>>>>> 63eabab (Update launcher)

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

	mkdir -p PYscine_tester

	if ! [ -f ./PYscine_tester/tester_launcher.sh ]; then
		mv tester_launcher.sh ./PYscine_tester/
		ln -sf ./PYscine_tester/tester_launcher.sh tester_launcher.sh
	fi

	if ! [ -f ./PYscine_tester/conftest.py ] || ((OPT_FORCE==1)); then
		wget "$cfg" -O ./PYscine_tester/conftest.py -o /dev/null &
		loading "$!" "Downloading config file"
	else
		sleep 0.05
		loading "$!" "Config file already here (use -f to force)"
	fi
	ln -sf ./PYscine_tester/conftest.py ./conftest.py

	if ! [ -f ./PYscine_tester/tester_requirements.txt ] || ((OPT_FORCE==1)); then
		wget "$req" -O ./PYscine_tester/tester_requirements.txt -o /dev/null &
		loading "$!" "Downloading requirement file"
	else
		sleep 0.05
		loading "$!" "Requirement file already here (use -f to force)"
	fi

	if ! [ -f "./PYscine_tester/ft_tester_day$chosen_day.py" ] || ((OPT_FORCE==1)); then
		wget "$tests" -O "./PYscine_tester/ft_tester_day$chosen_day.py" -o /dev/null &
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

	rm -f ./conftest.py
	if ((OPT_CACHE == 0)); then
		deactivate 2>/dev/null

		rm -rf ./PYscine_tester 2>/dev/null &
		loading "$!" "Clearing directory."

		exec rm -rf ./PYscine_tester ./tester_launcher.sh
	else
		exit 0
	fi
}

function create_env() {
	if ! [ -d ./PYscine_tester/.venv_tester ]; then
		python3 -m venv ./PYscine_tester/.venv_tester &
		loading "$!" "Creating virtual environnement for tester"
	else
		sleep 0.1
		loading "$!" "Virtual Env already present"
	fi

	! [ -d ./PYscine_tester/.venv_tester ] && error "Tester virtual env non created." && kill -INT $$

	source ./PYscine_tester/.venv_tester/bin/activate

	[ -f ./requirement.txt ] && pip install -r ./requirements.txt 2>&1 >/dev/null  &
	pip install -r ./PYscine_tester/tester_requirements.txt  2>&1 >/dev/null &
	loading "$!" "Downloading dependencies"
}

check_dependencies
get_user_choice

trap delete_files INT

load_files

create_env

pytest -v -rP "./PYscine_tester/ft_tester_day$chosen_day.py"

delete_files
# Clear the terminal
clear -x

# Move the cursor to the top left corner
echo -e "\033[H"
