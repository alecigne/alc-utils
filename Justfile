set shell := ["bash", "-cu"]

# Prepare virtual environment for Python scripts
setup-venv:
    #!/usr/bin/env bash
    echo "setup-venv: check and setup Python virtualenv"
    if [ ! -d "$(pwd)/.venv" ]; then
        echo "setup-venv: Python virtualenv not present, creating it"
        python3 -m venv "$(pwd)/.venv"
        "$(pwd)/.venv/bin/pip" install -r "$(pwd)/requirements.txt"
    else
        echo "setup-venv: Python virtualenv already present"
        printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    fi

# Test all Python scripts
test: setup-venv
    #!/usr/bin/env bash
    echo "test: executing Python tests"
    source "$(pwd)/.venv/bin/activate"
    find "$(pwd)" -mindepth 2 -maxdepth 2 -type f -name "test_*.py" -exec python3 {} \;
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

# Install symlinks to Bash and Python scripts
install-symlinks: test
    #!/usr/bin/env bash
    echo "install-symlinks: installing symlinks to Bash and Python scripts"
    mkdir -p ~/bin
    find "$(pwd)" -maxdepth 1 -type f -name "*.bash" -exec sh -c 'ln -sf "{}" ~/bin/"$(basename "{}" .bash)"' \;
    find "$(pwd)" -mindepth 2 -maxdepth 2 -type f -name "*.py" ! -name "test_*.py" -exec sh -c 'ln -sf "{}" ~/bin/"$(basename "{}" .py)"' \;
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
