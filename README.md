# Docker for ROS Development

## Quickstart
Simply pull the images available from the packages section and refer the actual source code [int-brain-ros](https://github.com/exMachina316/int-brain-ros/) for more steps.

___

This repository provides the ROS2 Docker images for easy development with the [int-brain-stm32](https://github.com/eccentricOrange/int-brain-stm32) project.

This documentation is split into four parts:

- [List of features and images](#list-of-ros2-features-and-images)
- [Instructions for everyone (GHCR authentication)](#authenticating-to-github-container-registry)
- [How to use an image](#pulling-an-image)
- [How to build an image](#building-an-image)

> [!NOTE]
> This repository uses GitHub Actions for CI/CD. Further documentation on how we have implemented this is available in the [CI/CD documentation](/.github/workflows/README.md).

## List of ROS2 Features and Images

| Image name | Base image | Intended target | Features |
| --- | --- | --- | --- |
| `int_brain_common` | [`ros:jazzy-ros-base`](https://hub.docker.com/_/ros/) | AMD\_64 Host PC and Aarch64 SBC | - Basic ROS2 Jazzy installation with common packages <br> - Privileged `ubuntu` user |
| `int_brain_host` | `int_brain_common:amd64` | AMD\_64 Host PC | - PlotJuggler <br> - Gazebo Harmonic <br> - Join state publisher GUI |
| `int_brain_sbc` | `int_brain_common:aarch64` | Aarch64 SBC | I/O-related packages |


## Authenticating to GitHub Container Registry
To pull or push images to the GitHub Container Registry, you need to authenticate using a personal access token (PAT) with the `write:packages` and `repo` scopes.

Brief steps are given below, but you can find more detailed instructions in the [GitHub documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-with-a-personal-access-token-classic).
1.  Create a personal access token (PAT) with the required scopes.
2.  Log in to the GitHub Container Registry using the following command:

    ```bash
    echo <YOUR_PAT> | docker login ghcr.io -u <YOUR_GITHUB_USERNAME> --password-stdin
    ```

3.  Verify that you are logged in by running:

    ```bash
    docker info
    ```


## Pulling an image

To download a pre-built image from GitHub Container Registry (ghcr.io), use the following command:

```bash
docker pull ghcr.io/eccentricorange/<image_name>:<tag>
```

Replace `<image_name>` with the desired image name (e.g., `int_brain_host`). For example:

```bash
docker pull ghcr.io/eccentricorange/int_brain_host:amd64-v1.0
```

> [!IMPORTANT]
> Please be mindful of the tag you are pulling. The `latest` tag is not used in this repository, so you need to provide a specific version tag (e.g., `v3.0`).

## Building an image
Since this repository uses CI/CD builds, certain considerations must be taken into account when building images:

1.  **Dependant images**

    Certain images depend on other images. For example, `int_brain_host` depends on `int_brain_common`. If you want to build `int_brain_host`, you need to build `int_brain_common` first.

    In the dependant image's Dockerfile, you can specify the base image as follows:

    ```dockerfile
    FROM ghcr.io/eccentricorange/int_brain_common:amd64-v1.0
    ```

    Again, please be mindful of the tag you are using. If you update a base image, and you want the changes to reflect in the dependant image, you need to rebuild the dependant image **with the correct tag of the base image**.

1.  **Online builds must be tagged**

    The CI/CD system **will not initiate builds** if the image is not tagged. Moreover, your tag must follow the [SemVer](https://semver.org/spec/v2.0.0.html) format. For example: `v3`, `v3.0`, `v3.1.0`. So your tag names must start with `v` and be followed by a version number.

    Once a commit has been tagged and pushed to the repository, the CI/CD system will automatically build the image and push it to the GitHub Container Registry. It will attempt to do this regardless of the branch you are on.

1.  **Building locally**

    If you want to build locally, you're free to use any tags you like, however you should be mindful of dependant images and their tags. You can build an image using the following command:

    ```bash
    docker build -t ghcr.io/eccentricorange/<image_name>:<tag> -f <path/to/Dockerfile> <build_context>
    ```

    Replace `<image_name>` with the desired image name, `<tag>` with the version tag, and `<build_context>` with the directory containing the Dockerfile. For example, to build the `humble` image:

    ```bash
    docker build -t ghcr.io/eccentricorange/int_brain_common:amd64-v1.0 -f src/int_brain_common.Dockerfile .
    ```

1.  **Pushing the image**

    After building the image, you can push it to the GitHub Container Registry using the following command:

    ```bash
    docker push ghcr.io/eccentricorange/<image_name>:<tag>
    ```

    For example, to push the `humble` image:

    ```bash
    docker push ghcr.io/eccentricorange/int_brain_common:amd64-v1.0
    ```

> [!IMPORTANT]
> Avoid using the `latest` tag.

### Recommendations for tagging images
Suggestions for filling in the SemVer version tag.

Let us assume that the latest image before you start working is `v3.14`. Therefore, the next image you target to release will be `v3.15`.

However, the CI/CD workflow requires that you tag every commit where you want to build an image AND GitHub requires commit tags to be unique. If you wish to use the online builds to test your changes, you can use the `dev*` tags. For example, you can tag your commit as `dev3.15.0` or `dev3.15.1`. This way, you can test your changes without affecting the main versioning scheme.

When you are ready to release the next version (most likely a merge commit), you can tag it as `v3.15.0` or `v3.15`. This will trigger the CI/CD workflow to build the image with the correct version tag.

> [!NOTE]
> - `v*` tags should only be used on the `master` branch.
> - `dev*` tags may be used on any branch (including `master`).


## Acknowledgements
The Devcontainer system of this project was inspired by the Wheelchair project at [RRC, IIIT Hyderabad](https://github.com/Smart-Wheelchair-RRC/). Please see their project [DockerForDevelopment](https://github.com/Smart-Wheelchair-RRC/DockerForDevelopment).