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

### Unit Tests
`dart test`

### Buildchain
A Docker container is used to imlement the build chain. Helper bin scripts have been provided for actions with the build chain.

#### Executing the buildchain
`./buildchain/bin/build.sh`

#### Shelling into the buildchain
`./buildchain/bin/shell.sh`

### TO DO

- Figure out how to authorize terminus within the buildchain