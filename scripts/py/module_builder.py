#!/usr/bin/env python3
"""
module_builder.py
==================

This script provides a simple interface for pulling external modules (e.g. C++
libraries or subprojects) from remote repositories and building them locally.
It is designed to streamline the process of adding third‑party dependencies to
the Lumi codebase. By default it will clone the repository into a specified
destination directory, optionally install dependencies using vcpkg, and build
the project with CMake. This modular approach makes it easy to fetch and
integrate new components without manually copying code or writing bespoke
build scripts.

Usage examples:

    # Clone and build a GitHub repository, installing its dependencies via vcpkg
    python3 lumi/scripts/module_builder.py \
        --repo https://github.com/someuser/somelib.git \
        --dest external \
        --use-vcpkg

    # Clone a private repository and checkout a specific branch
    python3 lumi/scripts/module_builder.py \
        --repo git@github.com:myorg/private_module.git \
        --branch release/1.2.3

The script assumes that you have git, cmake, and (optionally) vcpkg installed
and available on your PATH. If vcpkg is not installed, pass --use-vcpkg
only after installing it separately.
"""

import argparse
import os
import subprocess
import sys


def run_command(cmd, cwd=None):
    """Run a shell command and raise a meaningful error if it fails."""
    try:
        subprocess.run(cmd, cwd=cwd, check=True)
    except subprocess.CalledProcessError as exc:
        print(f"Command failed: {' '.join(cmd)}", file=sys.stderr)
        print(f"Return code: {exc.returncode}", file=sys.stderr)
        sys.exit(exc.returncode)


def clone_repo(repo_url: str, dest_dir: str, branch: str | None = None) -> None:
    """Clone a git repository to dest_dir. If dest_dir exists, skip cloning."""
    if os.path.exists(dest_dir):
        print(f"Repository already cloned at {dest_dir}; skipping clone.")
        return
    print(f"Cloning repository {repo_url} into {dest_dir}…")
    run_command(["git", "clone", repo_url, dest_dir])
    if branch:
        print(f"Checking out branch {branch}…")
        run_command(["git", "checkout", branch], cwd=dest_dir)


def install_deps_vcpkg(module_dir: str) -> None:
    """Install dependencies using vcpkg for a module with a vcpkg.json manifest."""
    manifest_path = os.path.join(module_dir, "vcpkg.json")
    if not os.path.exists(manifest_path):
        print(f"No vcpkg manifest found at {manifest_path}; skipping vcpkg install.")
        return
    print("Installing dependencies via vcpkg…")
    # Use the manifest mode of vcpkg so packages are pulled from vcpkg.json
    run_command(["vcpkg", "install"], cwd=module_dir)


def build_module(module_dir: str, build_dir: str, build_system: str) -> None:
    """Configure and build a module using the specified build system."""
    os.makedirs(build_dir, exist_ok=True)
    print(f"Configuring {module_dir} into {build_dir} using {build_system}…")
    if build_system == "cmake":
        run_command(["cmake", "-S", module_dir, "-B", build_dir])
        print("Building project…")
        run_command(["cmake", "--build", build_dir])
    else:
        raise ValueError(f"Unsupported build system: {build_system}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Clone and build external modules for Lumi.")
    parser.add_argument("--repo", required=True, help="Git repository URL to clone")
    parser.add_argument(
        "--dest",
        default="external",
        help="Destination directory under which to place the cloned module (default: external)",
    )
    parser.add_argument(
        "--branch",
        default=None,
        help="Branch name or tag to checkout after cloning",
    )
    parser.add_argument(
        "--build-system",
        choices=["cmake"],
        default="cmake",
        help="Build system to use (currently only cmake is supported)",
    )
    parser.add_argument(
        "--use-vcpkg",
        action="store_true",
        help="Install dependencies using vcpkg before building",
    )
    args = parser.parse_args()

    module_name = os.path.basename(args.repo).rsplit(".", 1)[0]
    dest_path = os.path.join(args.dest, module_name)
    # Ensure the destination parent exists
    os.makedirs(args.dest, exist_ok=True)
    clone_repo(args.repo, dest_path, args.branch)
    if args.use_vcpkg:
        install_deps_vcpkg(dest_path)
    build_module(dest_path, os.path.join(dest_path, "build"), args.build_system)


if __name__ == "__main__":
    main()