# Brand Assets & ASCII Art

This document contains text-based graphical assets for Bodegga and Tide Software, designed for use in CLI dashboards, documentation, boot screens, and code comments.

---

## Bodegga
*Innovation + Technical Precision | Local Authenticity*

The Bodegga logo features an egg motif with a stylized wave and sun/yolk element, representing fresh starts and organic flow.

### Colors
| Color | Hex | Description |
|-------|-----|-------------|
| **Off-Black** | `#131313` | Primary stroke and outlines |
| **Muted Blue** | `#3D7297` | Inner semi-circle (Sun/Sky) |
| **Mustard** | `#F2B03D` | Bottom wave (Yolk/Earth) |
| **Cream** | `#F8F4E9` | Background |

### Typography
The brand uses the **Bodega** font family.
*   **Primary:** `Bodega-Plain.otf`
*   **Display:** `Bodega-Striped.otf`

Location: `docs/logos/Fonts/`

### Vector Assets
*   **Full Color:** [`bodegga_logo_color.svg`](./bodegga_logo_color.svg)
*   **Transparent:** [`bodegga_logo_transparent.svg`](./bodegga_logo_transparent.svg)

### ASCII Art
For CLI banners and code comments.

**Primary Mark:**
```text
       .---.
    .'       '.
   /           \
  |    _____    |
  |   /     \   |
  |  |  ( )  |  |
  |   \__~__/   |
   \    ~~~    /
    '.       .'
      '-----'
```

**Detailed ASCII:**
```text
          ,d8888b,
        ,888888888b
       d88888888888b
      d8888888888888b
     d888888888888888b
    d88888888888888888b
   d8888888888888888888b
  d8888888P"   "Y8888888b
  8888888' .d8b. '8888888
  8888888  88888  8888888
  Y888888b 'Y8P' d888888P
   Y888888b     d888888P
    Y88888888888888888P
     Y888888888888888P
      `Y88888888888P'
         `"Y888P"'
```

---

## Tide Software
*Fluidity, Data, reliability*

### Concept 1: The "Tide" Wave (Console Banner)
Fluid ASCII curves suitable for boot screens or main menu headers.

```text
  _______   _       __        
 /_  __(_)___/ /__     / /  __ __/ /_      
  / / / / _  / -_)   / /__/ // / __/      
 /_/ /_/\_,_/\__/   /____/\_,_/\__/       
```

### Concept 2: Data Rising (Dashboard Widget)
Vertical bars representing data tides. Good for loading screens or status indicators.

```text
 TIDE OS [||||||....]

       .
      .:.
     .:::.
    .:::::.   T I D E
   .:::::::.  SYSTEMS
```

### Concept 3: Minimal Terminal Header
Compact header for CLI tools.

```text
 // TIDE_SOFTWARE v1.0
 ~~~~~~~~~~~~~~~~~~~~~
```

### Concept 4: The "Ripple" (Icon)
Concentric motion.

```text
    ( ( ( T ) ) )
```

---

## Implementation Guidelines

### Colors (ANSI Codes)
When implementing these in a terminal, use the following approximate ANSI colors to match the brand palette:

**Bodegga:**
- Deep Charcoal: `\033[1;30m` (Dark Gray)
- Electric Teal: `\033[0;36m` (Cyan)
- Warm Sand: `\033[0;33m` (Yellow/Brown dim)

**Tide:**
- Ocean Blue: `\033[0;34m` (Blue)
- Foam White: `\033[1;37m` (Bright White)

### Usage Example (Bash)
```bash
echo -e "\033[0;36m    ____            __                       \033[0m"
echo -e "\033[0;36m   / __ )____  ____/ /__  ____ _____ _____ _ \033[0m"
echo -e "\033[0;36m  / __  / __ \/ __  / _ \/ __ \`/ __ \`/ __ \`/\033[0m"
echo -e "\033[0;36m / /_/ / /_/ / /_/ /  __/ /_/ / /_/ / /_/ /  \033[0m"
echo -e "\033[0;36m/_____/\____/\__,_/\___/\__, /\__, /\__,_/   \033[0m"
echo -e "\033[0;36m                       /____//____/          \033[0m"
```
