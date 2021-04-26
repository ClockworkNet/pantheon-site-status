# pantheon-site-status

## Static Site

### More to come!

## Pantheon Site Evaluator

The evaluator is a Flutter script. The script performs these high-level actions:

1. Gather site information from Pantheon for each site of a Pantheon organizaiton.
2. Gathers additional data from worpdress.org
3. Evaluates the information gathered for each site and determines potential issues.
4. Produces a detailed JSON file containing the gathered information and potential issues.

### Running the Evaluator from the Command Line

```dart evaluator/bin/main.dart -h```

### Local Dev Prerequisites
- Dart version < 2.0
- terminus (from Pantheon)

### Docker
The following commands build a static container based and then run it interactively.

When working with docker:

```
docker build -t sinfo ./evaluator
docker build --no-cache -t sinfo ./evaluator


docker run -it --entrypoint=bash sinfo

docker run -it sinfo
```

When working with docker compose:

```
cd evaluator
docker-compose build buildchain

-- more to come -- 

```


### Unit Tests
`dart test`

