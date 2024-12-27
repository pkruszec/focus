snippet_dialog_handle_event :: (event: Input.Event) -> handled: bool {
    return dialog_handle_event(*snippet_dialog, event);
}

snippet_dialog: Snippet_Dialog;

Snippet_Dialog :: struct {
    using #as generic_dialog: Generic_Choice_Dialog(Snippet);
    generic_dialog.global_widget_id    = .snippet_dialog;
    generic_dialog.refresh_entries     = snippet_dialog_refresh_entries;
    generic_dialog.open_entry_in_place = apply_selected_snippet;
    generic_dialog.on_show             = snippet_dialog_on_show;
}

apply_selected_snippet :: () {
    using snippet_dialog;
    defer hide_dialog(*snippet_dialog);

    if build_panel_is_active() return;  // shouldn't ever be active
    if selected >= filtered.count return;

    editor, buffer := get_active_editor_and_buffer();
    if !buffer return;
    if buffer.cursors.count < 1 return;

    snip := filtered[selected];
    str, cursor_added_count := snip.value();
    assert(cursor_added_count >= 0);

    // TODO: Figure out snippets with multiple cursors
    cursor := *buffer.cursors[0];
    selection := get_selection(cursor);
    replace_range(buffer, selection, str);
    cursor.pos += xx cursor_added_count;
    cursor.sel = cursor.pos;

    editor.cursor_moved = .large_edit;
}

snippet_dialog_on_show :: () {
    hide_build_panel();
}

snippet_dialog_refresh_entries :: (filter: Fuzzy_Filter) {
    using snippet_dialog;
    for SNIPPETS {
        score, highlights := fuzzy_match(it.name, filter);
        if score <= 0 && filter.full_string continue;

        entry := array_add(*filtered);
        entry.highlights = highlights;
        entry.sort_key = xx score;

        entry.details = it;
    }
}
