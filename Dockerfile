FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY src/ src/
COPY *.props *.targets global.json ./
RUN dotnet publish src/Radarr.sln -c Release -o /app/publish --no-self-contained

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

ARG DD_TRACER_VERSION=3.12.0
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && curl -Lo /tmp/datadog-dotnet-apm.deb \
       https://github.com/DataDog/dd-trace-dotnet/releases/download/v${DD_TRACER_VERSION}/datadog-dotnet-apm_${DD_TRACER_VERSION}_amd64.deb \
    && curl -Lo /tmp/dd-checksums.txt \
       https://github.com/DataDog/dd-trace-dotnet/releases/download/v${DD_TRACER_VERSION}/checksums.txt \
    && grep "datadog-dotnet-apm_${DD_TRACER_VERSION}_amd64.deb" /tmp/dd-checksums.txt | sha256sum -c - \
    && dpkg -i /tmp/datadog-dotnet-apm.deb \
    && rm /tmp/datadog-dotnet-apm.deb /tmp/dd-checksums.txt \
    && apt-get purge -y curl && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/publish .

RUN useradd -r -u 1001 appuser && chown -R appuser /app
USER appuser

ENV CORECLR_ENABLE_PROFILING=1
ENV CORECLR_PROFILER={846F5F1C-F9AE-4B07-969E-05C26BC060D8}
ENV CORECLR_PROFILER_PATH=/opt/datadog/Datadog.Trace.ClrProfiler.Native.so
ENV DD_DOTNET_TRACER_HOME=/opt/datadog
ENV DD_SERVICE=radarr
ENV DD_LOGS_INJECTION=true
ENV DD_RUNTIME_METRICS_ENABLED=true
ENV DD_TRACE_AGENT_URL=unix:///var/run/datadog/apm.socket
ENV DD_DOGSTATSD_URL=unix:///var/run/datadog/dsd.socket

ARG DD_ENV=production
ENV DD_ENV=${DD_ENV}

ARG DD_VERSION=dev
ENV DD_VERSION=${DD_VERSION}

EXPOSE 7878
ENTRYPOINT ["dotnet", "Radarr.dll"]
