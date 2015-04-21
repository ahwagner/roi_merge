#!/usr/bin/perl -w
use strict;
use List::Util qw(max);
use Scalar::Util qw(looks_like_number);

# This script uses a sorted input

my $file = pop(@ARGV);

open(BED, "<", $file) or die $!;

my %coordinates;
my $last_chr = '';
my $last_start;
my $line = 0;

# Parse bed file and merge by gene identifier
while (<BED>){
	chomp;
	$line += 1;
	my ($chr, $start, $stop, $gene) = split("\t");
	die "Not a sorted input on line $line.\n" if ($last_chr eq $chr 
													and $last_start > $start);
	$last_chr = $chr;
	$last_start = $start;
	if (defined $coordinates{$gene}){
		my $hchr = $coordinates{$gene}{'contig'}[-1];
		my $hstart = $coordinates{$gene}{'start'}[-1];
		my $hstop = $coordinates{$gene}{'stop'}[-1];
		if ($hchr eq $chr and $hstop > $start){
			$coordinates{$gene}{'stop'}[-1] = max($hstop, $stop);
		}else{
			push(@{$coordinates{$gene}{'start'}}, $start);
			push(@{$coordinates{$gene}{'stop'}}, $stop);
			push(@{$coordinates{$gene}{'contig'}}, $chr);
		}
	}else{
		$coordinates{$gene}{'contig'} = [$chr];
		$coordinates{$gene}{'start'} = [$start];
		$coordinates{$gene}{'stop'} = [$stop];
	}
}

# Sort output
my @rows;
foreach my $gene (keys %coordinates){
	while(@{$coordinates{$gene}{'contig'}}){
		my $hchr = pop $coordinates{$gene}{'contig'};
		my $hstart = pop $coordinates{$gene}{'start'};
		my $hstop = pop $coordinates{$gene}{'stop'};
		push(@rows, [$hchr, $hstart, $hstop, $gene]);
	}
}

@rows = sort bed @rows;

# Print
foreach (@rows) {
	print join("\t", @{$_})."\n";
}

exit;

sub bed {
	if (looks_like_number(${$a}[0]) and looks_like_number(${$b}[0])){
		if (${$a}[0] != ${$b}[0]){
			return ${$a}[0] <=> ${$b}[0];
		}
	}else{
		if (${$a}[0] ne ${$b}[0]){
			return ${$a}[0] cmp ${$b}[0];
		}
	}
	return ${$a}[1] <=> ${$b}[1] unless ${$a}[1] == ${$b}[1];
	return ${$a}[2] <=> ${$b}[2] unless ${$a}[2] == ${$b}[2];
	return ${$a}[3] cmp ${$b}[3];
}