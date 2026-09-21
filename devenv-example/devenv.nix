# Esempio devenv.nix per un progetto Ruby on Rails
# Copia questo file nella root del progetto e aggiungi .envrc (vedi sotto)
#
# Installazione devenv: https://devenv.sh/getting-started/
#   nix profile install --accept-flake-config github:cachix/devenv/latest
#
# Utilizzo:
#   cd mio-progetto-rails/
#   cp /path/a/questo/devenv.nix .
#   echo 'use devenv' > .envrc
#   direnv allow
#   devenv up   # avvia postgres + redis

{ pkgs, lib, config, inputs, ... }:
{
  # Ruby: specifica la versione del progetto
  # Versioni disponibili: pkgs.ruby_3_2, pkgs.ruby_3_3, pkgs.ruby_3_4
  languages.ruby = {
    enable = true;
    package = pkgs.ruby_3_2;
    bundler.enable = true;
  };

  # Node.js: specifica la versione del progetto
  # Versioni disponibili: pkgs.nodejs_20, pkgs.nodejs_22, pkgs.nodejs-slim_20
  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_22;
    npm.enable = true;
  };

  # PostgreSQL locale per il progetto
  services.postgres = {
    enable = true;
    package = pkgs.postgresql_16;
    initialDatabases = [
      { name = "${builtins.baseNameOf config.devenv.root}_development"; }
      { name = "${builtins.baseNameOf config.devenv.root}_test"; }
    ];
    listen_addresses = "127.0.0.1";
  };

  # Redis (per Sidekiq, Action Cable, cache)
  services.redis = {
    enable = true;
    port = 6379;
  };

  # Pacchetti aggiuntivi disponibili nell'ambiente
  packages = with pkgs; [
    # Build dependencies Ruby native extensions
    openssl
    libyaml
    readline
    zlib
    libffi
    libgmp
    ncurses
    gdbm

    # Tool Rails
    overmind   # alternativa a foreman per Procfile

    # Utilità
    jq
    httpie
  ];

  # Variabili d'ambiente del progetto
  env = {
    DATABASE_URL = "postgresql://localhost/${builtins.baseNameOf config.devenv.root}_development";
    REDIS_URL = "redis://localhost:6379";
    RAILS_ENV = "development";
    NODE_ENV = "development";
  };

  # Script di setup eseguiti al primo `devenv up`
  enterShell = ''
    echo "Ruby: $(ruby -v)"
    echo "Node: $(node -v)"
    echo "Rails: $(bundle exec rails -v 2>/dev/null || echo 'non installato, esegui: bundle install')"
    echo ""
    echo "Comandi utili:"
    echo "  devenv up                      → avvia PostgreSQL + Redis"
    echo "  overmind start -f Procfile.dev → avvia i processi app (dentro devenv shell)"
    echo "  overmind connect backend       → attacca al processo rails"
    echo "  bundle install                 → installa gem"
  '';
}
