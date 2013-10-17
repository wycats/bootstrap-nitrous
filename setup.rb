require_relative "./dsl"

SetupNitrous.begin(DATA) do
  dependency "curl"
  dependency "zsh"
  dependency "vim"

  run "Downloading oh-my-zsh" do
    oh_my_zsh = File.expand_path("~/.oh-my-zsh")

    test File.exist?(oh_my_zsh)

    setup do
      command "git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh"
      copy "~/.oh-my-zsh/templates/zshrc.zsh-template", "~/.zshrc"
    end

    update do
      Dir.chdir(oh_my_zsh) { command "git pull" }
    end

    converge do
      copy "~/.oh-my-zsh/custom/wycats.zsh"
    end
  end

  run "Downloading Janus" do
    vim = File.expand_path("~/.vim")

    test File.exist?(vim)

    setup do
      command "git clone --recursive --progress https://github.com/carlhuda/janus.git #{vim}"
    end

    update do
      Dir.chdir(vim) { command "git pull" }
    end

    converge do
      Dir.chdir(vim) { command "rake" }
    end
  end

  run "Copying ~/.vimrc.after" do
    copy "~/.vimrc.after"
  end

  run "Copying ~/.tmux.conf" do
    copy "~/.tmux.conf"
  end

  package "tmux"
  package "rust"
  package "phantomjs"
  package "postgresql"

  run "Setting git identity and configuration" do
    command "git config --global user.email 'wycats@gmail.com'"
    command "git config --global user.name 'Yehuda Katz'"
    command "git config --global push.default simple"
  end
end

__END__

# ~/.vimrc.after

set mouse=a
set ttymouse=xterm2
colorscheme jellybeans+

# ~/.tmux.conf

set-option -g default-shell /usr/bin/zsh --login
set -g default-terminal "screen-256-color"

unbind +
bind + new-window -d -n tmp \; swap-pane -s tmp.0 \; select-window -t tmp
unbind -
bind - last-window \; swap-pane -s tmp.0 \; kill-window -t tmp

set -g mouse-mode on
set -g mouse-select-pane on
set -g mouse-resize-pane on
set -g mouse-select-window on

# ~/.oh-my-zsh/custom/wycats.zsh

export TERM=xterm
