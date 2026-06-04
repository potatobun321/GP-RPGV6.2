# Map Creation Workflow

Map creation is an intentional action designed to give every map a consistent starting state. 

## The `newmap` Command

To create a new map, open the console and type:
`newmap.map_name`

### What happens under the hood?
1. The engine checks if `map_name` already exists. If it does, the command aborts to prevent overwriting.
2. The current map is saved to disk.
3. The engine loads the `template.json` system map.
4. The engine renames the current map context to `map_name`.
5. The map is immediately saved to disk as `map_name.json`.

## The Template Blueprint

All new maps originate from `content/maps/template.json`.

**Template Properties:**
- **Dimensions**: 30x30 tiles
- **Contents**: A default grass interior surrounded by a solid wall boundary.
- **Visibility**: `template.json` is a **System Map**. It will never appear in the map selection popup, the link tile popup, or the playable map list.

## Duplicating Maps

If you want to base a new map on an existing map instead of the default template, use the `duplicatemap` command:
`duplicatemap.source_map.new_map`

This will load `source_map` and immediately save it as `new_map`, functioning identically to a "Save As" operation.
