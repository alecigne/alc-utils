set shell := ["bash", "-cu"]

setup-venv:
    #!/usr/bin/env bash
    if [ ! -d "$(pwd)/.venv" ]; then
        python3 -m venv "$(pwd)/.venv"
        "$(pwd)/.venv/bin/pip" install -r "$(pwd)/requirements.txt"
    fi

install-symlinks: setup-venv
    #!/usr/bin/env bash
    mkdir -p ~/bin
    find "$(pwd)" -maxdepth 1 -type f -name "*.bash" -exec sh -c 'ln -sf "{}" ~/bin/"$(basename "{}" .bash)"' \;
    find "$(pwd)" -maxdepth 1 -type f -name "*.py" -exec sh -c 'ln -sf "{}" ~/bin/"$(basename "{}" .py)"' \;
