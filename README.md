# GitHub Action for kustomize-diff

This [action](https://help.github.com/en/actions) can be used in any repository that uses [kustomize](https://kustomize.io/).

# Summary

The steps the action takes are as follows:

- Store the output of `kustomize build` (for each environment) on the current branch in a temporary location.
- Store the output of `kustomize build` (for each environment) on the master branch in a temporary location.
- Based on the two outputs above it performs a git diff and stores the output in a variable called `escaped_output`.

This action can be combined with [unsplash/comment-on-pr](https://github.com/unsplash/comment-on-pr) to comment the output to the PR.

# Example configuration

The below example will run `kustomize-diff` against your branch and commit the changes due to be applied back to your Pull Request.

```
name: kustomize-diff
on:
  pull_request:
    paths:
      - 'kustomize/**'

jobs:
  kustomize-diff:
    runs-on: ubuntu-latest
    steps:
      - id: checkout
        uses: actions/checkout@v2
        with:
          fetch-depth: 0
      - id: kustomize-diff
        uses: swade1987/github-action-kustomize-diff@master
        with:
          root_dir: "./my-custom-path"
          max_depth: "2"
      - id: comment
        uses: unsplash/comment-on-pr@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          msg: ${{ steps.kustomize-diff.outputs.diff }}
          check_for_duplicate_msg: false
```

## Features

- Commits must meet [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
    - Automated with GitHub Actions ([commit-lint](https://github.com/conventional-changelog/commitlint/#what-is-commitlint))
- Pull Request titles must meet [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
    - Automated with GitHub Actions ([pr-lint](https://github.com/amannn/action-semantic-pull-request))
- Commits must be signed with [Developer Certificate of Origin (DCO)](https://developercertificate.org/)
    - Automated with GitHub App ([DCO](https://github.com/apps/dco))

## Getting started

Before working with the repository it is **mandatory** to execute the following command:

```
make initialise
```

The above command will install the `pre-commit` package and setup pre-commit checks for this repository including [conventional-pre-commit](https://github.com/compilerla/conventional-pre-commit) to make sure your commits match the conventional commit convention.

## Contributing to the repository

To contribute, please read the [contribution guidelines](CONTRIBUTING.md). You may also [report an issue](https://github.com/swade1987/kubernetes-toolkit/issues/new/choose).
