install-symlinks:
    find $(pwd) -maxdepth 1 -type f -name "*.bash" -exec sh -c 'ln -sf "$1" ~/bin/$(basename "$1" .bash)' _ {} \;
