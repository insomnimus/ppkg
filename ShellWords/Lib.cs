// MIT License Copyright (c) 2023 Taylan Gökkaya <insomnimus@proton.me>

// This is a mostly 1:1 port of https://github.com/tmiasko/shell-words.
// I've changed the escape character to be ` as Powershell uses it.
// I've also implemented more Powershell-like escape handling.

namespace ShellWords;

using System;
using System.Collections.Generic;
using System.Text;

public class ParseError: FormatException {
	internal long pos;
	internal string input;

	public override string Message => this.message();

	internal ParseError(string input, long pos) {
		this.pos = pos;
		this.input = input;
	}

	private string message() {
		var line = 1;
		var start = 0;

		for (var i = 0; i < this.pos; i++) {
			if (this.input[i] == '\n') {
				start = i;
				line++;
			}
		}

		var s = this.input.Substring(start);
		var len = s.IndexOf('\n');
		s = (len < 0) ? s : s.Substring(0, len);

		var col = (start == 0)
		? 1
		: (1 + this.pos % start);

		return $"{line}:{col}: unterminated quote\nline: {s}";
	}
}

enum State {
	/// Within a delimiter.
	Delimiter,
	/// After escape char, but before starting word.
	Escape,
	/// Within an unquoted word.
	Unquoted,
	/// After escape char in an unquoted word.
	UnquotedEscape,
	/// Within a single quoted word.
	SingleQuoted,
	/// Within a double quoted word.
	DoubleQuoted,
	/// After escape char inside a double quoted word.
	DoubleQuotedEscape,
	/// Inside a comment.
	Comment
}

public static class ShellWords {
	const char ESCAPE = '`';

	internal static char EscapedChar(char c) => c switch {
		'0' => '\0',
		'a' => '\a',
		'b' => '\b',
		'f' => '\f',
		'n' => '\n',
		'r' => '\r',
		't' => '\t',
		'v' => '\v',
		_ => c,
	};

	private static long split(string s, List<string> words) {
		var word = new StringBuilder();
		var chars = s.GetEnumerator();
		var state = State.Delimiter;
		var lastQuote = 0L;

		for (long i = 0; true; i++) {
			var prevState = state;
			var end = !chars.MoveNext();
			var c = end ? '\0' : chars.Current;

			switch (state) {
				case State.Delimiter: {
						if (end) return -1;
						else if (c == '\'') state = State.SingleQuoted;
						else if (c == '"') state = State.DoubleQuoted;
						else if (c == ESCAPE) state = State.Escape;
						else if (c == '#') state = State.Comment;
						else if (c != ' ' && c != '\t' && c != '\n') {
							word.Append(c);
							state = State.Unquoted;
						}
						break;
					}

				case State.Escape: {
						if (end) {
							word.Append(ESCAPE);
							words.Add(word.ToString());
							return -1;
						} else if (c == '\n') state = State.Delimiter;
						else {
							word.Append(EscapedChar(c));
							state = State.Unquoted;
						}
						break;
					}

				case State.Unquoted: {
						if (end) {
							words.Add(word.ToString());
							return -1;
						} else if (c == '\'') state = State.SingleQuoted;
						else if (c == '"') state = State.DoubleQuoted;
						else if (c == ESCAPE) state = State.UnquotedEscape;
						else if (c == ' ' || c == '\t' || c == '\n') {
							words.Add(word.ToString());
							word.Clear();
							state = State.Delimiter;
						} else {
							word.Append(c);
						}
						break;
					}

				case State.UnquotedEscape: {
						if (end) {
							word.Append(ESCAPE);
							words.Add(word.ToString());
							return -1;
						} else if (c == '\n') state = State.Unquoted;
						else {
							word.Append(EscapedChar(c));
							state = State.Unquoted;
						}
						break;
					}

				case State.SingleQuoted: {
						if (end) return lastQuote;
						else if (c == '\'') state = State.Unquoted;
						else {
							word.Append(c);
						}
						break;
					}

				case State.DoubleQuoted: {
						if (end) return lastQuote;
						else if (c == '"') state = State.Unquoted;
						else if (c == ESCAPE) state = State.DoubleQuotedEscape;
						else {
							word.Append(c);
						}
						break;
					}

				case State.DoubleQuotedEscape: {
						if (end) return lastQuote;
						else if (c == '\n') state = State.DoubleQuoted;
						else if (c == '$' || c == ESCAPE || c == '"') {
							word.Append(c);
							state = State.DoubleQuoted;
						} else {
							word.Append(EscapedChar(c));
							state = State.DoubleQuoted;
						}
						break;
					}

				case State.Comment: {
						if (end) return -1;
						else if (c == '\n') state = State.Delimiter;

						break;
					}

				default: throw new Exception("internal logic error (unhandled switch case)");
			}

			if (state != prevState && (state == State.SingleQuoted || state == State.DoubleQuoted)) {
				lastQuote = i;
			}
		}
	}

	public static ParseError? TryParse(string input, out string[] outWords) {
		var words = new List<string>();
		var res = ShellWords.split(input, words);
		if (res >= 0) {
			outWords = new string[] { };
			return new ParseError(input, res);
		}

		outWords = words.ToArray();
		return null;
	}

	public static string[] Parse(string input) {
		string[] words;
		var res = TryParse(input, out words);
		if (res == null) return words;
		else throw res;
	}
}
