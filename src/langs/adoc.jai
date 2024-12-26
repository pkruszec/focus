tokenize_adoc :: (using buffer: *Buffer, start_offset := -1, count := -1) -> [] Buffer_Region {
    tokenizer := get_adoc_tokenizer(buffer, start_offset, count);

    while true {
        token := get_next_token(*tokenizer);
        if token.type == .eof break;

        memset(tokens.data + token.start, xx token.type, token.len);
    }

    return .[];
}

#scope_file

get_adoc_tokenizer :: (using buffer: *Buffer, start_offset := -1, count := -1) -> Adoc_Tokenizer {
    tokenizer: Adoc_Tokenizer;

    tokenizer.buf   = to_string(bytes);
    tokenizer.max_t = bytes.data + bytes.count;
    tokenizer.t     = bytes.data;
    tokenizer.found_new_line   = true;
    tokenizer.found_whitespace = true;

    if start_offset >= 0 {
        start_offset = clamp(start_offset, 0, bytes.count - 1);
        count        = clamp(count,        0, bytes.count - 1);
        tokenizer.t += start_offset;
        tokenizer.max_t = tokenizer.t + count;
    }

    return tokenizer;
}

get_next_token :: (using tokenizer: *Adoc_Tokenizer) -> Token {
    while t < max_t && is_white_space(t.*) {
        found_whitespace = true;
        if t.* == #char "\n" found_new_line = true;
        t += 1;
    }

    token: Token;
    token.start = cast(s32) (t - buf.data);
    token.type = .eof;
    if t >= max_t return token;

    start_t = t;
    char := t.*;
    if char == {
        case #char "/"; parse_slash_or_comment(tokenizer, *token);
        case;
            token.type = .default;
            t += 1;
    }

    found_new_line = false;
    found_whitespace = false;

    if t >= max_t then t = max_t;
    token.len = cast(s32) (t - start_t);
    return token;
}

parse_slash_or_comment :: (using tokenizer: *Tokenizer, token: *Token) {
    slash_count := try_to_eat_slashes(tokenizer);
    if slash_count < 2 return;

    if slash_count >= 4 {
        token.type = .multiline_comment;
        t += 1;
        while t + 1 < max_t {
            slash_count = try_to_eat_slashes(tokenizer);
            if slash_count >= 4 break;
            t += 1;
        }
    } else {
        token.type = .comment;
        t += 1;
        while t < max_t && t.* != #char "\n" t += 1;
    }
}

try_to_eat_slashes :: (using tokenizer: *Tokenizer) -> int {
    slash_count := 0;
    while t + 1 < max_t {
        if t.* != #char "/" break;
        t += 1;
        slash_count += 1;
    }
    return slash_count;
}

Adoc_Tokenizer :: struct {
    using #as base:   Tokenizer;
    found_new_line:   bool;
    found_whitespace: bool;
}

Token :: struct {
    start, len: s32;
    type: Token_Type = .invalid;
}
