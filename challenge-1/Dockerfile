ARG runtime_image="gcr.io/distroless/python3-debian12"
# use 'debug' tag for container with shell
ARG image_tag="nonroot"

# let's say we build things, so using multistage 
FROM python:3.12-slim AS builder
WORKDIR /app
COPY main.py . 
# just a file we write during CI run, which doesn't exist in repo, sometimes it's useful
COPY file-from-ci .

# Using distroless base image for least vulnerabilities
FROM ${runtime_image}:${image_tag} AS runtime
WORKDIR /app
COPY --from=builder /app/main.py .
COPY --from=builder /app/file-from-ci .
# set the nonroot user ownership on our files if it's that kind of image
RUN if [ "${image_tag}" == "nonroot" ]; then chown 65532:65532 -R /app ; fi

# the 'non root user' preparation would be needed if we didn't use distroless, as runtime image,
# and if it was nginx then also need to take care of cache folders it uses. Example:
# RUN useradd --system --create-home --uid 1001 webserver && chown -R webserver:webserver /app
# USER webserver
# but we don't need it here.

ENTRYPOINT ["python", "/app/main.py"]
CMD ["--port", "8000"]
