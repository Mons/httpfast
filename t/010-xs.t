#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

use Test::More tests    => 90;


BEGIN {
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";


    use_ok 'HTTPFast';
}

use Data::Dumper;


# params
{
    is_deeply HTTPFast::_params("abc"), { abc => '' }, 'raw string';
    is_deeply HTTPFast::_params("abc="), { abc => '' }, 'empty string';
    is_deeply HTTPFast::_params("a=1"), { a => 1 }, "one param";
    is_deeply HTTPFast::_params("a=1&b=2"), { a => 1, b => 2 }, "two params";
    is_deeply HTTPFast::_params("a=1&"), { a => 1 }, "one param";
    is_deeply HTTPFast::_params("a=1&b=2&"), { a => 1, b => 2 }, "two params";
    is_deeply HTTPFast::_params("a=1&a=2"), { a => [1, 2] }, "one param twice";
    is_deeply HTTPFast::_params("a=1&a=2&a=3"), { a => [1, 2, 3] },
        "one param three times";
    is_deeply HTTPFast::_params("a=1&a=2&"), { a => [1, 2] }, "one param twice";
    is_deeply HTTPFast::_params("a=1&a=2&a=3&"), { a => [1, 2, 3] },
        "one param three times";
    is_deeply HTTPFast::_params("a=1&a&"), { a => [1, ''] }, "one param twice";
    is_deeply HTTPFast::_params("a=1&a=&a=3&"), { a => [1, '', 3] },
        "one param three times";
    is_deeply HTTPFast::_params("a=1&a=&"), { a => [1, ''] }, "one param twice";
    is_deeply HTTPFast::_params("a=1&a&a=3&"), { a => [1, '', 3] },
        "one param three times";
}

# continuation at the first header
{
    my $res = HTTPFast::_parse(0, " abc\nHost: abc.ru");
    isa_ok $res => 'HTTPFast::Message';
    like $res->[0], qr{first header}, 'continuation at the first header';
    is_deeply $res->[1], [], 'headers';
}
# one valid header
{
    my $res = HTTPFast::_parse(0, "Host: abc.ru");
    isa_ok $res => 'HTTPFast::Message';
    is $res->[0], '', 'one header';
    is_deeply $res->[1], [host => 'abc.ru'], 'headers';
    is $res->[2], '', 'body';
    
    $res = HTTPFast::_parse(0, "Host: abc.ru\n");
    isa_ok $res => 'HTTPFast::Message';
    is $res->[0], '', 'one header';
    is_deeply $res->[1], [host => 'abc.ru'], 'headers';
    is $res->[2], '', 'body';
    
    $res = HTTPFast::_parse(0, "Host: abc.ru\n\n");
    isa_ok $res => 'HTTPFast::Message';
    is $res->[0], '', 'one header';
    is_deeply $res->[1], [host => 'abc.ru'], 'headers';
    is $res->[2], '', 'body';
    
    $res = HTTPFast::_parse(0, "Host: abc.ru\r\n\r\n");
    isa_ok $res => 'HTTPFast::Message';
    is $res->[0], '', 'one header';
    is_deeply $res->[1], [host => 'abc.ru'], 'headers';
    is $res->[2], '', 'body';
    
    # and body
    $res = HTTPFast::_parse(0, "Host: abc.ru\r\n\r\n12345");
    isa_ok $res => 'HTTPFast::Message';
    is $res->[0], '', 'one header';
    is_deeply $res->[1], [host => 'abc.ru'], 'headers';
    is $res->[2], '12345', 'body';
}

{
    my $h = <<eof;
Host: google.com
Content-Length: 123
X-Test: abc
 cde
X-Test: abc
X-Test:
    cde
    def
eof

    my $res = HTTPFast::_parse(0, $h);
    is $res->[0], '', 'normal headers';
    is_deeply $res->[1], [
        host                => 'google.com',
        'content_length'    => 123,
        'x_test'            => 'abc cde',
        'x_test'            => 'abc',
        'x_test'            => 'cde def'
    ], 'headers';
}

