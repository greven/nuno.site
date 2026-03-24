# Makefile for nuno.site remote server management
#
# Reads VPS_HOST and VPS_USER from the local .env file automatically.
# Usage: make <target>

# Load VPS connection details from .env
VPS_HOST := $(shell grep -m1 '^VPS_HOST=' .env | cut -d= -f2)
VPS_USER := $(shell grep -m1 '^VPS_USER=' .env | cut -d= -f2)

SSH      := ssh -t $(VPS_USER)@$(VPS_HOST)
APP      := site
APP_DIR  := /opt/$(APP)
DB_PATH  := /var/lib/$(APP)/$(APP).db

.PHONY: help logs status stats restart current releases rollback console database health secrets pre-commit pre-deploy deploy

help: ## Show this help
	@echo ""
	@echo "nuno.site remote commands — connected to $(VPS_USER)@$(VPS_HOST)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""

logs: ## Stream live application logs (Ctrl+C to stop)
	$(SSH) "journalctl -u $(APP) -f --output=cat"

status: ## Show current service status and active release
	$(SSH) "sudo systemctl --no-pager status $(APP) && echo '' && echo 'Current release:' && readlink $(APP_DIR)/current && echo 'Previous release:' && readlink $(APP_DIR)/previous 2>/dev/null || echo '(none)'"

stats: ## Show VPS CPU load, memory stats, and disk space in MB
	$(SSH) "echo 'CPU load (1m/5m/15m):'; awk '{printf \"  %s / %s / %s\\n\", \$$1, \$$2, \$$3}' /proc/loadavg; echo ''; awk '/MemTotal/ {total=\$$2} /MemAvailable/ {avail=\$$2} END {used=total-avail; printf \"Memory (MB):\\n  current %.0f / available %.0f (total %.0f)\\n\", used/1024, avail/1024, total/1024}' /proc/meminfo; echo ''; df -m / | awk 'NR==2 {printf \"Disk / (MB):\\n  current %s / available %s (total %s, used %s)\\n\", \$$3, \$$4, \$$2, \$$5}'"

restart: ## Restart the application service
	$(SSH) "sudo systemctl restart $(APP) && sleep 2 && sudo systemctl is-active $(APP)"

current: ## Show the currently active release
	$(SSH) "basename \$$(readlink $(APP_DIR)/current)"

releases: ## List all available releases on the server
	$(SSH) "ls -1t $(APP_DIR)/releases/"

rollback: ## Roll back to previous release, or to VERSION (e.g. make rollback VERSION=v1.2.3)
	$(SSH) " \
		CURRENT=\$$(readlink $(APP_DIR)/current); \
		if [ -n '$(VERSION)' ]; then \
			TARGET=$(APP_DIR)/releases/$(VERSION); \
			if [ ! -d \"\$$TARGET\" ]; then \
				echo \"Release $(VERSION) not found. Available releases:\"; \
				ls $(APP_DIR)/releases/; \
				exit 1; \
			fi; \
		else \
			TARGET=\$$(readlink $(APP_DIR)/previous 2>/dev/null); \
			if [ -z \"\$$TARGET\" ]; then \
				echo 'No previous release found. Available releases:'; \
				ls $(APP_DIR)/releases/; \
				exit 1; \
			fi; \
		fi; \
		echo \"Rolling back:\"; \
		echo \"  From: \$$CURRENT\"; \
		echo \"  To:   \$$TARGET\"; \
		ln -sfn \"\$$TARGET\" $(APP_DIR)/current && \
		sudo systemctl restart $(APP) && \
		sleep 2 && \
		sudo systemctl is-active $(APP) && \
		echo 'Rollback complete.' \
	"

console: ## Open a remote shell on the running node
	$(SSH) "$(APP_DIR)/current/bin/$(APP) remote"

database: ## Open an interactive SQLite shell on the production database
	$(SSH) "sqlite3 $(DB_PATH)"

health: ## Check the application health endpoint
	$(SSH) "curl -sf http://localhost:4000/health && echo ' — healthy' || echo 'Health check failed'"

secrets: ## Print all server .env secrets (values masked)
	@echo ""
	@echo "Secrets from $(APP_DIR)/.env on $(VPS_HOST):"
	@echo ""
	@ssh $(VPS_USER)@$(VPS_HOST) "grep -v '^\s*#' $(APP_DIR)/.env | grep '='" | while IFS='=' read -r key value; do \
		if [ -z "$$value" ]; then \
			printf "  \033[36m%-30s\033[0m (empty)\n" "$$key"; \
		elif [ $${#value} -le 4 ]; then \
			printf "  \033[36m%-30s\033[0m ****\n" "$$key"; \
		else \
			masked=$$(printf '%s' "$$value" | cut -c1-4); \
			printf "  \033[36m%-30s\033[0m %s****\n" "$$key" "$$masked"; \
		fi; \
	done
	@echo ""

pre-commit: ## Run pre-commit checks (e.g. mix format, mix credo, etc.)
	mix precommit

pre-deploy: pre-commit ## Pre-deployment steps (e.g. run tests, etc.)
	mix test

deploy: pre-deploy ## Deploy a new release (e.g. make deploy, make deploy TYPE=minor, make deploy TYPE=major)
	mix bump $(or $(TYPE),patch)
