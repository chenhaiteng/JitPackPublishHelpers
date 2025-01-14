# JitPackPublishHelpers

This repository provides scripts to help developer publish android library with [JitPack](https://jitpack.io/).

Those scripts includes:
1. setupPublish.zsh -- Help gathering information from project and git to setup publishing block in gradle file. It will invoke setupDemoApp.zsh and updateSDK.zsh automatically.
2. setupDemoApp.zsh -- Help setup demo app by given module.
3. updateSDK.zsh -- Help setup SDK version and update java environment for specific module.

## Quick Start:

### Installation
just download it, and put them into the same folder(ex: /usr/bin or just put it in the root of your android project). 

### Create an Publishable Android Library Project
1. Open Android Studio, create a new project.
2. In the new project, create a new android library module.
3. Init and setup the git repository of the project.
4. In root of project, just execute setupPublish.zsh, then following the commands to finish your setup.