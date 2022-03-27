# aws-helper-scripts

Contains scripts for assuming AWS roles and rotating access keys based on profile name.

The `rotate_key` function in `functions.sh` at minimum should be updated with the correct path to your AWS credentials file. 

`rotate_all_keys.sh` can run automatically as a cron/launchd job if your keys should be rotated within a certain time frame. For this to work, `rotate_key` must have absolute paths to its dependencies (aws, jq, credentials file).

TODO: steps for running periodically in launchd