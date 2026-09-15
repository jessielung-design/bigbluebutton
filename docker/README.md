# BigBlueButton Docker / GHCR

This repo publishes container images to GitHub Container Registry and can run the in-repo web/GraphQL services with Compose.

Images:

- `ghcr.io/jessielung-design/bigbluebutton` — HTML5 client + learning dashboard (nginx)
- `ghcr.io/jessielung-design/bigbluebutton-graphql-actions`
- `ghcr.io/jessielung-design/bigbluebutton-graphql-middleware`
- `ghcr.io/jessielung-design/bigbluebutton-graphql-server`
- `ghcr.io/jessielung-design/bigbluebutton-export-annotations`

This is **not** a full production BBB node. Media/voice (FreeSWITCH, mediasoup/LiveKit, recordings) still need the official installer or [bigbluebutton/docker](https://github.com/bigbluebutton/docker).

## Run

```bash
cp .env.example .env
docker compose up -d --build
```

- HTML5: http://localhost:8080/html5client/
- Hasura console: http://localhost:8085/console (secret: `bigbluebutton`)

Greenlight (from `ghcr.io/jessielung-design/greenlight`):

```bash
docker compose --profile greenlight up -d
```

## Publish

GitHub Actions workflow `.github/workflows/docker-publish.yml` builds and pushes the GHCR images on push to `v3.0.x-develop` and on version tags. The repository must have `packages: write` permission (default `GITHUB_TOKEN` is enough for `ghcr.io/<owner>/<image>`).
