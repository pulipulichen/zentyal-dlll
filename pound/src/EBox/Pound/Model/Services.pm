package EBox::Pound::Model::Services;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::DomainName;
use EBox::Types::HostIP;
use EBox::Types::Port;
use EBox::Types::Text;
use EBox::Types::Boolean;

# Method: _table
#
# Overrides:
#
#       <EBox::Model::DataTable::_table>
#
sub _table
{
    my ($self) = @_;

    my @fields = (
        new EBox::Types::DomainName(
            fieldName => 'domainName',
            printableName => __('Domain Name'),
            editable => 1,
        ),
        new EBox::Types::HostIP(
            fieldName => 'ipaddr',
            printableName => __('Internal IP Address'),
            editable => 1,
        ),
        new EBox::Types::Port(
            fieldName => 'port',
            printableName => __('Internal Port'),
            defaultValue => 80,
            editable => 1,
        ),
        new EBox::Types::Text(
            fieldName => 'description',
            printableName => __('Description'),
            editable => 1,
        ),
        new EBox::Types::Boolean(
            fieldName => 'bound_local_dns',
            printableName => __('Bound Local DNS'),
            editable => 1,
            optional => 0,
            defaultValue => 1,
            help => __('If you want to bound this service with local DNS, this domain name will be created when service creates. The other hand, this doamin name will be removed when service deletes.'),
        ),
        new EBox::Types::Boolean(
            fieldName => 'enabled',
            printableName => __('enabled'),
            editable => 1,
            optional => 0,
            defaultValue => 0
        ),
    );

    my $dataTable =
    {
        tableName => 'Services',
        printableTableName => __('Services'),
        defaultActions => [ 'add', 'del', 'editField', 'changeView' ],
        pageTitle => 'Services',
        modelDomain => 'Pound',
        tableDescription => \@fields,
        printableRowName => __('Pound Service'),
        sortedBy => 'domainName',
        'HTTPUrlView'=> 'DNS/Composite/Global',
        help => __('This is the help of the model'),
    };

    return $dataTable;
}

sub addedRowNotify
{
    my ($self, $row) = @_;

# 測試用，修改自己模組的port    
#    my $port = $row->valueByName('port');
#    my $pound = $self->parentModule();
#    my $settings = $pound->model('Settings');
#    $settings->setAll('port', $port);

}

# 找尋row用
#sub hostDomainChangedDone
#{
#    my ($self, $oldDomainName, $newDomainName) = @_;
#
#    my $domainModel = $self->model('DomainTable');
#    my $row = $domainModel->find(domain => $oldDomainName);
#    if (defined $row) {
#        $row->elementByName('domain')->setValue($newDomainName);
#        $row->store();
#    }
#}

# 新增row用
#    for my $mod (@modsToAdd) {
#        $self->add( module => $mod, enabled => 1 );
#    }
1;
