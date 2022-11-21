# services.sh

A simple user-mode service manager written in bash.

## Basic service

```bash
#!/bin/bash

NAME="loop"
DESCRIPTION="loopin'"

Execute() {
	while true; do
		echo "Hello $(date)"
		sleep 15
	done
}

Status() {
	echo "ok"
}

Status.Message() {
	echo "Working with no problems."
}
```
