# pantheon-site-status

## Repo Structure

The repo is divided into two parts:

- static website
- site data gatherer

## Static Site

Review [site/readme.md](./site/README.md).

## Pantheon Site Evaluator

The evaluator is a Dart script. The script performs these high-level actions:

1. Gather site information from Pantheon for each site of a Pantheon organizaiton.
2. Gathers additional data from worpdress.org
3. Evaluates the information gathered for each site and determines potential issues.
4. Produces a detailed JSON file containing the gathered information and potential issues.

### Running the Evaluator from the Command Line

This example can be used to update the json file expected by the Vue app.

```zsh
terminus auth:login --email=username@clockwork.com
dart pub get --directory=evaluator
dart ./evaluator/bin/main.dart --results-file=./site/data/sites.json
```

### Local Dev Prerequisites

- terminus (from Pantheon)

### Unit Tests

```zsh
cd evaluator
dart test
```

## Playbooks

### Updating Supported PHP Versions

1. Open this file `evaluator/lib/evaluator.dart`
2. Edit the contents of the variable `_phpVersions`

### Updating S3 bucket with New Data

```zsh
dart ./evaluator/bin/main.dart --results-file=./site/data/sites.json
cd site
npm run build
npm run generate
aws s3 sync ./dist/ ${{ vars.AWS_S3_BUCKET }} --delete --acl public-read
```

## In Progress Work -- Items not done yet

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

#### TO DO

- Figure out how to authorize terminus within the buildchain
