FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl \
    libicu-dev \
    libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*

# Extracting so the binary is at /app/Radarr/Radarr
RUN curl -L -o radarr.tar.gz https://github.com/Radarr/Radarr/releases/download/v6.2.0.10390/Radarr.develop.6.2.0.10390.linux-core-x64.tar.gz \
    && tar -xzf radarr.tar.gz -C /app \
    && rm radarr.tar.gz

WORKDIR /app/Radarr

# Ensure the native binary is executable
RUN chmod +x Radarr

RUN useradd -r -u 1001 appuser && chown -R appuser /app
USER appuser

ENV CORECLR_ENABLE_PROFILING=0
ENV CORECLR_PROFILER={846F5F1C-F9AE-4B07-969E-05C26BC060D8}
ENV DD_SERVICE=radarr
ENV DD_LOGS_INJECTION=true
ENV DD_RUNTIME_METRICS_ENABLED=true
ENV DD_TRACE_AGENT_URL=unix:///var/run/datadog/apm.socket
ENV DD_DOGSTATSD_URL=unix:///var/run/datadog/dsd.socket

ARG DD_ENV=production
ENV DD_ENV=${DD_ENV}

ARG DD_VERSION=dev
ENV DD_VERSION=${DD_VERSION}
ENV CORECLR_PROFILER_PATH=/datadog/Datadog.Trace.ClrProfiler.Native.so
ENV DD_DOTNET_TRACER_HOME=/datadog

EXPOSE 7878

# Use the native binary instead of 'dotnet Radarr.Host.dll'
ENTRYPOINT ["./Radarr", "-nobrowser", "-data=/config"]

# Added -data=/config to ensure it uses your mounted volume
# ENTRYPOINT ["dotnet", "Radarr.Host.dll", "-nobrowser", "-data=/config"]