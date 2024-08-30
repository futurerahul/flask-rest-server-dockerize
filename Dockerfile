#FROM frolvlad/alpine-python3
FROM python:3.6-alpine

ENV API_SERVER_HOME=/opt/www
WORKDIR "$API_SERVER_HOME"
COPY "./requirements.txt" "./"
COPY "./app/requirements.txt" "./app/"
COPY "./config.py" "./"
COPY "./tasks" "./tasks"

ARG INCLUDE_POSTGRESQL=true
ARG INCLUDE_UWSGI=false
RUN apk add build-base
RUN apk add --no-cache --virtual=.build_dependencies curl-dev musl-dev gcc python3-dev libffi-dev linux-headers libpq-dev && \
    cd /opt/www && \
    pip install -r tasks/requirements.txt && \
    invoke app.dependencies.install && \
    ( \
        if [ "$INCLUDE_POSTGRESQL" = 'true' ]; then \
            apk add --no-cache libpq && \
            apk add --no-cache --virtual=.build_dependencies postgresql-dev && \
            pip install psycopg2-binary ; \
        fi \
    ) && \
    ( if [ "$INCLUDE_UWSGI" = 'true' ]; then pip install uwsgi ; fi ) && \
    rm -rf ~/.cache/pip && \
    apk del .build_dependencies

COPY "./" "./"

RUN chown -R nobody "." && \
    if [ ! -e "./local_config.py" ]; then \
        cp "./local_config.py.template" "./local_config.py" ; \
    fi

USER nobody
CMD [ "invoke", "app.run", "--no-install-dependencies", "--host", "0.0.0.0" ]
