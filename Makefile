.DEFAULT_GOAL := default

.PHONY: default bootstrap lint check

default:
	@command -v mise >/dev/null 2>&1 || { echo "mise is not installed yet. Run: make bootstrap"; exit 1; }
	@mise run

bootstrap:
	@scripts/switch_host.sh

lint:
	@command -v mise >/dev/null 2>&1 || { echo "mise is not installed yet. Run: make bootstrap"; exit 1; }
	@mise run lint

check:
	@command -v mise >/dev/null 2>&1 || { echo "mise is not installed yet. Run: make bootstrap"; exit 1; }
	@mise run check
