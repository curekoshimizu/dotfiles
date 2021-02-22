#!/bin/bash

poetry run black .
poetry run isort
poetry run flake8 .
poetry run mypy .
