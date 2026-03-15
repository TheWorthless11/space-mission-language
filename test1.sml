// --------------------------------------------------
// Space Mission Language - Lexer Stress Test
// Tests: keywords, identifiers, numbers, strings,
// escapes, comments, operators, and lexical errors
// --------------------------------------------------

mission DeepSpace start

// ---------- variable declarations ----------
int fuel = 150;
float speed = 7.8;
string status = "Launch Ready";
flag go = true;

// ---------- identifier tests ----------
int fuel2;
int orbit_speed;
int MarsMission;

// ---------- arithmetic ----------
fuel = fuel - 25;
fuel = fuel + 10;
fuel = fuel * 2;
fuel = fuel / 5;

// ---------- logical expressions ----------
check (fuel >= 100 && go == true) start
    transmit "Mission approved";
end
otherwise start
    transmit "Abort mission";
end

// ---------- loop ----------
orbit (fuel > 0) start
    fuel = fuel - 25;
    transmit fuel;
end

// ---------- string tests ----------
string s1 = "Hello World";
string s2 = "Line1\nLine2";
string s3 = "Tab\tSeparated";
string s4 = "Quote: \"Hello\"";
string s5 = "Backslash: \\";

transmit s1;
transmit s2;
transmit s3;
transmit s4;
transmit s5;

// ---------- multiline comment test ----------
/*
This is a multiline comment
that spans several lines.
Lexer should ignore everything here.
*/

// ---------- numeric tests ----------
int normalInt = 10;
float normalFloat = 3.14;

// ---------- malformed floats ----------
float badFloat1 = 5.;
float badFloat2 = .5;

// ---------- integer overflow ----------
int hugeNumber = 999999999999999999999999999999;

// ---------- invalid identifier usage ----------
int @fuel = 100;

// ---------- invalid escape sequence ----------
string badEscape = "Invalid escape \q";

// ---------- unterminated string ----------
string badString = "This string never ends

// ---------- invalid operator ----------
fuel = fuel $ 5;

// ---------- final valid output ----------
transmit "Mission complete";

end