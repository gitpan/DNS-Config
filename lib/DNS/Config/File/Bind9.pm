#!/usr/local/bin/perl -w
######################################################################
#
# DNS/Config/File/Bind9.pm
#
# $Id: Bind9.pm,v 1.6 2003/02/07 23:58:09 awolf Exp $
# $Revision: 1.6 $
# $Author: awolf $
# $Date: 2003/02/07 23:58:09 $
#
# Copyright (C)2001-2003 Andy Wolf. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
######################################################################

package DNS::Config::File::Bind9;

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;

use vars qw(@ISA);

use DNS::Config;
use DNS::Config::Server;
use DNS::Config::Statement;
use DNS::Config::Statement::Zone;
use DNS::Config::Statement::Options;

@ISA = qw(DNS::Config::File);

my $VERSION   = '0.65';
my $REVISION  = sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

sub new {
	my($pkg, $file, $config) = @_;
	my $class = ref($pkg) || $pkg;

	my $self = {
		'FILE' => $file
	};

	$self->{'CONFIG'} = $config if($config);
	
	bless $self, $class;
	
	return $self;
}

sub parse {
	my($self, $file) = @_;
	
	my @lines = $self->read($file);

	# substitute include statements completely
	for(my $i=0 ; defined $lines[$i] ; $i++) {
		if($lines[$i] =~ /^\s*include\s+\"*(.+)\"*\s*\;/i) {
			my @included = $self->read($1);
			splice @lines, $i, 1, @included
		}
	}
	
	return undef unless(scalar @lines);

	$self->{'CONFIG'} = new DNS::Config() if(!$self->{'CONFIG'});
	
	my $result;
	for my $line (@lines) {
		$line =~ s/\s+/ /g;
		$line =~ s/\/\/.*$//g;
		$line =~ s/\#.*$//g;
		$result .= $line;
	}

	my $tree = &analyze_brackets($result);
	my @res = &analyze_statements(@$tree);

	foreach my $temp (@res) {
		my @temp = @$temp;
		my $type = shift @temp;

		my $statement;

		eval {
			my $tmp = 'DNS::Config::Statement::' . ucfirst(lc $type);
			$statement = $tmp->new();
			$statement->parse_tree(@temp);
		};

		if($@) {
			#warn $@;
			
			$statement = DNS::Config::Statement->new();
			$statement->parse_tree($type, @temp);
		}

		$self->{'CONFIG'}->add($statement);
	}
		
	return $self;
}

sub dump {
	my($self, $file) = @_;
	
	$file = $file || $self->{'FILE'};

	return undef unless($file);
	return undef unless($self->{'CONFIG'});
	
	if($file) {
		if(open(FILE, ">$file")) {
			my $old_fh = select(FILE);

			map { $_->dump() } $self->config()->statements();
			
			select($old_fh);
			close FILE;
		}
		else { return undef; }
	}
	else {
		map { $_->dump() } $self->config()->statements();
	}
	
	return $self;
}

sub config {
	my($self) = @_;
	
	return($self->{'CONFIG'});
}

sub analyze_brackets {
	my($string) = @_;
	
	my @chars = split //, $string;

	my $tree = [];
	my @chunks;
	my @stack;

	my %matching = (
		'(' => ')',
		'[' => ']',
		'<' => '>',
		'{' => '}',
	);

	for my $char (@chars) {
		if(grep {$char eq $_} keys(%matching)) {
			my $temp = [];
			push @$tree, $temp;
			push @chunks, $tree;
			push @stack, $matching{$char};
			$tree = $temp;
		}
		elsif(grep {$char eq $_} values(%matching)) {
			my $expected = pop @stack;
			die "Invalid order !\n" if((!defined $expected) || ($char ne $expected));
			$tree = pop @chunks;
			die "Unmatched closing !\n" if(!ref($tree));
		}
		else {
			my $noe = scalar(@$tree);
			
			if((!$noe) || (ref($$tree[$noe-1]) eq 'ARRAY')) {
				push @$tree, ($char);
			}
			else {
				$$tree[$noe-1] .= $char;
			}
		}
	}

	die "Unbalanced !\n" if(scalar @stack);

	return($tree);
}

sub analyze_statements {
	my(@array) = @_;
	my @result;
	my $full;
	
	for my $line (@array) {
		if(!ref($line)) {
			$line =~ s/\s*\;\s*/\;/g;

			my(@parts) = split /;/, $line, -1;

			shift @parts if(!$parts[0]);

			if($parts[$#parts-1] eq '') {
				$full = 1;
				pop @parts;
			}
			else {
				$full = 0;
			}

			for my $temp (@parts) {
				if($temp) {
					$temp =~ s/^\s*//g;
					
					my @chunks = split / /, $temp;

					push @result, (\@chunks);
				}
			}
		}
		else {
			my @statements = &analyze_statements(@$line);

			my @temp;
			if(!$full) { my $temp = pop @result; @temp = @$temp; }
			push @temp, (\@statements);
			push @result, (\@temp);
		}
	}

	return(@result);
}

1;

__END__

=pod

=head1 NAME

DNS::Config::File::Bind9 - Concrete adaptor class

=head1 SYNOPSIS

use DNS::Config::File::Bind9;

my $file = new DNS::Config::File::Bind9($file_name_string);

$file->parse($file_name_string);
$file->dump($fie_name_string);
$file->debug();

$file->config(new DNS::Config());


=head1 ABSTRACT

This class represents a concrete configuration file for ISCs
Bind v9 domain name service daemon (DNS).


=head1 DESCRIPTION

This class, the Bind9 file adaptor, knows how to write the
information to a file in the Bind9 daemon specific format.


=head1 AUTHOR

Copyright (C)2001-2003 Andy Wolf. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Please address bug reports and comments to: 
zonemaster@users.sourceforge.net


=head1 SEE ALSO

L<DNS::Config>, L<DNS::Config::File>


=cut
