require_relative "./dsl"

SetupNitrous.begin(DATA) do
  run "Downloading Janus" do
    vim = File.expand_path("~/.vim")

    test File.exist?(vim)

    setup do
      command "git clone --recursive --progress https://github.com/carlhuda/janus.git #{vim}"
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

  run "Installing Rust" do
    parts_install "rust"
  end

  run "Installing PhantomJS" do
    parts_install "phantomjs"
  end

  run "Installing Postgres" do
    parts_install "postgresql"
  end

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
