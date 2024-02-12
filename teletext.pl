:- module(teletext, [fmt_text_//2]).

:- use_module(library(dcgs)).
:- use_module(library(pio)).
:- use_module(library(format)).
:- use_module(library(clpz)).
:- use_module(library(lists)).
:- use_module(library(iso_ext)).
:- use_module(library(between)).
:- use_module(library(os)).
:- use_module(library(charsio)).
:- use_module(library(time)).

:- dynamic(termconf/1).

ansi_esc --> "\x1b\".

fmt_text_(Text, []) -->
    Text.
fmt_text_(Text, Styles) -->
    ansi_esc, "[", fmt_styles_(Styles), "m",
    Text,
    ansi_esc, "[m".

fmt_color_(black, "0").
fmt_color_(red, "1").
fmt_color_(green, "2").
fmt_color_(yellow, "3").
fmt_color_(blue, "4").
fmt_color_(magenta, "5").
fmt_color_(cyan, "6").
fmt_color_(white, "7").

fmt_style(bright, "1").
fmt_style(dim, "2").
fmt_style(italic, "3").
fmt_style(underline, "4").
fmt_style(reverse, "7").
fmt_style(fg_color(Color), ['3'|C]) :-
    fmt_color_(Color, C).
fmt_style(fg_color(C), X) :-
    C in 0..255,
    number_chars(C, N),
    append("38;5;", N, X).
fmt_style(fg_bright_color(Color), ['9'|C]) :-
    fmt_color_(Color, C).
fmt_style(bg_color(Color), ['4'|C]) :-
    fmt_color_(Color, C).
fmt_style(bg_color(C), X) :-
    C in 0..255,
    number_chars(C, N),
    append("48;5;", N, X).
fmt_style(bg_bright_color(Color), ['10'|C]) :-
    fmt_color_(Color, C).

fmt_styles_([X]) -->
    { fmt_style(X, Cs) },
    Cs.
fmt_styles_([X|Xs]) -->
    { fmt_style(X, Cs), length(Xs, N), N #>= 0 },
    Cs,
    ";",
    fmt_styles_(Xs).

tui_clear --> ansi_esc, "[2J".
tui_enter --> ansi_esc, "[?1049h".
tui_exit --> ansi_esc, "[?1049l".
tui_move(X, Y) -->
    { number_chars(X, C), number_chars(Y, R) },
    ansi_esc, "[",R,";",C,"H".

terminal_size(Lines, Cols) :-
    shell("stty size > /tmp/stty_size"),
    open("/tmp/stty_size", read, Stream),
    get_n_chars(Stream, _, X),
    phrase(stty_out_(Lines, Cols), X).

stty_out_(Cols, Lines) -->
    seq(CsCols),
    " ",
    seq(CsLines),
    "\n",
    { number_chars(Cols, CsCols), number_chars(Lines, CsLines) }.

show_8bit_colors :-
    forall(between(0, 255, C),(
	       phrase_to_stream(fmt_text_("█", [fg_color(C)]), user_output),
	   (15 is C mod 16 ->
		format(" = ~d\n", [C])
	   ;    format(" = ~d\t", [C]))
	   )).

test_fmt_text_001 :-
    phrase(("Lorem", fmt_text_("Ipsum", [bright, italic]), fmt_text_("Magna", [underline, reverse])), "Lorem\x1b\[1;3mIpsum\x1b\[m\x1b\[4;7mMagna\x1b\[m").
test_fmt_text_002 :-
    phrase((fmt_text_("A", [fg_color(red)]), fmt_text_("B", [fg_color(134), italic])), "\x1b\[31mA\x1b\[m\x1b\[38;5;134;3mB\x1b\[m").

test :-
    forall((current_predicate(teletext:Name/0), atom_chars(Name, NameCs), append("test_", _, NameCs)), (
	       portray_clause(executing(Name)),
	       call(teletext:Name)
	   )),
    halt.
test :- halt(1).
