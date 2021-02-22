#!/bin/bash

poetry run black .
poetry run isort -y
poetry run flake8 .
poetry run mypy .
