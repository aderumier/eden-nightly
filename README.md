<h1 align="left">
  <br>
  <b>Unofficial Eden Nightly Release</b>
  <br>
</h1>

[![GitHub Release](https://img.shields.io/github/v/release/pflyly/eden-nightly?label=Current%20Release)](https://github.com/pflyly/eden-nightly/releases/latest)
[![GitHub Downloads](https://img.shields.io/github/downloads/pflyly/eden-nightly/total?logo=github&label=GitHub%20Downloads)](https://github.com/pflyly/eden-nightly/releases/latest)
[![CI Build Status](https://github.com//pflyly/eden-nightly/actions/workflows/build-nightly.yml/badge.svg)](https://github.com/pflyly/eden-nightly/releases/latest)

## Release Overview

This repository provides **unofficial nightly releases** of **Eden** for the following platforms:

- **Linux** (`x86_64`, `aarch64`)
- **Android**
- **Windows-MSVC** (`x86_64`)
- **Windows-CLANG** (`x86_64`)
- **Windows-MSYS2** (`x86_64`, `arm64`)
- **MacOS** (`arm64`)
- **FreeBSD** (`amd64`)
- **Solaris** (`amd64`)

>[!WARNING]
>**This repository is not affiliated with the official Eden development team. It exists solely to provide an easy way for users to try out the latest features from recent commits.**
>
>**These builds are experimental and may be unstable. Use them at your own risk, and please do not report issues from these builds to the official channels unless confirmed on official releases.**

---------------------------------------------------------------
### 🚀 PGO Optimized Builds

Profile-Guided Optimization (**PGO**) is now being tested via clang for Eden nightly.  
PGO builds can improve runtime performance by **5–10% FPS** compared to non-PGO builds, depending on the game and workload.

For now, PGO builds are provided alongside regular builds. 
They are extremely experimental with unstable performance boost across different builds even with the same game. 

---------------------------------------------------------------
### 🐧 Linux Builds

The builds for Linux are built with several CPU-specific compliler optimization flags targeting:

- **Steam Deck** — optimized for Steam Deck’s APU architecture (AMD Zen 2)
- **ROG ALLY & Similar Handhelds** — optimized for next-gen handhelds APUs (AMD Zen 4)
- **Modern x86_64 CPUs** — optimized for `x86-64-v3`, targets CPUs from roughly 2015 and later for a performance boost (via the Common Build)
- **Legacy x86_64 CPUs** — compatible with baseline `x86-64`, means can run on virtually all 64-bit x86 processors (via the Legacy Build)
- **AArch64 devices** — compatible with `aarch64` architecture

AppImages built using [**Sharun**](https://github.com/VHSgunzo/sharun) are bundled with **Mesa drivers** to ensure maximum compatibility — similar to Eden’s official releases and may include the latest fixes for certain games (though untested). These builds should work on any linux distro.

A newly added **AppBundle** version, built with [**pelf**](https://github.com/xplshn/pelf), serves as an alternative to AppImage. It's a lightweight format written in Go and intended for broader Linux compatibility.

---------------------------------------------------------------

### 🤖 Android Builds

Eden nightly for Android is available in four versions:

- **Replace** Build
  
Shares the same application ID as the official Eden release. Installing this version will replace the official app on your device. It appears as "**Eden**" on the home screen.

- **Coexist** Build
  
Uses a nightly application ID, allowing it to coexist with the official Eden release. It appears as "**Eden Nightly**" on the home screen.

- **Optimized** Build
  
Using com.miHoYo.Yuanshen for application ID to enable device dependent features such as AI frame generation. It appears as "**Eden Optimized**" on the home screen.

- **ChromeOs** Build

Android x86_64 build for devices running Chrome/FydeOS, AVD emulators, or certain Intel Atom Android devices.

- **Legacy** Build
  
Apply patches that improve compatibility with older GPUs (e.g. Snapdragon 865) at the cost of performance. It appears as "**Eden Legacy**" on the home screen.
