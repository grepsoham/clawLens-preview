# raw.githubusercontent.com URL verification

Testing whether raw URLs render correctly on github.com README + are anonymously accessible.

## PNG image (agent close-up)

<p align="center">
  <img src="https://raw.githubusercontent.com/grepsoham/clawLens-preview/test/raw-url-verification/docs/assets/clawlens-agent-close.png" alt="Risk drivers close-up" width="600">
</p>

## SVG (Mermaid architecture diagram fallback)

<p align="center">
  <img src="https://raw.githubusercontent.com/grepsoham/clawLens-preview/test/raw-url-verification/docs/assets/architecture.svg" alt="ClawLens architecture" width="800">
</p>

## MP4 video (compressed demo)

<p align="center">
  <video src="https://raw.githubusercontent.com/grepsoham/clawLens-preview/test/raw-url-verification/docs/assets/clawlens-demo.mp4" controls width="800">
    Your browser does not support inline video. <a href="https://raw.githubusercontent.com/grepsoham/clawLens-preview/test/raw-url-verification/docs/assets/clawlens-demo.mp4">Download the demo</a>.
  </video>
</p>

## Mermaid (native fenced block)

```mermaid
flowchart LR
    A[AI Agent] -->|tool call| B[OpenClaw Runtime]
    B -->|before_tool_call hook<br/>priority 100| C{ClawLens}
    C -->|"allow / block /<br/>require approval"| B
    C -->|score + tag| D[(Hash-chained<br/>audit log)]
    C -->|stream| E[Local dashboard]
    C -.->|opt-in| F[Alert channel]
    B -->|allowed| G[Tool executes]

    style C fill:#7c3aed,stroke:#5b21b6,color:#fff
```

## What to check

1. PNG renders inline.
2. SVG renders inline.
3. Video player appears (click play to verify it streams).
4. Mermaid diagram renders as a flowchart (not a code block).
5. Clicking any image opens the raw asset in a new tab (not GitHub's file viewer).

If 1-4 all work in **incognito mode** (not logged into github.com), the approach is validated for ClawHub and any other anonymous renderer.
