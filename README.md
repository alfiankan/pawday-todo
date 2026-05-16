# Draggable Town Map

A minimal Godot 4 web game prototype:

- Drag the map with mouse or touch.
- Scroll to zoom.
- A placeholder Townhall building is placed at the center of the map.

## Run Locally

Open this folder with Godot 4.2 or newer and run `scenes/main.tscn`.

## Web Export

The `Web` export preset writes to `dist/web/index.html`.

```sh
godot --headless --import --quit-after 30
mkdir -p dist/web
godot --headless --export-release Web dist/web/index.html
```

## Deployment

Pushing to `main` triggers `.github/workflows/pages.yml`, exports the Godot web build, injects `coi-serviceworker.js` (for SharedArrayBuffer/Cross-Origin Isolation compatibility on GitHub Pages), and deploys it.
