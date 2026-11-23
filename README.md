# Local AWS Emulator

Localhost-only AWS Emulator for an Apple silicon Mac. The container installs the official `aws-emulator-aarch64.rpm`, keeps signature checks on, caps memory at 2 GiB, and publishes port 9297 only on `127.0.0.1`.

Generated credentials and the CA are written to `~/.aws/emulator/9297` when the emulator starts. They are not part of this repository.

This stand-in is for S3, DynamoDB, SQS, and SNS. It does not evaluate IAM or resource policies. Do not use it to decide whether an application is secure.

## Run

Docker is required. This repository does not publish an image. `bin/up` builds one from the Dockerfile.

```bash
bash bin/up
```

In another shell:

```bash
eval "$(bash bin/emulator-env)"
bash bin/smoke
```

`bin/emulator-env` unsets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, and `AWS_PROFILE`, then points the CLI and SDK at `https://127.0.0.1:9297`.

`bin/smoke` exits before any AWS call when `AWS_ENDPOINT_URL` is unset or is not that local URL. Against a running emulator it checks health (`ok`), account `000000000000`, and a create-then-read on S3, DynamoDB, SQS, and SNS. The same names work on a second run. State is in memory and disappears when the container stops.

Stop the emulator with Ctrl+C in the `bin/up` terminal.
