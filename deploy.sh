#!/bin/sh

source ./.env && \
    gcloud builds \
    submit --config cloudbuild.yaml \
    && gcloud run deploy bank \
    --allow-unauthenticated \
    --image gcr.io/side-projects-301300/bank:latest \
    --platform managed --region us-east1 \
    --set-env-vars DB_URL=$DB_URL,SECRET_KEY_BASE=$SECRET_KEY_BASE
