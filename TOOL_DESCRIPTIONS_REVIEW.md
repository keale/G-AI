# G-AI Tool Description Review

Purpose: The text an AI client sees for each MCP tool comes 1:1 from that VI's own **VI Description** (Documentation tab). This file reviews the current descriptions of every VI in [`src/tools`](src/tools), flags the ones that are unclear, inaccurate, or missing information an AI agent would need, and proposes replacement text.

Editing a VI's description currently requires opening it for editing in LabVIEW and pasting the text into **File → VI Properties → Documentation → VI Description**, then saving — this is not yet something the G-AI tools themselves can do (there is no `set_description`/load-and-edit-existing-VI tool). So this file is meant as a checklist to apply by hand.

Legend: 🔴 needs a fix (wrong/misleading/incomplete) · 🟡 minor polish (works, could be clearer) · 🟢 fine as-is (not listed below).

---

## 🔴 `add subvi to vi.vi` — description is a copy-paste of `add object to vi.vi` and is factually wrong for this VI

**Current** (identical to `add object to vi.vi`):
> Adds an object to the block diagram, structure sub-diagram or frontpanel of the referenced vi. Get a VI reference from new_vi or get a structure sub-diagram by get_stucture_diagram to add to this. If adding a control, consider the create_control tool and think about adding objects first and then creating structures around them using the enclose with selection.
> Add a subVI or typedef by using the subvi_path, object name will be ignored. Leave subvi_path empty for all other objects.

**Problem:** Talks about an `object_name` parameter and "leave subvi_path empty for all other objects" — but `add_subvi_to_vi`'s connector pane has no `object_name` input at all (only `vi_id`, `subvi_path`, `position_x`, `position_y`). An AI reading this will look for a parameter that doesn't exist.

**Proposed:**
> Adds a subVI call (or a type-defined control/.ctl) to the block diagram, a structure's sub-diagram, or the front panel of the referenced VI, given the file path of the .vi/.ctl in `subvi_path`. This is the subVI-only equivalent of `add_object_to_vi` with `subvi_path` set — use it instead when you already know you're placing a subVI/typedef, since this tool has no unused `object_name` parameter. Get `vi_id` from `create_new_vi` (or `open_vi` for an existing VI), or a sub-diagram id from `get_structure_diagram`.

*Status: still unresolved — live `get_vi_details` on this VI (checked 2026-07-22) still returns the old copy-pasted text.*

---

## 🟡 `add object to vi.vi` — typo and vague reference

**Current:**
> Adds an object to the block diagram, structure sub-diagram or frontpanel of the referenced vi. Get a VI reference from new_vi or get a structure sub-diagram by get_stucture_diagram to add to this. If adding a control, consider the create_control tool and think about adding objects first and then creating structures around them using the enclose with selection.
> Add a subVI or typedef by using the subvi_path, object name will be ignored. Leave subvi_path empty for all other objects.

**Problems:** `get_stucture_diagram` is missing an "r" (should be `get_structure_diagram`); "the enclose with selection" is a vague reference to a specific placeable object name a reader can't act on without more context; refers informally to "new_vi" instead of the actual tool name `create_new_vi` (and doesn't mention `open_vi` as the equivalent for existing VIs).

**Proposed:**
> Adds an object (function, structure, constant, or a typedef/subVI via `subvi_path`) to the block diagram, a structure's sub-diagram, or the front panel of the referenced VI. Get `vi_id` from `create_new_vi` or `open_vi`, or a sub-diagram id from `get_structure_diagram`. To wrap existing objects in a new loop/case structure, place the objects first, then add one of the "Enclose Selection in..." structure objects around them. For a control/indicator on a terminal, prefer `create_control` instead — it creates and wires the right type automatically. To add a subVI or type-defined control (.ctl), set `subvi_path` to its file path (`object_name` is then ignored); leave `subvi_path` empty for every other object (see `get_available_objects` for valid `object_name` values).

*Status: still unresolved — live description unchanged.*

---

## 🟡 `connect objects.vi` — informal tool references

**Current:**
> Connects two terminals of two objects with a wire on the block diagram of a labview vi. To get a new VI use "new vi" to add objects to a vi use "add object". If a frontpanel control/indicator reference is passed to this function, it will automatically use the corresponding terminal on the block diagram for wiring. Use get_object_terminals before wiring to find out which terminals to wire.

**Problem:** References tools by informal names ("new vi", "add object") rather than their actual callable names (`create_new_vi`, `add_object_to_vi`), which is a minor mismatch for an AI client matching tool names literally.

**Proposed:**
> Connects two terminals of two objects with a wire on the block diagram. Get object ids from `create_new_vi`/`open_vi`, `add_object_to_vi`/`add_subvi_to_vi`, or `create_control`. If a front-panel control/indicator's id is passed, the corresponding block-diagram terminal is used automatically. Call `get_object_terminals` first on each object to find the correct terminal indices.

*Status: still unresolved — live description unchanged.*

---

## 🟡 `rename object.vi` — minor grammar/clarity

**Current:**
> Renames an objects label.text property, can be a control/indicator or a block diagram element like a constant.

**Problem:** "an objects label.text" → missing apostrophe; doesn't explain what `label_visible` does.

**Proposed:**
> Renames an object's label (its `Label.Text` property) — works on front-panel controls/indicators as well as block-diagram elements such as constants. Set `new_label_name` to the new text, and `label_visible` to show or hide the label.

*Status: still unresolved — live description unchanged.*

---

## 🟡 `set invoke node.vi` — `allow_alternate_names` is no longer a connector-pane input

An earlier draft of this review documented and recommended `method_name` = the **"Unique ID string"** from `get_available_methods` (not the "Data name"/display text, which errors with code 1077) — **this fix has been applied**, the live description now matches.

