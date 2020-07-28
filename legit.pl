#!/usr/bin/perl

error_checking();
if ($ARGV[0] eq "init") {
  init();
}
elsif (! -d ".legit"){
  print "legit.pl: error: no .legit directory containing legit repository exists\n";
}
elsif ($ARGV[0] eq "add") {
  add();
}
elsif ($ARGV[0] eq "commit") {
  commit();
}
elsif ($ARGV[0] eq "log") {
  LOG(); # error message: Can't take log of 0 at legit.pl line 17
}
elsif ($ARGV[0] eq "show") {
  show();
}


sub init {
  if (-d ".legit") {
    print STDERR "legit.pl: error: .legit already exists\n";
    exit 1;
  }

  mkdir ".legit";
  print "Initialized empty legit repository in .legit\n";

  mkdir ".legit/index";

}

sub add {
  shift @ARGV;
  foreach $file (@ARGV) {
      ########
    open IN, '<', $file or print "legit.pl: error: can not open 'non_existent_file'\n" and exit 1;

    if (!($file =~ /^[a-zA-Z0-9][a-zA-z0-9\.\-\_]*$/g)) {
      print STDERR "legit.pl: error: invalid filename '$file'\n";
      exit 1;
    }
    if (! -e $file) {
      print STDERR "legit.pl: error: can not open '$file'\n";
      exit 1;
    }

    open OUT, '>', ".legit/index/$file" or die; # /$file!
    while($line = <IN>) {
      print OUT $line;
    }
    close IN; # !
    close OUT;
  }
}
sub next_commit_num
{
    my $commit_no = 0;
    my $commit_dir = ".legit/commit.$commit_no";
    while (-d $commit_dir)
    {
        $commit_no++;
        $commit_dir = ".legit/commit.$commit_no";
    }
    return $commit_no;
}
# 0 if same, 1 if diff
sub compare_files
{
    my ( $file1, $file2 ) = @_;

    open my $F1, "<", $file1 or return 1;
    my @arr1 = <$F1>;
    close $F1;
    open my $F2, "<", $file2 or return 1;
    my @arr2 = <$F2>;
    close $F2;

    scalar @arr1 == scalar @arr2 or return 1;

    foreach my $elem1 (@arr1)
    {
        if (scalar @arr2 > 0)
        {
            $elem2 = shift @arr2;
            $elem1 eq $elem2 and next;
            return 1;
        }
        else
        {
            return 1;
        }
    }

    return 0;
}

