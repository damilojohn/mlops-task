FROM python-3.12:slim AS builder


WORKDIR /usr/app/server/

RUN apt-get update \
    && apt-get --no-install-recommends install -y \
    build-essential \
    && apt-get-clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY --from=ghcr.io/astral-sh/uv:0.6.14 /uv /uvx /bin/

COPY .pyproject.toml uv.lock /usr/app/server/

RUN uv sync --only-group apiserver

COPY /api /usr/app/server/api

FROM builder

WORKDIR /usr/app/server

COPY --from=builder /usr/app/server/api/ /usr/app/server/api/
COPY --from=builder /usr/app/server/.venv /usr/app/server/.venv
COPY --from=builder /usr/app/server/pyproject.toml /usr/app/server/pyproject.toml
COPY --from=builder /usr/app/server/uv.lock /usr/app/server/uv.lock

ENV PATH="/usr/app/server/.venv/bin:$PATH"

EXPOSE 8000

CMD ["uvicorn", "api.app:app", "--host", "0.0.0.0", "--port", "8000"]