**New finding:** at the time that guidance was tested, `set_invoke_node` had a fourth input, `allow_alternate_names`, that enabled a fuzzy fallback match when the exact Unique ID string wasn't used. The current connector pane (checked 2026-07-22 via `get_vi_details`) only exposes `object_id`, `method_name`, `error in`, `error out` — the block diagram shows `AllowAlternateNames` wired as a hardcoded **`False`** constant into the Invoke Node's `SetMethod` call, not as a front-panel terminal. So the fuzzy-fallback capability still exists internally but is **no longer reachable from outside**: if `method_name` isn't an exact Unique ID string match, the call now always fails with error 1077, with no fallback option to opt into.

The current description doesn't claim otherwise (it correctly doesn't mention `allow_alternate_names`), so no text fix is needed here — but worth deciding deliberately: either re-expose `allow_alternate_names` as a connector-pane input if the fallback is meant to be usable, or leave it hardcoded and treat exact-match-only as intentional.

---

## 🔴 `open vi.vi` — never reviewed; undocumented parameters

This VI post-dates the previous review pass and was never assessed.

**Current:**
> Open an existing LabVIEW VI and optional shows the block diagram to the user. Use the returned vi id with other tools to modify the VI. Use this Tool to get a reference to vi in order to modify the content.

**Problems:**
- Typo: "optional shows" → "optionally shows".
- The connector pane has `VI Path`, `password`, `options` (I32), `Show VI` (bool), `error in` → `vi id`, `error out` — but the description explains none of `password` or `options`. An AI agent has no way to know what `options` accepts (this is the VI Server "Open VI Reference" options bitmask, e.g. flags for preparing for reentrant run, not running the top-level VI, etc.) or when `password` is required (password-protected VIs).
- No cross-reference to `create_new_vi` as its counterpart for brand-new VIs (the other tool-pairs in this project consistently reference each other).

**Proposed:**
> Opens an existing VI by file path and returns a `vi_id` for use with the other editing tools (`add_object_to_vi`, `connect_objects`, `cleanup_vi`, …) — the counterpart to `create_new_vi` for VIs that already exist on disk. Set `Show VI` to true to also open the block-diagram window for the user. Leave `password` empty unless the VI is password-protected. `options` is the VI Server "Open VI Reference" options bitmask (e.g. to prepare the VI for reentrant execution without running it) — leave at 0 for normal editing.

---

## 🟡 `get vi json graph description.vi` — never reviewed; minor typo

This VI also post-dates the previous review pass. The description itself is thorough and already well-structured (four labeled output arrays, a worked example of resolving a wire to its source/sink terminals, a documented list of known limitations) — no structural rewrite needed. Two small issues:

- Typo: "scans recursivly" → "scans recursively".
- See the encoding/mojibake finding below — this VI's description is the most affected by it.

---

## 🟡 Cross-cutting: em dash / arrow characters get mangled ("mojibake") when pasted into VI Description

Checked live via `get_vi_details` (2026-07-22). Several already-fixed descriptions contain garbled text where an em dash ("—") was apparently pasted as UTF-8 into a VI Description field that doesn't round-trip it correctly, rendering as **"â€”"**:

- `get_available_properties.vi`: "...for a Property Node **â€”** this does not work on Invoke Nodes..."
- `set_invoke_node.vi`: "...Unique ID string' field...**â€”** this is the reliable exact match."
- `get_broken_vi_list.vi`: "...full absolute file paths) **â€”** pass an entry..."
- `get_vi_json_graph_description.vi`: multiple instances.

More seriously, in `get_vi_json_graph_description.vi` an arrow ("→") used in the "Resolving a wire to its exact source/sink terminals" steps was mangled into a bare **"?"**, e.g.:
> "1. Look up the wire in array "1" **?** UID_Source, UIDs_Sink (node-level)."

Unlike the em-dash mojibake (which at least reads as obvious garbage), a lone "?" mid-sentence looks like a typo or a placeholder rather than a corrupted arrow, and actively hurts comprehension of that numbered procedure.

**Fix:** when typing/pasting VI Description text in LabVIEW going forward, avoid em dashes and arrow glyphs — use plain ASCII instead (`-` for em dash, `->` for arrow). Existing affected descriptions (`get_available_properties`, `set_invoke_node`, `get_broken_vi_list`, `get_vi_json_graph_description`) should be re-typed with ASCII substitutes the next time they're opened for editing.

---

## Not changed (already clear enough)

`get_project`, `get_vi_details`, `get_available_objects`, `get_available_methods`, `get_object_terminals`, `get_structure_diagram`, `create_new_vi`, `create_control`, `set_property`, `cleanup_vi`, `close_vi`, `get_control`, `get_enum`, `get_available_properties`, `get_broken_vi_list` — read fine for an AI client as-is; only cosmetic nitpicks (e.g. a double space in `cleanup_vi.vi`'s description, or the mojibake noted above) that aren't worth a separate edit pass.

## Next steps

1. Open each 🔴/🟡 VI listed above in LabVIEW, paste the proposed text into VI Properties → Documentation → VI Description (using plain ASCII punctuation — see the mojibake finding), save.
2. **Restart the G-MCP server** (reload `Init MCP.vi`) afterward — it only reads each tool VI's connector pane and description once at startup, so edits stay invisible to AI clients until it rescans.
3. Re-check via `ToolSearch` that the live schema/description now match what's in the VI.
4. Decide deliberately on the `set_invoke_node` / `allow_alternate_names` question (re-expose the input, or treat exact-match-only as final) rather than leaving it as an undocumented side effect.
5. Once description-editing is scriptable (a future `set_description`-style tool, analogous to how `set_invoke_node` closed the Invoke Node gap), these edits could be applied programmatically instead of by hand.
