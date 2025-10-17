FROM elixir:1.17


RUN set -uex; \
    apt-get update; \
    apt-get install -y apt-utils libvips-tools build-essential inotify-tools ca-certificates curl gnupg bat fzf ripgrep  iputils-ping nodejs npm -y;

RUN mix local.hex --force \
 && mix local.rebar --force

RUN npm install -g @anthropic-ai/claude-code

RUN ln -s /usr/bin/batcat /usr/bin/bat
ENV ERL_AFLAGS "-kernel shell_history enabled"
ENV APP_HOME /app
RUN mkdir -p $APP_HOME
COPY . /app/
WORKDIR $APP_HOME

