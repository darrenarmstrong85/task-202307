# Code location

Individual task directories can be found in the lib directory at the
root of this repository.

# Task 1 Outputs

1. An input file with data you have created in csv format

I've added a utilities library that will generate random data by calling `.utils.seedTradesCsv[]`.  A copy of the data generated can be found at lib/utils/trades.csv.

2. A function which, given a time range and a list of symbols as inputs, returns the VWAP (TWAP) for each of these symbols as a table

The is the function `.task1.getVwap` which can be found in lib/task1/init.q

3. A command to start a q process which will load this function

Based on the below setup instructions, this can be done using:

```
darren@DESKTOP-LMH5KQC:~/git/task-202307$ type qq
qq is a function
qq ()
{
    loc=$(readlink -f $(which q));
    local QHOME=${loc%/l64/q};
    QHOME=$QHOME rlwrap -c -s 99999 $loc $@ -c $LINES $COLUMNS
}
darren@DESKTOP-LMH5KQC:~/git/task-202307$ qq loadlibs.q
KDB+ 4.0 2023.01.20 Copyright (C) 1993-2023 Kx Systems
l64/ 8(24)core 3813MB darren desktop-lmh5kqc 127.0.1.1 EXPIRE 2024.07.07 darren.armstrong85@gmail.com KOD #5015115

q).task1.getVwap
{[s;st;et]
   0!select vwap:size wavg price by sym from trade
      where sym in s, date within (`date$(st;et)), time within (st;et)
   }
```

4. Example of how to call the function

Using the initialization above:

```
q).task1.init[]
q)meta .task1.getVwap[`EURUSD;.z.p;.z.p]
c   | t f a
----| -----
sym | s
vwap| f
```

5. Test(s) to ensure validity of code

These can be found at lib/tests/test_vwap.q

# Task 2

Please find test code in lib/tests/test_cond_vwap.q, and implementation at lib/task2/init.q

- The function should be tested using your testing framework of your choice and an example should be given on how to run the tests.

As per instructions on Task 1 and using setup instuctions below, we can see the description of the output in the case where `--desc` is supplied and a successful test run without this, confirming that the test has been run successfully.

```
darren@DESKTOP-LMH5KQC:~/git/task-202307$ qspec lib/tests --desc
KDB+ 4.0 2023.01.20 Copyright (C) 1993-2023 Kx Systems
l64/ 8(24)core 3813MB darren desktop-lmh5kqc 127.0.1.1 EXPIRE 2024.07.07 darren.armstrong85@gmail.com KOD #5015115

conditional vwap::
- should take a client order and market trades tables as inputs and
      return a table which contains one record per client id , the
      sym,start and end columns, and an extra column, the conditional
      vwap described above.
sampling generation function calculateSamplePoints::
- should generate the correct sampling points between t1 and t2
sampling function getStockSamples::
- should generate an output table of correct schema with same number of outputs as samples requested
- should call util function to generate correctly spaced samples
- should include sym in results returned
- should call snap function with the correct granularity
vwap function::
- should return a table with expected schema
- should Find vwaps with expected values
- should Find vwaps in expected range
darren@DESKTOP-LMH5KQC:~/git/task-202307$ qspec lib/tests
KDB+ 4.0 2023.01.20 Copyright (C) 1993-2023 Kx Systems
l64/ 8(24)core 3813MB darren desktop-lmh5kqc 127.0.1.1 EXPIRE 2024.07.07 darren.armstrong85@gmail.com KOD #5015115

.........

For 4 specifications, 9 expectations were run.
9 passed, 0 failed.  0 errors.
```

- A sample/example run of the function with some input/output should be documented (it can be the tests above).

See above

# Setup instructions

I have been running all samples via a combination of Docker / Circle
CI automation and my local setup, which I will describe below.

## CircleCI - qspec integration

This is based on pushes to the repository at
https://github.com/darrenarmstrong85/task-202307 which are now
configured to automatically run all qspec tests found in this project
at lib/tests.  This has helped me to ensure that the solutions
provided are not dependent on anything I have not committed, or any
specific state on my machine.  Therefore it should be relatively
simple to get these code samples running.

The pipeline configuration for this can be found at
.circleci/config.yml.  This uses the docker image
darrenarmstrong85/ubuntu-kdb-qspec, which is a docker image I
previously built for another project,
https://github.com/darrenarmstrong85/scientist.  I have replicated its
dependencies in this repository at ci/Docker in the root of this
project.

## qutil / qspec setup

qspec was chosen as it is a project I am familiar with from various
previous work.  It defines a small DSL within kdb based on function
blocks (desc, should, holds), mocking utilities (before, after, mock),
and assertion tests (musteq, mustlike, etc).

Once setup, it provides a rapid environment to run tests in, requiring
very little outside of core kdb other than supporting libaries and
setup.  On my laptop (2022 hp pavilion x360 14-dy0xxx, core i5-1135G7,
8GB RAM) running WSL:

```
darren@DESKTOP-LMH5KQC:~/git/task-202307$ time qspec lib/tests
KDB+ 4.0 2023.01.20 Copyright (C) 1993-2023 Kx Systems
l64/ 8(24)core 3813MB darren desktop-lmh5kqc 127.0.1.1 EXPIRE 2024.07.07 darren.armstrong85@gmail.com KOD #5015115

.....

For 2 specifications, 5 expectations were run.
5 passed, 0 failed.  0 errors.

real    0m0.159s
user    0m0.042s
sys     0m0.023s
```

qspec is a bash function, provided as part of files in env in the root
of this repository.  It depends on a bash function qq, which depends
on finding q on $PATH.

## Bash / q / qspec setup

There is admittedly a little bit of set up to do here, as qspec and
various bash functions de depends upon a few things:

 - $QPATH should be set (this is set to a folder qlibs in my local
   environment)

 - qutil, qutil code: cloned from github into a directory git (in my
   case this is at ~/git).

 - qutil bootstrap code location: this is done in code in $QINIT

```
$ cat $QINIT
.utl.QPATH:hsym `$getenv[`QPATH]
system "l ",getenv[`QPATH],"/qutil/bootstrap.q"
```

 - qlibs directory setup: qutil assume a certain layout of files and
   the simplest way I've found to do this is to use the setup
   described in the tree command output below in this file.

This all allows me to start a new session with qq (another bash
function included in .bash_functions in this repository), and load the
task-202307 library as shown below:

```
darren@DESKTOP-LMH5KQC:~/git/task-202307$ qq
KDB+ 4.0 2023.01.20 Copyright (C) 1993-2023 Kx Systems
l64/ 8(24)core 3813MB darren desktop-lmh5kqc 127.0.1.1 EXPIRE 2024.07.07 darren.armstrong85@gmail.com KOD #5015115

q).utl.require "task-202307"
q)\f
`calculateSamplePoints`getStockSamples`snap
```

