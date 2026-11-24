# Ebb

A small Linux desktop app for starting, stopping and watching the moving parts of your dev projects:
servers, databases, emulators, watchers, and the one-off commands you run all the time.

Add your projects in the app. Each one gets a page with:

- **Services**: long-running things (an API server, `npm run dev`, an Android emulator). Start and stop
  them with one click and see whether each one is *Stopped*, *Starting…* or *Running*.
- **Actions**: one-off commands with a Run button (build and install, run tests, open the browser).
  You get a notification when they finish, with a link to the log if they fail.

Services keep running when you close the window. Everything is set up through forms in the app (folder
pickers, an icon picker, status checks, environment variables), saved to a plain TOML file you can also
edit by hand or keep in a dotfiles repo. Everything is also available from the command line.

Built with GTK 4 and libadwaita, so it looks at home on GNOME. It's a single Python file with no
dependencies beyond what GNOME desktops already ship.

## Install

You need Python 3.11+, GTK 4, libadwaita 1.6+ and PyGObject:

| Distro | Command |
|---|---|
| Arch | `sudo pacman -S python-gobject libadwaita` |
| Fedora 41+ | `sudo dnf install python3-gobject libadwaita` |
| Debian 13+ / Ubuntu 24.10+ | `sudo apt install python3-gi gir1.2-adw-1` |

Then:

```bash
git clone https://github.com/Tomiloba21/ebb.git
cd ebb
./install.sh
```

This puts `ebb` in `~/.local/bin` and adds Ebb to your app menu. To remove it: `./install.sh --uninstall`
(your config is kept).

## Set up your projects

In the app:

- **+** in the header (or Ctrl+N) adds a project: a name, its folder, and optional environment variables.
- **Add service** and **Add action** at the bottom of each list open a form for one. The pencil on any row
  edits it, and the form has a Delete button.
- **Edit project** at the top of a page changes or deletes the project.
- The menu has **Environment for all projects**, **Reload config** (Ctrl+R) and **Open config file**.

Saving checks your input (names must be filled in and unique, ports must be numbers) and rewrites
`~/.config/ebb/config.toml`. The previous version is kept as `config.toml.bak`. Comments in the file are not
kept when Ebb saves it, so put notes in the description fields instead.

### The config file

You can also write the file by hand, then press Reload. A minimal project:

```toml
[[project]]
name = "My API"
cwd = "~/code/my-api"

  [[project.service]]
  name = "Server"
  start = "npm run dev"
  port = 3000

  [[project.action]]
  name = "Run tests"
  run = "npm test"
```

Commands run in a bash login shell in the given folder, so `&&`, pipes, `~` and `$VARS` all work, and your
`PATH` from `~/.bash_profile` applies even when Ebb is opened from the app menu.

### Reference

**Top level**

| Key | Meaning |
|---|---|
| `[env]` | Environment variables for every command. |
| `[[project]]` | One per project. Each becomes a page. |

**`[[project]]`**

| Key | Meaning |
|---|---|
| `name` | Shown in the sidebar. Required. |
| `description` | Shown above the services. |
| `cwd` | Folder commands run in. Default `~`. |
| `env` | Environment variables for this project, e.g. `env = { NODE_ENV = "development" }`. |
| `[[project.service]]` | A service (below). |
| `[[project.action]]` | An action (below). |

**`[[project.service]]`**

| Key | Meaning |
|---|---|
| `name` | Required. |
| `start` | Command that runs the service in the foreground. Required. |
| `stop` | Command that stops it. Default: Ctrl-C (SIGINT) to the process Ebb started, then terminate, then kill. |
| `http` | Running when this URL answers with 2xx/3xx. |
| `port` | Running when something listens on this port (if no `http`). On Stop, whatever still listens is terminated, so this also stops a server you started in a terminal. |
| `ready` | Running when this command exits 0, e.g. `adb shell getprop sys.boot_completed \| grep -q 1`. |
| `process` | `pgrep -f` pattern. Counts as started when a matching process exists, even one started outside Ebb. |
| `cwd`, `env` | As for projects. `cwd` is relative to the project's. |
| `description`, `icon` | Subtitle, and an icon name (e.g. `network-server-symbolic`; the app's icon picker lists good ones) or a path to an image. |

How status works: if any of `http`, `port` or `ready` is set, the service is *Running* when all of them pass,
and *Starting…* while its process exists but they don't pass yet. With no checks, it's *Running* while the
process Ebb started is alive.

**`[[project.action]]`**

| Key | Meaning |
|---|---|
| `name` | Required. |
| `run` | Command to run. Required. |
| `highlight` | `true` makes the Run button stand out. |
| `cwd`, `env`, `description`, `icon` | As for services. |

See [`config.example.toml`](config.example.toml) for a web project and an Android project with an emulator.

## Command line

```text
ebb                          open the window
ebb --project NAME           open the window on one project
ebb list                     list projects, services and actions
ebb status [PROJECT]         show service status
ebb start PROJECT [SERVICE]  start one service, or all of a project's
ebb stop PROJECT [SERVICE]   stop one service, or all of a project's
ebb run PROJECT ACTION       run an action and wait for it
```

Names are case-insensitive. Set `EBB_CONFIG` to use a different config file.

Logs and pid files are in `~/.local/state/ebb/<project>/`. Each service and action has a log button in
the window.

### A launcher per project

To get a separate app-menu entry that opens straight on one project, copy the installed desktop file:

```bash
sed -e 's/^Name=Ebb$/Name=My API/' -e 's|^Exec=\(.*\)|Exec=\1 --project "My API"|' \
  ~/.local/share/applications/io.github.tomiloba21.Ebb.desktop > ~/.local/share/applications/ebb-my-api.desktop
```

## Tip: blank dock icons for other apps

If an app you start (an emulator, an AppImage, an Electron app) shows a blank icon in the GNOME dock, its
window isn't matched to any `.desktop` file. Find its window class:

- X11/XWayland windows: run `xprop WM_CLASS` and click the window.
- Native Wayland windows: the class is the app id, shown when you hover over the dock icon.

Then add a `.desktop` file in `~/.local/share/applications/` with `StartupWMClass=<that class>` and an
`Icon=`, and restart the app. For the Android emulator the class is `Emulator`.

## License

[MIT](LICENSE)
