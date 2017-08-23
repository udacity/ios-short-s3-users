include Makefile-web
include Makefile-db
include Makefile-secrets

# =============
# Build Images
# =============
images_build: images_build_db images_build_web

images_build_db:
	docker build -t ${DB_IMAGE} -f ${DB_DOCKERFILE} .

images_build_web:
	docker build -t ${WEB_IMAGE} -f ${WEB_DOCKERFILE} .

# =================
# Full Environment
# =================
env_start: db_run web_dev

env_start_clean: db_run_clean web_dev

env_start_seed: db_run_seed web_dev