Bash functions and scripts can be found in the env directory at the root of this repository.

## Overall Layout

Here is the location of relevant files for startup of this project
from my local machine, other than the ones strictly needed for q.

```
darren@DESKTOP-LMH5KQC:~$ tree qlibs git/{qspec,qutil,task-202307}
qlibs
├── qspec -> src/qspec/lib
├── qutil -> src/qutil/lib
├── src
│   ├── qspec -> /home/darren/git/qspec
│   ├── qutil -> /home/darren/git/qutil
│   └── task-202307 -> /home/darren/git/task-202307
└── task-202307 -> src/task-202307/lib
git/qspec
├── CHANGES
├── LICENSE
├── README
├── app
│   └── spec.q
├── lib
│   ├── fixture.q
│   ├── init.q
│   ├── loader.q
│   ├── mock.q
│   ├── output
│   │   ├── junit.q
│   │   ├── text.q
│   │   ├── xml.q
│   │   └── xunit.q
│   └── tests
│       ├── assertions.q
│       ├── expec.q
│       ├── fuzz.q
│       ├── internals.q
│       ├── spec.q
│       └── ui.q
└── test
    ├── fixture_tests
    │   ├── fixtures
    │   │   ├── a_fixture
    │   │   │   └── 2009.01.01
    │   │   │       └── sometable
    │   │   │           └── a
    │   │   ├── all_types.csv
    │   │   ├── emptyDir
    │   │   ├── fixtureCarets.csv
    │   │   ├── fixtureCommas.csv
    │   │   ├── fixturePipes.psv
    │   │   ├── myFixture
    │   │   ├── no_part_fixture
    │   │   │   └── aTable
    │   │   │       ├── a
    │   │   │       └── b
    │   │   ├── not_a_fixture
    │   │   │   └── 2009.01.01
    │   │   │       └── mytable
    │   │   │           └── a
    │   │   ├── other_fixture
    │   │   │   └── 2009.01.01
    │   │   │       └── othertable
    │   │   │           └── a
    │   │   └── splayFixture
    │   │       ├── a
    │   │       └── b
    │   ├── test_directory_fixture.q
    │   ├── test_file_fixture.q
    │   └── test_text_fixture.q
    ├── nestedFiles
    │   ├── bar
    │   │   └── g.q
    │   ├── baz
    │   │   └── f.q
    │   └── foo
    │       ├── one
    │       │   ├── a.q
    │       │   ├── b.q
    │       │   └── one
    │       │       ├── c.q
    │       │       └── d.q
    │       └── two
    │           ├── d.q
    │           └── e.k
    ├── test_assertions.q
    ├── test_expec_runner.q
    ├── test_fileloading.q
    ├── test_fuzz.q
    ├── test_mock.q
    ├── test_spec_runner.q
    └── test_ui.q
git/qutil
├── CHANGES
├── LICENSE
├── README
├── lib
│   ├── bootstrap.q
│   ├── config_parse.q
│   ├── init.q
│   └── opts.q
├── q_q.sample
├── test
│   ├── configs
│   │   ├── colonSeparators
│   │   ├── default
│   │   ├── emptyKey
│   │   ├── emptySection
│   │   ├── equalsSeparators
│   │   ├── leadingWhitespace
│   │   ├── longHeader
│   │   ├── multiValue
│   │   ├── multipleSections
│   │   ├── nameSubstitution
│   │   ├── noSections
│   │   ├── normal
│   │   ├── semicolonComment
│   │   ├── sharpComment
│   │   ├── tabsInKeys
│   │   └── whitespace
│   ├── test_config_parser.q
│   └── test_option_parser.q
└── test_require
    ├── testLoaderFiles
    │   ├── alphaprefixedpackage
    │   │   └── init.q
    │   ├── alphaprefixedv-pkg-4.0
    │   │   └── init.q
    │   ├── nested
    │   │   ├── init.q
    │   │   └── nested1
    │   │       ├── init.q
    │   │       └── nested2
    │   │           ├── foo.q
    │   │           └── init.q
    │   ├── package
    │   │   ├── init.q
    │   │   └── verify_pkg_load.q
    │   ├── recursive
    │   │   └── init.q
    │   ├── structured
    │   │   └── lib
    │   │       └── init.q
    │   ├── structured_nested
    │   │   └── lib
    │   │       ├── init.q
    │   │       └── nested1
    │   │           ├── init.q
    │   │           └── nested2
    │   │               ├── foo.q
    │   │               └── init.q
    │   ├── v-pkg
    │   │   └── init.q
    │   ├── v-pkg-0.1.2
    │   │   └── init.q
    │   ├── v-pkg-1.2.1
    │   │   └── init.q
    │   ├── verify_load_file_path.q
    │   ├── verify_no_dup_require.q
    │   └── verify_pkgloading.q
    └── test_require.q
git/task-202307
├── LICENSE
├── ci
│   └── Docker
│       ├── ubuntu-kdb
│       │   ├── Dockerfile
│       │   └── qq.sh
│       ├── ubuntu-kdb-deps
│       │   └── Dockerfile
│       ├── ubuntu-kdb-qspec
│       │   ├── Dockerfile
│       │   └── qspec.sh
│       └── ubuntu-kdb-qutil
│           ├── Dockerfile
│           └── qutil.sh
├── env
│   ├── q
│   │   └── common
│   │       └── q.q
│   └── qlibs
│       ├── qspec -> src/qspec/lib
│       ├── qutil -> src/qutil/lib
│       ├── src
│       │   ├── qspec -> ../../../../qspec
│       │   ├── qutil -> ../../../../qutil
│       │   └── task-202307 -> ../../..
│       └── task-202307 -> src/task-202307/lib
├── lib
│   ├── init.q
│   ├── task1
│   │   ├── #trades.csv#
│   │   ├── init.q
│   ├── task2
│   │   └── init.q
│   ├── task3
│   │   ├── init.q
│   │   ├── readme.md
│   └── tests
│       ├── test_stock_sampling.q
└── readme.md

77 directories, 119 files
```
