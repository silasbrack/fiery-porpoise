.PHONY: update-deps init update venv lint format test build
SHELL := /bin/bash

#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_NAME = orchestration
TEST_FOLDER = tests
SYSTEM_PYTHON = python3
VENV = .venv
PYTHON_INTERPRETER = ./$(VENV)/bin/python

#################################################################################
# COMMANDS                                                                      #
#################################################################################

## Create a virtual environment
venv:
	$(SYSTEM_PYTHON) -m venv $(VENV)

## Update dependencies in requirements files
update:
	$(PYTHON_INTERPRETER) -m pip install --upgrade pip wheel setuptools pip-tools pre-commit
	$(PYTHON_INTERPRETER) -m piptools compile --resolver backtracking -o prod-requirements.txt pyproject.toml --generate-hashes --allow-unsafe
	$(PYTHON_INTERPRETER) -m piptools compile --extra dev --resolver backtracking -o dev-requirements.txt pyproject.toml --generate-hashes --allow-unsafe

## Update dependencies in requirements files
upgrade:
	$(PYTHON_INTERPRETER) -m pip install --upgrade pip wheel setuptools pip-tools pre-commit
	$(PYTHON_INTERPRETER) -m pre_commit autoupdate
	$(PYTHON_INTERPRETER) -m piptools compile --upgrade --resolver backtracking -o prod-requirements.txt pyproject.toml --generate-hashes --allow-unsafe
	$(PYTHON_INTERPRETER) -m piptools compile --extra dev --upgrade --resolver backtracking -o dev-requirements.txt pyproject.toml --generate-hashes --allow-unsafe

## Run linter
lint:
	$(PYTHON_INTERPRETER) -m ruff $(PROJECT_NAME)
	$(PYTHON_INTERPRETER) -m ruff $(TEST_FOLDER)

## Run code formatters
format:
	$(PYTHON_INTERPRETER) -m ruff $(PROJECT_NAME) --fix
	$(PYTHON_INTERPRETER) -m ruff $(TEST_FOLDER) --fix
	$(PYTHON_INTERPRETER) -m black $(PROJECT_NAME)
	$(PYTHON_INTERPRETER) -m black $(TEST_FOLDER)

## Run tests
test:
	$(PYTHON_INTERPRETER) -m pytest $(TEST_FOLDER)
	$(PYTHON_INTERPRETER) -m tox run

## Install and check dependencies
install:
	rm -rf .tox
	$(PYTHON_INTERPRETER) -m pip install --upgrade pip setuptools wheel pip-tools pre-commit
	$(PYTHON_INTERPRETER) -m piptools sync dev-requirements.txt prod-requirements.txt
	$(PYTHON_INTERPRETER) -m pip install --editable .
	$(PYTHON_INTERPRETER) -m pre_commit install
	$(PYTHON_INTERPRETER) -m pip check

## Build wheel file to dist folder
build:
	$(PYTHON_INTERPRETER) -m build

#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
.PHONY: help
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