sub commit {
  # Save copy of all files in index to the repo
  ($#ARGV > 1) or print STDERR "usage: legit.pl commit [-a] -m commit-message\n" and exit 1;
  $m = 1;
  while ($ARGV[$m] ne "-m")
  {
      $m++;
  }
  # check if message exists. Assume that the message is ascii and doesn't start with a '-'
  $#ARGV > $m and substr($ARGV[$m+1], 0, 1) ne "-" or print STDERR "usage: legit.pl commit [-a] -m commit-message\n" and exit 1;
  $i = 1;
  $update_index = 0;
  while ($i <= $#ARGV)
  {
      $ARGV[$i] eq "-a" and $update_index = 1 and last;
      $i++;
  }
  if ($update_index)
  {
      foreach $index_file (glob ".legit/index/*")
      {
          $index_file =~ m/^\.legit\/index\/(.+)$/g;
          $file = $1;
          # delete file for -a
          if (! open F, "<", $file) {
            unlink ".legit/index/$file";
          }
          else {
            @arr = <F>;
            close F;
            open F, ">", "$index_file" or die;
            while (scalar @arr > 0)
            {
                $line = shift @arr;
                print F "$line";
            }
            close F;
          }
      }
  }
  # Assume we do need to commit
  $commit = 1;
  $commit_no = next_commit_num();
  $commit_message = $ARGV[$m+1];
  # Save a copy of all files in the index to the repo or print "Nothing to commit" if index hasn't changed compared to prev commit
  if ($commit_no > 0)
  {
      $commit = 0;
      $prev_commit_no = $commit_no-1;
      foreach $index_file (glob ".legit/index/*")
      {
          $index_file =~ m/^\.legit\/index\/(.+)$/g;
          $file = $1;
          if (compare_files("$index_file", ".legit/commit.$prev_commit_no/$file"))
          {
              $commit = 1;
              last;
          }
      }
      # account for removed files here
      if ($commit == 0)
      {
          foreach $commit_file (glob ".legit/commit.$prev_commit_no/*")
          {
              $commit_file =~ m/^\.legit\/commit.$prev_commit_no\/(.+)$/g;
              $file = $1;
              if (not -e ".legit/index/$file")
              {
                  $commit = 1;
                  last
              }
          }
      }
      open $log, ">>", ".legit/log.txt" or die;
  }
  else
  {
      open $log, ">", ".legit/log.txt" or die;
  }
  if ( $commit )
  {
      $commit_dir = ".legit/commit.$commit_no";
      #printf("its time to COMMIT\n");
      mkdir "$commit_dir" or die "$commit_dir\n";
      foreach $index_file (glob ".legit/index/*")
      {
          $index_file =~ m/^\.legit\/index\/(.+)$/g;
          $file = $1;
          open F, "<", "$index_file" or die;
          while ( $line = <F> )
          {
              push @arr, $line;
          }
          close F;
          open F, ">", ".legit/commit.$commit_no/$file" or die;
          while ( scalar @arr > 0 )
          {
              $line = shift @arr;
              print F "$line";
          }
          close F;
          $commit=0;
      }
      print $log "$commit_no $commit_message\n";
      print "Committed as commit $commit_no\n";
  } elsif ($commit == 0)
  {
      print STDERR "nothing to commit\n";
  }
  close $log;

}

sub LOG {
  open FILE, '<', ".legit/log.txt" or die;
  @lines = reverse <FILE>; ####
  foreach $line(@lines) {
    print $line; # "$line"?
  }
  close FILE;
}

sub show {
  # check number of arguments TODO: check error mesage
  if ($#ARGV != 1) {
    print STDERR "usage: legit.pl show <commit>:<filename>\n";
    exit 1;
  }
  # check any commit exists TODO ??????
  if (! -d ".legit/commit.0") {
    print STDERR "legit.pl: error: your repository doesn't have any commits yet\n";
    exit 1;
  }

  # split arguments => check valid file name
  $arg = $ARGV[1];
  $arg =~ /(.*):(.*)/;
  $commit = $1;
  $file = $2;

  # check valid file names
  if (!($file =~ /^[a-zA-Z0-9][a-zA-z0-9\.\-\_]*$/g)) {
    print STDERR "legit.pl: error: invalid filename '$file'\n";
    exit 1;
  }

  # check whether commit number is ommitted
  # If the commit is omitted the contents of the file in the index should be printed.
  if ($commit eq "") {
    ## TODO : neccessary????
    if (! -d ".legit/index") {
      print STDERR "legit.pl: error: unknown index directory\n";
      exit 1;
    }
    $path = ".legit/index/$file";
    if (! -e $path) {
      print STDERR "legit.pl: error: '$file' not found in index\n";
      exit 1;
    }
  }
  else {
    if (! -d ".legit/commit.$commit") {
      print STDERR "legit.pl: error: unknown commit '$commit'\n";
      exit 1;
    }
    $path = ".legit/commit.$commit/$file";
    if (! -e $path) {
      print STDERR "legit.pl: error: '$file' not found in commit $commit\n";
      exit 1;
    }
  }

  # print the contents of the specified file from $path
  open FILE, '<', "$path" or die;
  while ($line = <FILE>)
  {
    print $line; # "$line"?
  }
}

sub error_checking {

  if ($#ARGV == -1) { ####
    print <<eof;;
    Usage: legit.pl <command> [<args>]

These are the legit commands:
   init       Create an empty legit repository
   add        Add file contents to the index
   commit     Record changes to the repository
   log        Show commit log
   show       Show file at particular state
   rm         Remove files from the current directory and from the index
   status     Show the status of files in the current directory, index, and repository
   branch     list, create or delete a branch
   checkout   Switch branches or restore current directory files
   merge      Join two development histories together
eof
  }

}
