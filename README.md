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
```
docker build -t sinfo .
docker run -i -t sinfo
```

### Unit Tests
`dart test`

