FROM python:3.10-slim AS builder


ARG BUILD_ENV=prod
ENV BUILD_ENV=${BUILD_ENV}

WORKDIR /usr/app/server

RUN apt-get update \
    && apt-get --no-install-recommends install -y build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
    && python -m pip install --upgrade pip \
    && python -m pip install poetry

ENV POETRY_VIRTUALENVS_IN_PROJECT=true

COPY pyproject.toml poetry.lock /usr/app/server/

RUN if [ "$BUILD_ENV" = "prod" ]; then \
        poetry install --no-interaction --no-ansi --only main; \
    else \
        poetry install --no-interaction --no-ansi; \
    fi

COPY training /usr/app/server/training


FROM python:3.10-slim AS production

WORKDIR /usr/app/server

COPY --from=builder /usr/app/server/training/ /usr/app/server/training/
COPY --from=builder /usr/app/server/.venv /usr/app/server/.venv
COPY --from=builder /usr/app/server/pyproject.toml /usr/app/server/pyproject.toml
COPY --from=builder /usr/app/server/poetry.lock /usr/app/server/poetry.lock

ENV PATH="/usr/app/server/.venv/bin:$PATH"

RUN groupadd -r appuser && useradd -r -g appuser appuser \
    && chown -R appuser:appuser /usr/app/server

USER appuser

WORKDIR /usr/app/server


ENTRYPOINT ["python", "training/train.py"]
CMD []
