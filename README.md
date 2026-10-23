# Spark stack

This stack serves a local NVIDIA Nemotron 3.5 Super VL NVFP4 model through
Docker/vLLM and a LiteLLM gateway, with Prometheus and Grafana monitoring.

## Quick start

Copy the example settings and create the local Prometheus credential file:

    cp .env.example .env
    cp litellm-key.example litellm-key.txt

Edit `.env` and set the model, passwords, and image tag. Set
`LITELLM_MASTER_KEY` to a strong value beginning with `sk-`. Then start the
stack:

    docker compose up -d
    docker compose logs -f vllm

The first start downloads the model and may take a long time.

## API

Test from the Spark or a trusted LAN host:

    curl http://<spark-host>:4000/v1/chat/completions \
      -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
      -H "Content-Type: application/json" \
      -d '{"model":"local","messages":[{"role":"user","content":"hello"}]}'

Create a key per app so usage is attributable:

    curl -X POST http://localhost:4000/key/generate \
      -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
      -H "Content-Type: application/json" \
      -d '{"key_alias":"opencode"}'

## Monitoring

Grafana is available at `http://<spark-ip>:3000` using the configured
`GRAFANA_PASSWORD`. Prometheus is pre-wired as its datasource.

The provisioned `DGX Spark LLM usage and savings` dashboard tracks engine-level
and gateway-level usage. vLLM panels show prompt/generation tokens, throughput,
latency, queueing, and KV-cache utilization. LiteLLM panels attribute token
throughput and completed requests to `api_key_alias`, and split input/output
throughput by model.

Use the Grafana time-range selector for usage totals. LiteLLM's
`litellm_total_tokens_metric_total`, `litellm_input_tokens_metric_total`,
`litellm_output_tokens_metric_total`, and `litellm_requests_metric_total`
counters are scraped from the gateway and preserve per-key/model labels.

For the "avoided cost" panel, replace `IN_PRICE` and `OUT_PRICE` with your
reference model's dollars per million tokens:

    sum(increase(vllm:prompt_tokens_total[$__range])) / 1e6 * IN_PRICE
      + sum(increase(vllm:generation_tokens_total[$__range])) / 1e6 * OUT_PRICE

If the metrics differ for your vLLM version, open Grafana Explore and search
for `vllm:`.

## Security

Do not commit `.env`, `litellm-key.txt`, or other credentials. The repository
contains templates only; replace every example password and key before
exposing the API beyond a trusted network.
