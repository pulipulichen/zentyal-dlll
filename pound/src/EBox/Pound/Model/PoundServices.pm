package EBox::Pound::Model::PoundServices;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::DomainName;
use EBox::Types::HostIP;
use EBox::Types::Port;
use EBox::Types::Text;
use EBox::Types::Boolean;

use EBox::Global;
use EBox::DNS;
use EBox::DNS::Model::Services;
use EBox::DNS::Model::DomainTable;

use EBox::Exceptions::Internal;

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
            fieldName => 'boundLocalDns',
            printableName => __('Bound Local DNS'),
            editable => 1,
            optional => 0,
            defaultValue => 1,
            help => __('If you want to bound this service with local DNS, this domain name will be created when service creates. The other hand, this doamin name will be removed when service deletes.'),
        ),

        # Enable Keep Last
        new EBox::Types::Boolean(
            fieldName => 'enabled',
            printableName => __('Enabled'),
            editable => 1,
            optional => 0,
            defaultValue => 1,
        ),
    );

    my $dataTable =
    {
        tableName => 'PoundServices',
        printableTableName => __('Services'),
        defaultActions => [ 'add', 'del', 'editField', 'changeView' ],
        modelDomain => 'Pound',
        tableDescription => \@fields,
        printableRowName => __('Pound Service'),
        sortedBy => 'domainName',
        'HTTPUrlView'=> 'Pound/Composite/Global',
        help => __('This is the help of the model'),
    };

    return $dataTable;
}

sub getExternalIpaddr
{
    my $network = EBox::Global->modInstance('network');
    my $address;
    foreach my $if (@{$network->allIfaces()}) {
        if ($network->ifaceIsExternal($if)) {
            $address = $network->ifaceAddress($if);
        }
    }
    my @ipaddr=($address);
    return \@ipaddr;
}

sub getPortHeader 
{
    my ($self, $row) = @_;

    # 測試用，變成ID前幾碼
    my $ipaddr = $row->valueByName('ipaddr');
    my @parts = split('\.', $ipaddr);
    my $partC = $parts[2];
        $partC = substr($partC, -1);
    my $partD = $parts[3];
        if (length($partD) == 1) {
            $partD = "0" . $partD;
        }
        else {
            $partC = substr($partC, -2);
        }
     my $portHeader = $partC.$partD;
     
     #$row->elementByName("description")->setValue($portHeader);
     #$row->store();
     #throw EBox::Exceptions::Internal("port header: ".$portHeader);

     return $portHeader;
}

sub addedRowNotify
{
    my ($self, $row) = @_;

    
    if ($row->valueByName('boundLocalDns') && $row->valueByName('enabled')) {
        my $domainName = $row->valueByName('domainName');
        
        #my $domainsModel = EBox::DNS::instance()->model("DomainTable");
        #my $global = EBox::Global->getInstance();
        #my $dnsModule = @{$global->modInstancesOfType('EBox::DNS')};
        #my $dnsModule = EBox::Global->modInstance('EBox::DNS')->model("DomainTable");
        #my $dnsModule = EBox::Global->modInstance('dns');
        #my $domainsModel = $dnsModule->model("DomainTable");
        #$domainsModel->addDomain({domain_name => $domainName});
        #$domainsModel->add( domain => $domainName, ipaddr => '192.168.1.1');
        #$domainsModel->addDomain($domainName);
        #$dnsModule->addDomain({
        #       domain_name => $domainName 
        #});

        my $gl = EBox::Global->getInstance();
        my $dns = $gl->modInstance('dns');
        $dns->addDomain({
            domain_name => $domainName,
            #ipAddresses => $self->getExternalIpaddr(),
        });
    }
}

sub deletedRowNotify
{
    my ($self, $row) = @_;
    my $domainName = $row->valueByName('domainName');

    my $gl = EBox::Global->getInstance();
    my $dns = $gl->modInstance('dns');
    my $domModel = $dns->model('DomainTable');
    my $id = $domModel->findId(domain => $domainName);
    $domModel->removeRow($id);
}

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;
    
    $self->deletedRowNotify($oldRow);
    $self->addedRowNotify($row);
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
