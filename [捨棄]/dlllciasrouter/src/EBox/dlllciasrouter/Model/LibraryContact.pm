package EBox::dlllciasrouter::Model::LibraryContact;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Global;
use EBox::DNS;
use EBox::DNS::Model::Services;
use EBox::DNS::Model::DomainTable;

use EBox::Exceptions::Internal;
use EBox::Exceptions::External;
use EBox::Exceptions::DataExists;

use LWP::Simple;
use POSIX qw(strftime);
use Try::Tiny;

##
# 讀取PoundLibrary
# @author Pulipuli Chen
##
sub getLibrary
{
    my ($self) = @_;
    return $self->parentModule()->model("PoundLibrary");
}

##
# 讀取指定的Model
#
# 我這邊稱之為Library，因為這些Model是作為Library使用，而不是作為Model顯示資料使用
# @author 20140312 Pulipuli Chen
sub loadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}

# ------------------------------------------------
# Date Setter

sub setUpdateDate
{
    my ($self, $row) = @_;

    my $date = strftime "%Y/%m/%d %H:%M:%S", localtime;

    $row->elementByName('updateDate')->setValue('<span>'.$date."</span>");
    #$row->store();
}

sub setCreateDate
{
    my ($self, $row) = @_;

    my $date = $row->valueByName("createDateField");
    if (defined($date) == 0) {
        $date = strftime "%Y/%m/%d %H:%M:%S", localtime;
        $row->elementByName('createDate')->setValue('<span>'.$date."</span>");
        $row->elementByName('createDateField')->setValue($date);
    }
    else {
        $row->elementByName('createDate')->setValue('<span>'.$date."</span>");
    }
    
    #$row->store();
}

# ------------------------------------------------
# Contact Setter

sub setContactLink
{
    my ($self, $row) = @_;

    my $link = '';

    my $desc = $row->valueByName('description');

    my $libEnc = $self->loadLibrary("LibraryEncoding");
    $desc = $libEnc->unescapeFromUtf16($desc);
    $desc = $libEnc->stripsHtmlTags($desc);
    #$desc = "如 何.,";

    if ($desc =~ m/^(http\:\/\/email\-km\.dlll\.nccu\.edu\.tw)/i) {
        $link = $link.'[<a style="background: none;text-decoration: underline;color: #A3BD5B;"  href="'.$desc.'" target="_blank">EMAIL-KM</a>]'.'<br />';
    }
    elsif ($desc =~ m/^(http)/i) {
        $link = $link.'[<a style="background: none;text-decoration: underline;color: #A3BD5B;"  href="'.$desc.'" target="_blank">LINK</a>]'.'<br />';
    }
    else {
        # 20140207 Pulipuli Chen
        # 如果不是網址，則顯示額外訊息
        my $short_desc = $desc;
        if (length($short_desc) > 10) {
            $short_desc = substr($short_desc, 0, 10) . "...";
            $short_desc = "<span title=\"".$desc."\">".$short_desc."</span>"
        }

        $link = $link.$short_desc.'<br />';
    }

    my $name = $row->valueByName('contactName');
    my $email = $row->valueByName('contactEmail');
    my $expiry = $row->valueByName('expiry');

    if ($email eq "") {
        $link = $link.$name;
    }
    elsif ($email =~ m/(@)/i) {
        $link = $link.'<a style="background: none;text-decoration: underline;color: #A3BD5B;"  href="mailto:'.$email.'">'.$name.'</a>';
    }
    else {
        $link = $link.$name.'<br />('.$email.')';
    }

    my $date = strftime "%Y/%m/%d", localtime;
    $link = $link."<br />[Update] ".$date;
    $link = $link."<br />[Expiry] ".$expiry;
    $link = "<span>".$link."</span>";

    $row->elementByName('contactLink')->setValue($link);

    #$row->store();
}

sub setDescriptionHTML
{
    my ($self, $row) = @_;

    my $desc = $row->valueByName('description');

    my $libEnc = $self->loadLibrary("LibraryEncoding");
    $desc = $libEnc->unescapeFromUtf16($desc);
    $desc = $libEnc->stripsHtmlTags($desc);
    
    $desc = "<span>".$desc."</span>";

    $row->elementByName('descriptionHTML')->setValue($desc);

    #$row->store();
}

1;
