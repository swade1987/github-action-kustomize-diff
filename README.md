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
    permissions:
      pull-requests: write
      contents: write
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4
        with:
          fetch-depth: 0
      - id: kustomize-diff
        uses: swade1987/github-action-kustomize-diff@v0.2.0
        with:
          root_dir: "./kustomize"
          max_depth: "2"
      - id: comment
        uses: actions/github-script@v7.0.1
        env:
          OUTPUT: ${{ steps.kustomize-diff.outputs.diff }}
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            const rawOutput = process.env.OUTPUT;
            const noDiffMessage = "No differences found between";

            const formattedOutput = rawOutput.includes(noDiffMessage)
              ? `### ${rawOutput}`
              : `### Kustomize Changes\n<details><summary>Show Diff</summary>\n\n\`\`\`diff\n${rawOutput}\n\`\`\`\n</details>`;

            await github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: formattedOutput
            })
```

An example of the commented output can be found [here](https://github.com/swade1987/flux2-kustomize-template/pull/15#issuecomment-2600995488).

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
