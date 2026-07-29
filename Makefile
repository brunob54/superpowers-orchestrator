SYNC := tools/sync-dev-install.sh
# install directory to sync into; empty means "resolve from the plugin registry"
TARGET ?=

SYNC_ARGS := $(if $(TARGET),--target "$(TARGET)",)

.PHONY: help install-dev install-dev-dry

help:  ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

install-dev:  ## Sync this working tree into the installed plugin in ~/.claude
	@$(SYNC) $(SYNC_ARGS)

install-dev-dry:  ## Show what install-dev would change, without writing
	@$(SYNC) --dry-run $(SYNC_ARGS)
