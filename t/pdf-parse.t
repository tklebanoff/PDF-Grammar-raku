#!/usr/bin/env perl6

use Test;
use PDF::Grammar::PDF;

for ('%PDF-1.0', '%PDF-1.7') {
    ok($_ ~~ /^<PDF::Grammar::PDF::pdf_header>$/, "pdf_header: $_");
}

my $header = '%PDF-1.0';
ok($header ~~ /^<PDF::Grammar::PDF::pdf_header>$/, "pdf_header: $header");

my $indirect_obj1 = '1 0 obj
<<
/Type /Catalog
/Pages 3 0 R
/Outlines 2 0 R
>>
endobj
';

my $body = $indirect_obj1 ~
'2 0 obj
<<
/Type /Outlines
/Count 0
>>
endobj
3 0 obj
<<
/Type /Pages
/Count 1
/Kids [4 0 R]
>>
endobj
4 0 obj
<<
/Type /Page
/Parent 3 0 R
/Resources << /Font << /F1 7 0 R >>/ProcSet 6 0 R
>>
/MediaBox [0 0 612 792]
/Contents 5 0 R
>>
endobj
5 0 obj
<< /Length 44 >>
stream
BT
/F1 24 Tf
100 100 Td (Hello, world!) Tj
ET
endstream
endobj
6 0 obj
[/PDF /Text]
endobj
7 0 obj
<<
/Type /Font
/Subtype /Type1
/Name /F1
/BaseFont /Helvetica
/Encoding /MacRomanEncoding
>>
endobj';

for ($indirect_obj1) {
    ok($_ ~~ /^<PDF::Grammar::PDF::indirect_object>$/, "indirect obj")
        or diag $_;
}

for ($indirect_obj1, $body) {
    ok($_ ~~ /^<PDF::Grammar::PDF::indirect_object>+$/, "body")
        or diag $_;
}

my $xref = "xref
0 8
0000000000 65535 f
0000000009 00000 n
0000000074 00000 n
0000000120 00000 n
0000000179 00000 n
0000000322 00000 n
0000000415 00000 n
0000000445 00000 n
";
ok($xref ~~ /^<PDF::Grammar::PDF::xref>$/, "xref")
    or diag $xref;

my $trailer = 'trailer
<<
/Size 8
/Root 1 0 R
>>
startxref
553
';
ok($trailer ~~ /^<PDF::Grammar::PDF::trailer>$/, "trailer")
    or diag $trailer;

my $nix_pdf = "$header
$body
$xref$trailer%\%EOF";

my $bin_commented_pdf = "$header
%âãÏÓ
$body
$xref$trailer%\%EOF";

my $edited_pdf = "$header
$body
$xref$trailer
$body
$xref$trailer%\%EOF";

(my $mac_osx_pdf = $nix_pdf)  ~~ s:g/\n/\r/;
# nb although the document remains parsable, converting to ms-dos line-endings
# changes byte offsets and corrupts the xref table
(my $ms_dos_pdf = $nix_pdf)  ~~ s:g/\n/\r\n/;

for (unix => $nix_pdf,
     bin_comments => $bin_commented_pdf,
     edit_history => $edited_pdf,
     mac_osx_formatted => $mac_osx_pdf,
     ms_dos_formatted => $ms_dos_pdf) {
     ok(PDF::Grammar::PDF.parse($_.value), "pdf parse - " ~ $_.key)
       or diag $_.value;

    # see of we can independently locate the trailer
    ok($_.value ~~ /<PDF::Grammar::PDF::pdf_tail>$/, "file_trailer match " ~ $_.key);
}

done;