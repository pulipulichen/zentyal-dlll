package EBox::dlllciasrouter::Model::ExportsSetting;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::DomainName;
use EBox::Types::HostIP;
use EBox::Types::Port;
use EBox::Types::Text;
use EBox::Types::HTML;
use EBox::Types::Boolean;
use EBox::Types::IPRange;
use EBox::Types::Union;
use EBox::Types::Union::Text;
use EBox::Types::Select;
use EBox::Types::HasMany;

use EBox::Global;
use EBox::DNS;
use EBox::DNS::Model::Services;
use EBox::DNS::Model::DomainTable;

use EBox::Exceptions::Internal;
use EBox::Exceptions::External;

use LWP::Simple;
use Try::Tiny;

sub getOptions
{
    my ($self) = @_;

    my $options = ();
    $options->{tableName} = "ExportsSetting";
    $options->{printableName} = __("Exports");
    $options->{printableRowName} = __("Export");
    $options->{expiryDate} = __("NEVER");
    return $options;
}

sub _table
{
    my ($self) = @_;
    
    my $options = $self->getOptions();
    my $tableName = $options->{tableName};

    my $fieldsFactory = $self->loadLibrary('LibraryFields');
    my @fields = ();

    push(@fields, $fieldsFactory->createFieldConfigEnable());

    push(@fields, new EBox::Types::DomainName(
              'fieldName'     => 'dir',
              'printableName' => __('Share Directory '),
              'help' => __("Use server's domain name."),
              "editable" => 1,
             ));

    # http://linux.vbird.org/linux_server/0330nfs.php#nfsserver_exports
    # https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/5/html/Deployment_Guide/s1-nfs-server-config-exports.html

    # 範圍
    push(@fields, new EBox::Types::Text(
            'fieldName'     => 'host',
            'printableName' => __('Share Network'),
            "editable" => 1,
            'defaultValue' => "10.0.0.0/8",
            "help" => __("Single host: IP, 10.0.0.254. <br />" 
                . "Wildcard (*) with domain name: *.excample.com. <br />"
                . "IP networks: 10.0.0.0/8"),
        ));

    push(@fields, new EBox::Types::Boolean(
            'fieldName'     => 'readOnly',
            'printableName' => __('Read Only'),
            "editable" => 1,
            'hiddenOnSetter' => 0,
            'hiddenOnViewer' => 1,
        ));
    push(@fields, new EBox::Types::Boolean(
            'fieldName'     => 'async',
            'printableName' => __('Async'),
            "editable" => 1,
            "defaultValue" => 1,
            'hiddenOnSetter' => 0,
            'hiddenOnViewer' => 1,
        ));
    push(@fields, new EBox::Types::Select(
            'fieldName' => 'squash',
            'printableName' => __("Squash"),
            'populate' => \&_populateFieldSquash,
            "editable" => 1,
            'hiddenOnSetter' => 0,
            'hiddenOnViewer' => 1,
        ));

    push(@fields, $fieldsFactory->createFieldContactName());
    push(@fields, $fieldsFactory->createFieldContactEmail());
    push(@fields, $fieldsFactory->createFieldDisplayContactLink());

    push(@fields, $fieldsFactory->createFieldDescription());
    push(@fields, $fieldsFactory->createFieldDescriptionHTML());

    push(@fields, $fieldsFactory->createFieldExpiryDate($options->{expiryDate}));
    push(@fields, $fieldsFactory->createFieldCreateDateData());
    push(@fields, $fieldsFactory->createFieldCreateDateDisplay());
    push(@fields, $fieldsFactory->createFieldDisplayLastUpdateDate());
    

    my $dataTable =
    {
        'tableName' => $tableName,
        'printableTableName' => $options->{printableName},
        'defaultActions' => [ 'add', 'del', 'editField', 'clone', 'changeView' ],
        'modelDomain' => 'dlllciasrouter',
        'tableDescription' => \@fields,
        'pageTitle' => $options->{printableName},
        'printableRowName' => $options->{printableRowName},
        'HTTPUrlView'=> 'dlllciasrouter/View/ExportsSetting',
        'order' => 1,
    };

    return $dataTable;
}

# 20150529 Pulipuli
sub _populateFieldSquash 
{
    return [
                {
                    value => 'no_root_squash',
                    printableValue => __('no_root_squash: Allow original root permission'),
                },
                {
                    value => 'root_squash',
                    printableValue => __('root_squash: Root will be squashed to "nfsnobody".'),
                },
                {
                    value => 'all_squash',
                    printableValue => __('all_squash: Any user will be squashed to "nfsnobody".'),
                },
            ];
}

# -----------------------------------------

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


# ---------------------------------------

my $ROW_NEED_UPDATE = 0;

sub addedRowNotify
{
    my ($self, $row) = @_;

    $ROW_NEED_UPDATE = 1;

    my $lib = $self->getLibrary();
    my $libCT = $self->loadLibrary('LibraryContact');
    try 
    {
        $libCT->setCreateDate($row);
        $libCT->setUpdateDate($row);
        $libCT->setContactLink($row);
        $libCT->setDescriptionHTML($row);

        $row->store();
    } catch {
        $lib->show_exceptions($_ . "(ExportsSetting->updateRowNotify())");
    };
    
    $ROW_NEED_UPDATE = 0;
}

sub deletedRowNotify
{
    my ($self, $row) = @_;
    my $lib = $self->getLibrary();
    try 
    {

    } catch {
        $lib->show_exceptions($_ . "(ExportsSetting->updateRowNotify())");
    };
}

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;
    my $libCT = $self->loadLibrary('LibraryContact');
    my $lib = $self->getLibrary();

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;
        
        try 
        {
            $libCT->setCreateDate($row);
            $libCT->setUpdateDate($row);
            $libCT->setContactLink($row);
            $libCT->setDescriptionHTML($row);

            $row->store();
        } catch {
            $lib->show_exceptions($_ . "(ExportsSetting->updateRowNotify())");
        };
        $ROW_NEED_UPDATE = 0;
    }
}

1;
