#!/usr/bin/perl -w

use File::Compare;
use File::Copy;

format_info();
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
	LOG();
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
		if (! (open IN, '<', $file)) {
			print "legit.pl: error: can not open 'non_existent_file'\n";
			exit 1;
		}
		if (!($file =~ /^[a-zA-Z0-9][a-zA-z0-9\.\-\_]*$/g)) {
		  print STDERR "legit.pl: error: invalid filename '$file'\n";
		  exit 1;
		}
		if (! -e $file) {
		  print STDERR "legit.pl: error: can not open '$file'\n";
		  exit 1;
		}
		open OUT, '>', ".legit/index/$file" or die;
		while($line = <IN>) {
		  print OUT $line;
		}
		close IN;
		close OUT;
  }

}

sub commit {

	if ($#ARGV <= 1) {
		print STDERR "usage: legit.pl commit [-a] -m commit-message\n";
		exit 1;
	}

    $next_commit = 0;
    $commit_dir = ".legit/commit.$next_commit";
    while (-d $commit_dir) {
        $next_commit++;
        $commit_dir = ".legit/commit.$next_commit";
	}

    # no change to previous commit
	$no_change = 1;
    # no deletion is found in index directory
	$no_delete = 1;

    # compare to previous commit to see any change is made in index folder
	if ($next_commit != 0) {
      	$no_change = 0;
      	$no_file = 0;
      	$prev_commit = $next_commit-1;

      	@files = glob(".legit/index/*");
      	foreach $file_path (@files) {
          	$file_path =~ /^\.legit\/index\/(.+)$/g;
          	if (compare("$file_path", ".legit/commit.$prev_commit/$1")) {
              	$no_change = 1;
          	}
      	}

      	if ($no_change == 0) {
          	@files = glob(".legit/commit.$prev_commit/*");
          	foreach $file_path (@files) {
              	if (! -e ".legit/index/$1") {
					$no_delete = 1;
					last
				}
			}
		}
	}

	if ($no_change == 0 || $no_file == 0) {
		print STDERR "nothing to commit\n";
		exit 1;
 	}
	elsif ($no_change == 1) {
		mkdir ".legit/commit.$next_commit" or die;
		@files = glob(".legit/index/*");

		foreach $file_path (@files) {
			copy("$file_path",".legit/commit.$next_commit/$1");
			$no_change=0;
		}
		open Log, ">>", ".legit/log.txt" or die;
		print Log "$next_commit $ARGV[2]\n";
		close Log;
		print "Committed as commit $next_commit\n";
	}

}

sub LOG {

	open FILE, '<', ".legit/log.txt" or die;
	@lines = reverse <FILE>;
	foreach $line(@lines) {
		print $line;
	}
	close FILE;

}

sub show {

  # check number of arguments
  if ($#ARGV != 1) {
    print STDERR "usage: legit.pl show <commit>:<filename>\n";
    exit 1;
  }
  # check any commit exists
  if (! -d ".legit/commit.0") {
    print STDERR "legit.pl: error: your repository doesn't have any commits yet\n";
    exit 1;
  }

  # split arguments
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
  # If so, the contents of the file in the index should be printed.
  if ($commit eq "") {
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

  open FILE, '<', "$path" or die;
  while ($line = <FILE>) {
    print $line;
  }

}

sub format_info {

  if ($#ARGV == -1) {
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
