#!/usr/bin/perl -w
use strict;
use warnings;

die "Usage: $0 <BLOSUM62> <min-score> <word>...\n" unless $#ARGV >= 2;
my ($filename, $min_score, @words) = @ARGV;

# load BLOSUM62
my %blosum = ();
open my $fh, "<", $filename or die;
my @to = ();
while (my $line = <$fh>) {
	next if $line =~ /^#/;
	chomp $line;
	my @s = split(" ", $line, -1);
	if (not @to) {
		@to = @s;
	} else {
		my $from = shift @s;
		next if $from eq 'B' or $from eq 'Z' or $from eq 'X' or $from eq '*';
		for my $i (0 .. $#to) {
			$blosum{$from}->{$to[$i]} = $s[$i];
		}
	}
}
close $fh;

# calc score
my %res = ();
for my $w (@words) {
	my $len = length($w);
	my @a = ();
	for my $neighbor (combination(length($w), keys(%blosum))) {
		my $score = 0;
		my @detail = ();
		for my $i (0 .. ($len - 1)) {
			my $v = $blosum{substr($w, $i, 1)}->{substr($neighbor, $i, 1)};
			$score += $v;
			push @detail, $v;
		}
		next if $score < $min_score;
		my $detail = join("+", @detail) =~ s/\+-/-/r;
		push @a, { neighbor => $neighbor, score => $score, detail => $detail };
	}
	@{$res{$w}} = sort {
		$b->{score} <=> $a->{score} || $a->{neighbor} cmp $b->{neighbor} } @a;
}

# print out results
print join("\t", "word", "neighborhood-words", "score", "max_score", "nsw", "detail"), "\n";
for my $w (@words) {
	print join("\t", $w,
		join("/", map { $_->{neighbor} } @{$res{$w}}),
		join("/", map { $_->{score} } @{$res{$w}}),
		max(map { $_->{score} } @{$res{$w}}),
		$#{$res{$w}},
		join("/", map { $_->{detail} } @{$res{$w}})), "\n";
}

# functions
sub combination {
	my ($n, @s) = @_;
	return @s if $n <= 1;
	return map { my $w = $_; (map { $w . $_ } @s) } (combination($n - 1, @s));
}

sub max {
	my $s = shift;
	for my $v (@_) {
		$s = $v if $s < $v;
	}
	return $s;
}
