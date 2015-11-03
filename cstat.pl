#!/usr/bin/perl
#
# Copyright 2015 Allan McAleavy.  All rights reserved.
#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at docs/cddl1.txt or
# http://opensource.org/licenses/CDDL-1.0.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at docs/cddl1.txt.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
# BUGS: input parsing
#


use strict;
use warnings;
use Switch;
use POSIX qw(ceil);
use Math::BigFloat ':constant' ;
use Getopt::Long;
$| = 1;

my $interval;
my $count;
my %cpu_data;
my @mpstat;
my $node=0;
my $sock=0;
my $core=0;
my $cpu=0;
my $rest=0;
my $util=0;
my $mpstart=0;
my $tim=0;


GetOptions (
'interval=i' =>\$interval,
'count=i'    =>\$count
) or die <<USAGE_END;
USAGE: $0 [options]
        --interval | -i             # mpstat sample interval
        --count    | -c             # mpstat count
    eg,
        $0 -i 1 -c 20
USAGE_END


open(FILE,"/usr/bin/lscpu -p |") || die "Can't run lscpu - $!";
while (<FILE>)
{
      chomp;
      my($cpu,$core,$sock,$node,$rest)=split(",",$_);
      if ( $_ =~ /^[0-9]/ )
      {
          $cpu_data{$node}{$sock}{$core}{$cpu}{util} = 0 ;
          $cpu_data{$node}{$sock}{$core}{$cpu}{usr} = 0 ;
          $cpu_data{$node}{$sock}{$core}{$cpu}{sys} = 0 ;
          $cpu_data{$node}{$sock}{$core}{$cpu}{ni} = 0 ;
      }
}
close(FILE);

sub update_cpu
{
    my $c = shift;
    my $nusr = shift;
    my $nsys = shift;
    my $ni = shift;

    foreach my $node (sort keys %cpu_data)
    {
        foreach my $sock (sort keys %{$cpu_data{$node}})
        {
                 foreach my $core (sort keys %{$cpu_data{$node}{$sock}})
                 {
                        foreach my $cpu (sort keys %{$cpu_data{$node}{$sock}{$core}})
                        {
                            if ( $c == $cpu )
                            {

                                        $cpu_data{$node}{$sock}{$core}{$cpu}{usr} = scalar($nusr);
                                        $cpu_data{$node}{$sock}{$core}{$cpu}{sys} = scalar($nsys);
                                        $cpu_data{$node}{$sock}{$core}{$cpu}{ni} = scalar($ni);
                                        $cpu_data{$node}{$sock}{$core}{$cpu}{util} = ($cpu_data{$node}{$sock}{$core}{$cpu}{usr} + $cpu_data{$node}{$sock}{$core}{$cpu}{sys} + $cpu_data{$node}{$sock}{$core}{$cpu}{ni}) ;

                            }
                        }
                 }
        }

    }
}

