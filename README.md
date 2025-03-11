# Kustomize Diff GitHub Action

This GitHub Action builds and compares Kustomize configurations between the base and head of a Pull Request, posting the differences as a PR comment. This helps reviewers easily identify configuration changes in Kubernetes manifests.

## Why Use This Action?
Managing Kubernetes configurations across multiple environments and PRs can be challenging. This action automatically generates and posts clear diffs of your Kustomize changes directly in your PR comments. This helps:

- 🔍 **Catch Configuration Mistakes** - Easily spot unintended changes before they hit production
- ⏱️ **Speed Up Reviews** - Reviewers can instantly see what's changing without checking out the code
- 🔄 **Validate Changes** - Confirm your Kustomize overlays are working as expected
- 📝 **Document Changes** - Automatically track and document configuration changes in PR history

## Features

- Automatically builds Kustomize configurations from both PR branches
- Generates a diff showing what would actually change upon merge (not just differences between branches)
- Intelligently handles parallel changes to base and feature branches
- Configurable root directory and search depth for Kustomize files
- Commits must meet [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
  - Automated with GitHub Actions ([commit-lint](https://github.com/conventional-changelog/commitlint/#what-is-commitlint))
- Pull Request titles must meet [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
  - Automated with GitHub Actions ([pr-lint](https://github.com/amannn/action-semantic-pull-request))
- Commits must be signed with [Developer Certificate of Origin (DCO)](https://developercertificate.org/)
  - Automated with GitHub App ([DCO](https://github.com/apps/dco))

## How It Works
Unlike simple diff tools, this action:

1. Builds Kustomize output from the base branch
1. Creates a temporary merge of the head branch into base (simulating the actual PR merge)
1. Builds Kustomize output from the merged state
1. Compares these outputs to show exactly what would change after merging

This approach correctly handles cases where changes have been made to the base branch in parallel to the feature branch, avoiding misleading diffs that incorrectly suggest changes would be reverted.

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `base_ref` | Reference (branch/SHA) for PR base | Yes | `${{ github.base_ref }}` |
| `head_ref` | Reference (branch/SHA) for PR head | Yes | `${{ github.head_ref }}` |
| `pr_num` | Pull Request number/ID | Yes | `${{ github.event.number }}` |
| `token` | GitHub token for authentication | Yes | `${{ github.token }}` |
| `root_dir` | Root directory containing kustomize files | No | `./kustomize` |
| `max_depth` | Maximum depth to search for kustomization files | No | `2` |

## Outputs

| Name | Description |
|------|-------------|
| `diff` | Generated diff between kustomize built head and base |

## Usage

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

## Contributing to the repository

To contribute, please read the [contribution guidelines](CONTRIBUTING.md). You may also [report an issue](https://github.com/swade1987/kubernetes-toolkit/issues/new/choose).
