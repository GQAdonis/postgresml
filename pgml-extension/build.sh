#!/bin/bash

docker buildx build --push \
--platform linux/amd64 -f Dockerfile \
--tag tribehealth/postgres-supabase-ml:v0.0.1 .