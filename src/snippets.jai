Snippet :: struct {
    name: string;
    // The return values don't have to be compile-time known, so you can return anything.
    // For instance, you can put things like the current date, or the current buffer name in there.
    // The cursor move count is usually the length of the snippet, but you can also set it to where you are supposed to type next (like the condition in an if statement).
    value: () -> contents: string, cursor_move_count: int;
}

SNIPPETS :: Snippet.[
    Snippet.{"adoc", adoc},
    Snippet.{"cm", cm},
];

#scope_file

adoc :: () -> string, int {
    template_without_annotation :: #string ADOC
=
:revdate: %-%-%
:author: Paweł Kruszec
:email: pakruszec@gmail.com
    ADOC
    template_annotation :: "[#%]\n";
    template_with_annotation :: #run join(template_annotation, template_without_annotation);
    added_offset :: 1;

    now := current_time_consensus();
    calendar_local := to_calendar(now, .LOCAL);
    year  := calendar_local.year;
    month := 1 + calendar_local.month_starting_at_0;
    day   := 1 + calendar_local.day_of_month_starting_at_0;

    _, buffer := get_active_editor_and_buffer();
    if !buffer return "", 0;

    // TODO: Simplify this code
    file_name := buffer.file.name;
    if file_name == "" {
        str := tprint(template_without_annotation, FormatInt.{minimum_digits = 4, value = year}, FormatInt.{minimum_digits = 2, value = month}, FormatInt.{minimum_digits = 2, value = day});
        added_count := find_index_from_right(str, #char "=");
        assert(added_count >= 0);

        return str, added_count + added_offset;
    } else {
        file_name_without_extension := path_strip_extension(file_name);
        annotation := file_name_without_extension;
        str := tprint(template_with_annotation, annotation, FormatInt.{minimum_digits = 4, value = year}, FormatInt.{minimum_digits = 2, value = month}, FormatInt.{minimum_digits = 2, value = day});
        added_count := find_index_from_right(str, #char "=");
        assert(added_count >= 0);

        return str, added_count + added_offset;
    }
}

cm :: () -> string, int {
    TEMPLATE :: #string CPP
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

int main() {
    return 0;
}
    CPP;
    return TEMPLATE, TEMPLATE.count - 16;
}
