Godot Android XR Template
=========================

This is a lightweight Godot project that is already setup to run on
Android XR!

Since the focus is Project Aura, this defaults to a "passthrough" rather
than "immersive" experience.

## Godot XR Tools

This template comes with the
[Godot XR Tools](https://github.com/GodotVR/godot-xr-tools) addon
pre-installed.

It provides many useful XR utilities, for example, rendering 2D UIs
and letting the user interact with them via a pointer attached to
their hands.

Please see the
[XR Tools documentation](https://github.com/GodotVR/godot-xr-tools/wiki)
for more information.

## Godot MCP and AI integration

There are numerous MCP servers available for Godot, all with somewhat
different approaches.

We recommend [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp),
which is one of the most popular. It's also easy to install (it can be
run via `npx`) and limit to working on the intended Godot project.

The template already includes an `.mcp.json` which will be picked up automatically
by Claude Code.

See [the documentation](https://github.com/Coding-Solo/godot-mcp#quick-start)
for instructions on how to use it with other MCP clients.
