# pantheon-site-status

## Repo Structure

The repo is divided into two parts:

- static website
- site data gatherer

## Static Site

Kevin add details here.

## Pantheon Site Evaluator

The evaluator is a Dart script. The script performs these high-level actions:

1. Gather site information from Pantheon for each site of a Pantheon organizaiton.
2. Gathers additional data from worpdress.org
3. Evaluates the information gathered for each site and determines potential issues.
4. Produces a detailed JSON file containing the gathered information and potential issues.

### Running the Evaluator from the Command Line

```zsh
dart ./evaluator/bin/main.dart -h
```

### Local Dev Prerequisites

- Dart version < 2.0
- terminus (from Pantheon)

### Unit Tests

```zsh
cd evaluator
dart test
```

### Buildchain

A Docker container is used to implement the buildchain. Helper bin scripts have been provided for actions with the build chain.

#### Executing the buildchain

```zsh
./bin/build.sh
```

#### Shelling into the buildchain

```zsh
./bin/shell.sh
```

### TO DO

- Figure out how to authorize terminus within the buildchain

## Change Cases

### Updating Supported PHP Versions

1. Open this file `evaluator/lib/evaluator.dart`
2. Edit the contents of the variable `_phpVersions`
