#FROM python:3.7-alpine
FROM python:3.7

ENV PYTHONDONTWRITEBYTECODE=1 \
	PYTHONUNBUFFERED=1

WORKDIR /code

RUN pip install --upgrade pip && \
	pip install pipenv

COPY ./Pipfile /code/Pipfile

RUN pipenv install --deploy --system --skip-lock --dev

COPY . /code/

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "tutorial.wsgi"]
