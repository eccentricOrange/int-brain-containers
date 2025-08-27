# Understanding the CI/CD workflows

## Desired behaviour
1.  The user creates a new branch for their changes.
1.  The user commits their changes to the branch, with a relevant tag.
1.  The user pushes the branch to the remote repository.
1.  The CI/CD system detects the new tag and starts building the image.
1.  If the build is successful, the image is pushed to the GitHub Container Registry.
1.  The user can then pull the image from the registry and use it.

### Key features
-   Dependant images are built in the correct order.
-   Images are built with the correct tags.
-   The CI/CD system is triggered by tags, not pushes to branches or pull requests.
-   Upon any failure, the system will exit gracefully and not proceed with downstream dependant builds.

## Overview of the main workflow
This is a high-level understanding of the workflow described in [build.yaml](/.github/workflows/build.yaml).

1.  The workflow is triggered when a tag starting with `v` (or `dev`) is pushed to the repository.

1.  Next, the workflow looks for the Git tag. If it finds a tag that starts with `v`/`dev`, records this to a variable, so that it may be used later in the workflow.

1.  The remainder of the build is split into two sections, building the common image, and building specific images for the Host and the SBC from that.

    By default, all of these sections are configured as [matrix strategies](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/running-variations-of-jobs-in-a-workflow). Although some sections have only one entry, this allows for easy expansion in the future.

## Overview of the reusable workflow
It quickly became evident that several steps in the workflow were repetitive, so the majority of the actual work was refactored into a [reusable workflow](https://docs.github.com/en/actions/sharing-automations/reusing-workflows). This is described in [build-workflow.yaml](/.github/workflows/build-workflow.yaml), and is briefly explained below.

This workflow is triggered by the main workflow, and receives the following inputs:

| Input | Description | Default |
| --- | --- | --- |
| `build_context` | The build context for the Dockerfile | - |
| `image_name` | The target name of the image to build | - |
| `image_version` | The version tag of the image to build | - |
| `runs_on` | The GitHub runner to use for the build | `ubuntu-latest` |

First, code is checked out, [buildx is setup](https://github.com/docker/setup-buildx-action/tree/v3/), and [GHCR is authenticated](https://github.com/docker/setup-buildx-action/tree/v3/).

Finally, the actual image is built and (if successful) pushed to the GitHub Container Registry, using the [`docker/build-push-action`](https://github.com/docker/build-push-action/tree/v6/) action.


## Deeper dive into the main workflow
Here, we discuss only the potentially confusing parts of the main workflow, which is described in [build.yaml](/.github/workflows/build.yaml).

You are encouraged to read the [GitHub Actions documentation](https://docs.github.com/en/actions) for more information on how GitHub Actions work, how to write workflows, and reference for syntax. If you use VS Code to write workflows, the [GitHub Actions extension](https://marketplace.visualstudio.com/items?itemName=GitHub.vscode-github-actions) is useful.

### Check conditions and set variables
We only trigger the workflow on the push of certain tags:

```yaml
on:
  push:
    tags:
      - 'dev*'
      - 'v*'
```

### Setting the image version
This simply involves obtaining the Git tag and setting it as an environment variable for later use:

```yaml
- name: Set image version
  id: set_version
  run: |
    echo "image_version=${{ github.ref_name }}" >> $GITHUB_OUTPUT
```

### Building the images
While there are several sections as described earlier, we shall dive deeper into one of these as exposition. Consider the "Stage 2: Specific Images with packages" section.

```yaml
# Stage 2: Specific Images with packages
  specific:
    needs: [get-version, int-brain-common]
    name: Specific Images with packages
    permissions:
      packages: write
      contents: read
    strategy:
      matrix:
        config:
          - { build_context: './src', image_name: 'int_brain_host', image_version: "amd64-${{ needs.get-version.outputs.image_version }}", runs_on: ubuntu-24.04 }
          - { build_context: './src', image_name: 'int_brain_sbc', image_version: "aarch64-${{ needs.get-version.outputs.image_version }}", runs_on: ubuntu-24.04-arm }
    uses: ./.github/workflows/build-workflow.yaml
    with:
      build_context: ${{ matrix.config.build_context }}
      image_name: ${{ matrix.config.image_name }}
      image_version: ${{ matrix.config.image_version }}
      runs_on: ${{ matrix.config.runs_on }}
```

Let's break this down:
-   `needs`: This job depends on the `changes` job and the `get-version` and `int-brain-common` jobs. It will only run if these jobs are successful. This ensures that dependant images are built in the correct order.
-   `permissions`: This job requires write access to packages (to push the built images) and read access to contents (to read the repository).
-   `strategy`: This defines a matrix strategy for the job. In this case, we have two configurations:
    -   `int_brain_host`: The image for the Host PC
    -   `int_brain_sbc`: The Aarch64 image for the remote SBC
-   `uses`: This specifies that the job will use the reusable workflow defined in [build-workflow.yaml](/.github/workflows/build-workflow.yaml).
-   `with`: This passes the necessary parameters to the reusable workflow, including the build context, image name, image version, and the runner to use.

Note the matrix system:
```yaml
strategy:
  matrix:
    config:
      - { build_context: './src', image_name: 'int_brain_host', image_version: "amd64-${{ needs.get-version.outputs.image_version }}", runs_on: ubuntu-24.04 }
      - { build_context: './src', image_name: 'int_brain_sbc', image_version: "aarch64-${{ needs.get-version.outputs.image_version }}", runs_on: ubuntu-24.04-arm }
```

In this system, we specify one or more configurations for the job. Each configuration corresponds to one resulting image. The reusable workflow will be run for each configuration, allowing us to build multiple images in parallel by just adding one more entry to the `config` list.

Please consult the [GitHub Actions documentation](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/running-variations-of-jobs-in-a-workflow) for more information on matrix strategies and syntax.