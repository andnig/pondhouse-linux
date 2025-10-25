mamba env create --name $1 --file ~/.dotfiles/configs/conda/environment.yml
eval "$(conda shell.zsh hook)"
conda activate $1
python -c 'import IPython; IPython.terminal.ipapp.launch_new_instance()' kernel install --user --name=$1
