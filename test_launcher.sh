#!/bin/bash

OPT_CACHE=0
OPT_FORCE=0
declare -A days
days_available=''

main() {
	for arg in "$@"; do
		case "$arg" in
			-c|--allow-cache)
				OPT_CACHE=1
				continue;;
			-f|--force)
				OPT_FORCE=1
				continue;;
			*)
				error "$arg: Unknown param..."
				exit 1;;
		esac
	done

	check_dependencies

	days[00]=Starting
	days[01]=Array

	days_available="${!days[@]}"

	trap delete_files INT
	get_user_choice
	load_files
	create_env

	pytest -v -rP "./PYscine_tester/ft_tester_day$chosen_day.py"

	norm=`flake8 --exclude __init__.py ex0*`
	loading "$!" "Checking Norm"

	if [[ -z "$norm" ]]; then
		printf "Flake8 Norm \t\033[92;1mSUCCESS\033[m\n"
	else
		printf "Flake8 Norm \t\033[91;1mFAILED\033[0;91m\n$norm\033[m\n"
	fi

	delete_files
}

# Print error message and disable caching.
error() {
	printf "\033[91;1m$1\033[m\n"
	OPT_CACHE=0
	delete_files
}

# Check dependencies: Python3 and venv.
check_dependencies() {
    python3 --version &>/dev/null || error "Python3 is not installed."
    python3 -c "import venv" &>/dev/null || error "python package venv is not installed."
}

# Initialize chosen day variable
chosen_day=0

# Function to prompt user for a day selection
get_user_choice() {
	printf "\033[H\033[2J"
	printf "\033[1;92m
  ┌──────────────────────────────────────────────────────────────┐
  │  ╔═╗┬ ┬┌┬┐┬ ┬┌─┐┌┐┌  ╔═╗┬┌─┐┌─┐┬ ┌┐┌┌─┐  ╔╦╗┌─┐┌─┐┌┬┐┌─┐┬─┐  │
  │  ╠═╝└┬┘ │ ├─┤│ ││││  ╠═╝│└─┐│  │ │││├┤    ║ ├┤ └─┐ │ ├┤ ├┬┘  │
  │  ╩   ┴  ┴ ┴ ┴└─┘┘└┘  ╩  ┴└─┘└─┘┴ ┘└┘└─┘   ╩ └─┘└─┘ ┴ └─┘┴└─  │
  └──────────────────────────────────────────────────────────────┘
\n\033[m"

    # List available days
	printf "\033[1m Days available are:\033[m\n"
	for key in $days_available; do
		printf "\t day$key \033[2m${days[$key]}\033[m\n"
	done | sort

	printf "\n"

    # Prompt user for day selection
    while true; do
        printf '\r\033[2K'
        read -n  1 -p 'Enter the wished day [0-1] ' choice
        if ! [[ -n $choice ]] || ! [[ $choice =~ [0-9] ]] || ! (( choice <=  1 && choice >=  0 )); then
            sleep  0.3
            continue
		else
			break
		fi
    done

	printf "\n"

    # Store user's choice
	chosen_day=$choice
}

loading() {
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

load_files() {
	base_url="https://gitlab.com/ThibaudM13/piscine_py_tester/-/raw/main"
	req="$base_url/day0$chosen_day.req"
	cfg="$base_url/day0$chosen_day.cfg"
	tests="$base_url/day0$chosen_day.test"

	mkdir -p PYscine_tester

	if ! [ -f ./PYscine_tester/tester_launcher.sh ] && [ -f ./tester_launcher.sh ]; then
		mv tester_launcher.sh ./PYscine_tester/
		ln -sf ./PYscine_tester/tester_launcher.sh tester_launcher.sh
	fi


    download_or_skip() {
        local url=$1
        local dest=$2
        local msg=$3
        if ! [ -f $dest ] || ((OPT_FORCE==1)); then
            wget "$url" -O $dest -o /dev/null &
            loading "$!" "$msg"
        else
            sleep  0.05
            loading "$!" "$(basename $dest) already here (use -f to force)"
        fi
    }

    download_or_skip "$cfg" "./PYscine_tester/conftest.py" "Downloading config file"
    ln -sf ./PYscine_tester/conftest.py ./conftest.py
    download_or_skip "$req" "./PYscine_tester/tester_requirements.txt" "Downloading requirement file"
    download_or_skip "$tests" "./PYscine_tester/ft_tester_day$chosen_day.py" "Downloading test script"
}

delete_files() {
	printf "\n"

    # Stop any background jobs related to the tester
	kill $(jobs -p)  2>/dev/null &
	loading "$!" "Stopping tester"

	rm -f ./conftest.py

    # Check if OPT_CACHE is set to  0, indicating no caching should occur
	if ((OPT_CACHE == 0)); then
		deactivate 2>/dev/null

		# Asynchronously remove the PYscine_tester directory
		rm -rf ./PYscine_tester &>/dev/null &
		loading "$!" "Cleaning directory."

		# Synchronously remove the PYscine_tester directory and tester_launcher.sh
		exec rm -rf ./PYscine_tester ./tester_launcher.sh 2>&1 >/dev/null
	else
        # If caching is allowed, simply exit without cleanup
		exit 0
	fi
}

create_env() {
	if ! [ -d ./PYscine_tester/.venv_tester ]; then
		python3 -m venv ./PYscine_tester/.venv_tester &
		loading "$!" "Creating virtual environnement for tester"
	fi

    # Verify that the virtual environment was created successfully
	! [ -d ./PYscine_tester/.venv_tester ] && error "Tester virtual env non created." && kill -INT $$

	source ./PYscine_tester/.venv_tester/bin/activate

	[ -f ./requirement.txt ] && pip install -r ./requirements.txt 2>&1 >/dev/null  &
	pip install -r ./PYscine_tester/tester_requirements.txt  2>&1 >/dev/null &
	loading "$!" "Downloading dependencies"
}

main "$@"; exit
