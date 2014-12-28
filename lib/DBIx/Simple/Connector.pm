use 5.006;
use strict;

$DBIx::Simple::Connector::VERSION = '1.40';

my $no_raiseerror = $ENV{PERL_DBIX_SIMPLE_NO_RAISEERROR};

package DBIx::Simple::Connector;
use base 'DBIx::Simple';
use DBIx::Connector;
use Data::Dumper;

sub connect {
    my ($class, @arguments) = @_;
    my $self = {
        lc_columns      => 1,
        result_class    => 'DBIx::Simple::Result',
        dont_disconnect => 1,
    };

    if (defined $arguments[0] and UNIVERSAL::isa($arguments[0], 'DBIx::Connector')) {
        $self->{conn} = shift @arguments;
        Carp::carp("Additional arguments for $class->connect are ignored") if @arguments;
    } else {
        $arguments[3]->{PrintError} = 0
            unless defined $arguments[3] and exists $arguments[3]{PrintError};
        $arguments[3]->{RaiseError} = 1
            unless $no_raiseerror
            or defined $arguments[3] and exists $arguments[3]{RaiseError};
        $self->{conn} = DBIx::Connector->new(@arguments);
    }

    return undef unless $self->{conn};
    $self->{dbd} = $self->{conn}->dbh->{Driver}->{Name};
    bless $self, $class;

    $self->setup_statement_cache;

    return $self;
}

sub dbh {
    my $self = shift;

    # If the database handle has changed, invalidate our statement handle caches.
    my $new_dbh = $self->{conn}->dbh;
    if (defined $self->{old_dbh} and "$self->{old_dbh}" ne "$new_dbh") {
        $self->_clear_cache;
    }

    $self->{old_dbh} = "$new_dbh";
    return $new_dbh;
}



1;

=head1 NAME

DBIx::Simple::Connector - Initialize DBIx::Simple with a DBIx::Connector object

=head1 SYNOPSIS

  my $db = DBIx::Simple::Connector->new( DBIx::Connector->new(...) );

  my $db = DBIx::Simple::Connector->new($dsn, $username, $password, \%args);

=head1 DESCRIPTION

Works just like L<DBIx::Simple>, but accepts a DBIx::Connector object as argument to C<new()>
instead of a raw database handle.

Alternately, arguments to C<new()> will be passed to DBIx::Connector to make a database connection.

=head1 AUTHORS

Mark Stosberg <mark@stosberg.com> and Juerd Waalboer <#####@juerd.nl> <http://juerd.nl/>

=head1 SEE ALSO

L<DBIx::Simple>

L<DBIx::Connector>

=cut
