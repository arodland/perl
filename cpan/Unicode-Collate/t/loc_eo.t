#!perl
use strict;
use warnings;
use Unicode::Collate::Locale;

use Test;
plan tests => 38;

my $objEo = Unicode::Collate::Locale->
    new(locale => 'EO', normalization => undef);

ok(1);
ok($objEo->getlocale, 'eo');

$objEo->change(level => 1);

ok($objEo->lt("c", "c\x{302}"));
ok($objEo->gt("d", "c\x{302}"));
ok($objEo->lt("g", "g\x{302}"));
ok($objEo->gt("h", "g\x{302}"));
ok($objEo->lt("h", "h\x{302}"));
ok($objEo->gt("i", "h\x{302}"));
ok($objEo->lt("j", "j\x{302}"));
ok($objEo->gt("k", "j\x{302}"));
ok($objEo->lt("s", "s\x{302}"));
ok($objEo->gt("t", "s\x{302}"));
ok($objEo->lt("u", "u\x{306}"));
ok($objEo->gt("v", "u\x{306}"));

# 14

$objEo->change(level => 2);

ok($objEo->eq("c\x{302}", "C\x{302}"));
ok($objEo->eq("g\x{302}", "G\x{302}"));
ok($objEo->eq("h\x{302}", "H\x{302}"));
ok($objEo->eq("j\x{302}", "J\x{302}"));
ok($objEo->eq("s\x{302}", "S\x{302}"));
ok($objEo->eq("u\x{306}", "U\x{306}"));

# 20

$objEo->change(level => 3);

ok($objEo->lt("c\x{302}", "C\x{302}"));
ok($objEo->lt("g\x{302}", "G\x{302}"));
ok($objEo->lt("h\x{302}", "H\x{302}"));
ok($objEo->lt("j\x{302}", "J\x{302}"));
ok($objEo->lt("s\x{302}", "S\x{302}"));
ok($objEo->lt("u\x{306}", "U\x{306}"));

# 26

ok($objEo->eq("c\x{302}", "\x{109}"));
ok($objEo->eq("C\x{302}", "\x{108}"));
ok($objEo->eq("g\x{302}", "\x{11D}"));
ok($objEo->eq("G\x{302}", "\x{11C}"));
ok($objEo->eq("h\x{302}", "\x{125}"));
ok($objEo->eq("H\x{302}", "\x{124}"));
ok($objEo->eq("j\x{302}", "\x{135}"));
ok($objEo->eq("J\x{302}", "\x{134}"));
ok($objEo->eq("s\x{302}", "\x{15D}"));
ok($objEo->eq("S\x{302}", "\x{15C}"));
ok($objEo->eq("u\x{306}", "\x{16D}"));
ok($objEo->eq("U\x{306}", "\x{16C}"));

# 38
