FROM python:3.8-slim

ENV PYTHONUNBUFFERED True
ENV PORT 8080

ENV APP_HOME /app
WORKDIR $APP_HOME
COPY . ./

RUN pip install Flask gunicorn

CMD gunicorn --chdir app --bind :$PORT \
  --workers 1 \
  --threads 8 \
  --timeout 0 \
  app:app