sub print_cpu
{
    printf("%s %8s %4s %4s %4s %6s %6s %6s \n","Time","Node","Sock","Core"," CPU","USR ","SYS ","UTIL");
    printf("-------------------------------------------------\n") ;

   my $tm = shift ;

   foreach my $node (sort keys %cpu_data)
    {
        foreach my $sock (sort keys %{$cpu_data{$node}})
        {
                 foreach my $core (sort keys %{$cpu_data{$node}{$sock}})
                 {
                        foreach my $cpu (sort keys %{$cpu_data{$node}{$sock}{$core}})
                        {
                                    my @nums = 1 .. 100;
                                    my $hashes;
                                    my $chr="#";

                                    foreach my $c (@nums)
                                     {
                                       if ( $c <= $cpu_data{$node}{$sock}{$core}{$cpu}{util})
                                         {
                                                $hashes = $hashes . $chr;
                                         }
                                     }
                                     if ( $cpu_data{$node}{$sock}{$core}{$cpu}{util} < 1) { $hashes=""; }
                                switch(ceil($cpu_data{$node}{$sock}{$core}{$cpu}{util}))
                                {
                                case [0]      { printf("%.8s %4d %4d %4d %4d %6.2f %6.2f %6.2f \e[38;5;0m%3s\e[0m \n",
                                                $tm , $node , $sock , $core , $cpu , $cpu_data{$node}{$sock}{$core}{$cpu}{usr} ,
                                                $cpu_data{$node}{$sock}{$core}{$cpu}{sys} ,$cpu_data{$node}{$sock}{$core}{$cpu}{util} ,$hashes); }
                                case [1..10]  { printf("%.8s %4d %4d %4d %4d %6.2f %6.2f %6.2f \e[38;5;24m%3s\e[0m \n",
                                                $tm , $node , $sock , $core , $cpu ,$cpu_data{$node}{$sock}{$core}{$cpu}{usr} ,
                                                $cpu_data{$node}{$sock}{$core}{$cpu}{sys} , $cpu_data{$node}{$sock}{$core}{$cpu}{util} ,$hashes); }
                                case [10..20] { printf("%.8s %4d %4d %4d %4d %6.2f %6.2f %6.2f \e[38;5;25m%3s\e[0m \n",
                                                $tm , $node , $sock , $core , $cpu , ,$cpu_data{$node}{$sock}{$core}{$cpu}{usr} ,
                                                $cpu_data{$node}{$sock}{$core}{$cpu}{sys} , $cpu_data{$node}{$sock}{$core}{$cpu}{util} ,$hashes); }
                                case [20..30] { printf("%.8s %4d %4d %4d %4d %6.2f %6.2f %6.2f \e[38;5;26m%3s\e[0m \n",
                                                $tm , $node , $sock , $core , $cpu , ,$cpu_data{$node}{$sock}{$core}{$cpu}{usr} ,
                                                $cpu_data{$node}{$sock}{$core}{$cpu}{sys} , $cpu_data{$node}{$sock}{$core}{$cpu}{util} ,$hashes); }
                                case [30..40] { printf("%.8s %4d %4d %4d %4d %6.2f %6.2f %6.2f \e[38;5;27m%3s\e[0m \n",
                                                $tm , $node , $sock , $core , $cpu , ,$cpu_data{$node}{$sock}{$core}{$cpu}{usr} ,
                                                $cpu_data{$node}{$sock}{$core}{$cpu}{sys} , $cpu_data{$node}{$sock}{$core}{$cpu}{util} ,$hashes); }
                                case [40..50] { printf("%.8s %4d %4d %4d %4d %6.2f %6.2f %6.2f \e[38;5;37m%3s\e[0m \n",
                                                $tm , $node , $sock , $core , $cpu , ,$cpu_data{$node}{$sock}{$core}{$cpu}{usr} ,
                                                $cpu_data{$node}{$sock}{$core}{$cpu}{sys} , $cpu_data{$node}{$sock}{$core}{$cpu}{util} ,$hashes); }
                                case [50..60] { printf("%.8s %4d %4d %4d %4d %6.2f %6.2f %6.2f \e[38;5;36m%3s\e[0m \n",
                                                $tm , $node , $sock , $core , $cpu , ,$cpu_data{$node}{$sock}{$core}{$cpu}{usr} ,
                                                $cpu_data{$node}{$sock}{$core}{$cpu}{sys} , $cpu_data{$node}{$sock}{$core}{$cpu}{util} ,$hashes); }
                                case [60..70] { printf("%.8s %4d %4d %4d %4d %6.2f %6.2f %6.2f \e[38;5;35m%3s\e[0m \n",
                                                $tm , $node , $sock , $core , $cpu , ,$cpu_data{$node}{$sock}{$core}{$cpu}{usr} ,
                                                $cpu_data{$node}{$sock}{$core}{$cpu}{sys} , $cpu_data{$node}{$sock}{$core}{$cpu}{util} ,$hashes); }
                                case [70..80] { printf("%.8s %4d %4d %4d %4d %6.2f %6.2f %6.2f \e[38;5;34m%3s\e[0m \n",
                                                $tm , $node , $sock , $core , $cpu , ,$cpu_data{$node}{$sock}{$core}{$cpu}{usr} ,
                                                $cpu_data{$node}{$sock}{$core}{$cpu}{sys} , $cpu_data{$node}{$sock}{$core}{$cpu}{util} ,$hashes); }
                                case [80..90] { printf("%.8s %4d %4d %4d %4d %6.2f %6.2f %6.2f \e[348;5;94m%3s\e[0m \n",
                                                $tm , $node , $sock , $core , $cpu , ,$cpu_data{$node}{$sock}{$core}{$cpu}{usr} ,
                                                $cpu_data{$node}{$sock}{$core}{$cpu}{sys} , $cpu_data{$node}{$sock}{$core}{$cpu}{util} ,$hashes); }
                                case [90..100]{ printf("%.8s %4d %4d %4d %4d %6.2f %6.2f %6.2f \e[38;5;196m%3s\e[0m \n",
                                                $tm , $node , $sock , $core , $cpu , ,$cpu_data{$node}{$sock}{$core}{$cpu}{usr} ,
                                                $cpu_data{$node}{$sock}{$core}{$cpu}{sys} , $cpu_data{$node}{$sock}{$core}{$cpu}{util} ,$hashes); }
                                }
                       }
                 }
         printf("-------------------------------------------------\n") ;
      }
}
}

open(FILE,"/usr/bin/mpstat -P ALL " . $interval . " " . $count . " |") || die "Can't open /usr/bin/mpstat - $!";
while (<FILE>)
{
  chomp;
  next if (/all/);   # ignore header

  if ($_ =~ /CPU/)
  {
      $mpstart=1;
      next ;
  }

  if ( $_ =~ /^[0-9][0-9]:/ )
  {
  my($tm,$cp,$us,$ni,$sy,$rest) = split(" ",$_);

  $tim = $tm ;
  update_cpu($cp,scalar($us),scalar($sy),scalar($ni));
  }


  if (( $_ =~ /^$/ ) && ( $mpstart == 1))
  {
     print_cpu($tim);
     sleep($interval);
     system("clear");
  }
}
close(FILE);
