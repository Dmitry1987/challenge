# let's say we build things so using multistage 
FROM python:3.12-slim as builder
WORKDIR /app
COPY main.py . 

# Using distroless base image for least vulnerabilities
FROM gcr.io/distroless/python3-debian12 as runtime
WORKDIR /app
COPY --from=builder /app/main.py .

# the non root stuff preparation would be needed if we didn't use distroless but something like python slim, as runtime image,
# and if it was nginx then also need to take care of cache folders it uses. Example:
# RUN useradd --system --create-home --uid 1001 webserver && chown -R webserver:webserver /app
# USER webserver
# but we don't need it here.

ENTRYPOINT ["python", "/app/main.py"]
CMD ["--port", "8000"]