# request line
{
    my $res = HTTPFast::_parse(1, "");
    isa_ok $res => 'HTTPFast::Request';
    like $res->[0], qr{empty}i, 'error message';

    $res = HTTPFast::_parse(1, "1");
    isa_ok $res => 'HTTPFast::Request';
    like $res->[0], qr{broken}i, 'error message';
    
    $res = HTTPFast::_parse(1, "GET / HTTP/1.0");
    isa_ok $res => 'HTTPFast::Request';
    is $res->[0], '', 'no errors';
    is_deeply $res->[1], [], 'headers';
    is_deeply $res->[3], [ 'GET', '/', '', 1, 0 ], 'request line';
    
    $res = HTTPFast::_parse(1, "GET / HTTP/1.0\r\nHost:abc.ru");
    isa_ok $res => 'HTTPFast::Request';
    is $res->[0], '', 'no errors';
    is_deeply $res->[1], [host => 'abc.ru'], 'headers';
    is_deeply $res->[3], [ 'GET', '/', '', 1, 0 ], 'request line';

    $res = HTTPFast::_parse(1, "GET /?query HTTP/0.9\r\nHost:abc.ru");
    isa_ok $res => 'HTTPFast::Request';
    is $res->[0], '', 'no errors';
    is_deeply $res->[1], [host => 'abc.ru'], 'headers';
    is_deeply $res->[3], [ 'GET', '/', 'query', 0, 9 ], 'request line';

    $res = HTTPFast::_parse(1, "GET /abc/cde HTTP/1.\r\nHost:abc.ru");
    isa_ok $res => 'HTTPFast::Request';
    like $res->[0], qr{protocol}i, 'error in protocol version';
    is_deeply $res->[1], [], 'headers';
    is_deeply $res->[3], [], 'request line';
    
    $res = HTTPFast::_parse(1, "GET /abc/cde HTTP/1.");
    isa_ok $res => 'HTTPFast::Request';
    like $res->[0], qr{too short}i, 'error in protocol version';
    is_deeply $res->[1], [], 'headers';
    is_deeply $res->[3], [], 'request line';
    
    $res = HTTPFast::_parse(1, "GET /abc/cde?query HTTP/1.");
    isa_ok $res => 'HTTPFast::Request';
    like $res->[0], qr{too short}i, 'error in protocol version';
    is_deeply $res->[1], [], 'headers';
    is_deeply $res->[3], [], 'request line';
}

# response line
{
    my $res = HTTPFast::_parse(2, "");
    isa_ok $res => 'HTTPFast::Response';
    like $res->[0], qr{empty}i, 'error message';

    $res = HTTPFast::_parse(2, "HTTP/1.0 301 Moved Permanently\n");
    isa_ok $res => 'HTTPFast::Response';
    is $res->[0], '', 'error message';
    is_deeply $res->[1], [], 'headers';
    is $res->[2], '', 'body';
    is_deeply $res->[3], [ 301, 'Moved Permanently', 1, 0 ], 'response line';

    $res = HTTPFast::_parse(2, "HTTP/1.1 200 Ok");
    isa_ok $res => 'HTTPFast::Response';
    is $res->[0], '', 'error message';
    is_deeply $res->[1], [], 'headers';
    is $res->[2], '', 'body';
    is_deeply $res->[3], [ 200, 'Ok', 1, 1 ], 'response line';

    $res = HTTPFast::_parse(2, "HTTP/1.1 200 Ok\nHost: abc");
    isa_ok $res => 'HTTPFast::Response';
    is $res->[0], '', 'error message';
    is_deeply $res->[1], [host => 'abc'], 'headers';
    is $res->[2], '', 'body';
    is_deeply $res->[3], [ 200, 'Ok', 1, 1 ], 'response line';

    $res = HTTPFast::_parse(2, "HTTP/0.9 400 Bad request\nHost: abc\n\ncde");
    isa_ok $res => 'HTTPFast::Response';
    is $res->[0], '', 'error message';
    is_deeply $res->[1], [host => 'abc'], 'headers';
    is $res->[2], 'cde', 'body';
    is_deeply $res->[3], [ 400, 'Bad request', 0, 9 ], 'response line';
}
