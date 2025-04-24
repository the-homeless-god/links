FROM elixir:1.14-alpine AS build

ENV MIX_ENV=prod \
    PORT=4000 \
    PHX_HOST=localhost \
    LOGSTASH_HOST=logstash \
    LOGSTASH_PORT=5044

RUN apk add --no-cache build-base npm git

WORKDIR /app

# Устанавливаем hex и rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Копируем только файлы для зависимостей
COPY mix.exs ./

# Создаем пустой mix.lock, если он отсутствует
RUN touch mix.lock

# Получаем зависимости
RUN mix deps.get

# Копируем все остальное и компилируем
COPY . .
RUN mix do compile

# Собираем статические ассеты
RUN mix assets.deploy

# Создаем релиз
RUN mix release

# Второй этап: создание финального образа
FROM alpine:3.16 AS app

RUN apk add --no-cache libstdc++ openssl ncurses-libs

ENV MIX_ENV=prod \
    PORT=4000 \
    LANG=C.UTF-8

WORKDIR /app

# Копируем релиз из предыдущего этапа
COPY --from=build /app/_build/prod/rel/links_api ./

# Устанавливаем команду запуска
CMD bin/links_api start 