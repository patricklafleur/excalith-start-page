# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Fork of excalith-start-page -- a terminal-inspired browser start page built with Next.js 14 (Pages Router), React 18, and Tailwind CSS. Uses Fira Code font, Iconify icons, and Serwist for PWA/service worker support.

## Commands

- `yarn dev` -- start dev server (Next.js on port 3000)
- `yarn build` -- production build
- `yarn lint` -- ESLint (next lint)
- `yarn format` -- Prettier formatting

## Architecture

**Configuration-driven UI**: The entire page content is defined in `data/settings.json`. This single JSON file controls theme colors, wallpaper, terminal appearance, prompt styling, search shortcuts, and all link sections.

**Settings flow**: `SettingsContext` (`src/context/settings.js`) loads config from localStorage (web) or from `data/settings.json` via API (Docker mode, controlled by `BUILD_MODE=docker` env var). Users can also edit config live with the `config edit` built-in command.

**Component hierarchy**:
- `pages/index.js` -- entry point, sets CSS variables from theme config, renders wallpaper + Terminal
- `Terminal.js` -- routes between views (List, Help, Config, Fetch) based on command events
- `List.js` -- renders the link grid (3-column CSS grid) by iterating `settings.sections.list`
- `Link.js` -- individual link with icon, supports filtering/selection highlighting
- `Search.js` / `Prompt.js` -- terminal prompt with autocomplete, link filtering, and command execution

**Sections/links structure** in `data/settings.json`:
```json
{
  "sections": {
    "list": [
      {
        "title": "Section Name",
        "color": "green",
        "align": "left",
        "links": [
          { "name": "Link Name", "url": "https://...", "icon": "mdi:github" }
        ]
      }
    ]
  }
}
```

Colors reference theme color names: `green`, `magenta`, `cyan`, `red`, `blue`, `yellow`, `white`, `gray`. Icons use Iconify format (e.g., `mdi:github`, `simple-icons:nasa`).

**Themes**: JSON files in `data/themes/` define color palettes. Switchable via `config theme <name>` command.

**Tailwind**: Colors are mapped to CSS variables set at runtime from the theme config. The safelist in `tailwind.config.js` ensures dynamic color classes are preserved.

**API routes** (`src/pages/api/`): `loadSettings`, `saveSettings` (Docker file-based persistence), `getData` (fetch file content), `getTheme` (list available themes).
