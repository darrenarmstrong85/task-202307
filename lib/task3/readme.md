# Task 1
## Problem statement

You have been tasked with implementing a kdb+ based solution for a new
UI feature which provides charting of different stock prices over
time, based on some high frequency historical data. The universe of
stocks is 5,000, with millions of records per day for each stock. The
data goes back 3 years.  The requirements are:

 - The charting front end will pass in a symbol (the stock sym), a
   start and end timestamp and a granularity, ie how many price points
   to return to the chart.

 - The return object to the charting front end should be a table with
   sym,time,price columns - its count being equal to the value of the
   granularity.

 - Note that performance here takes priority over precision since this
   is just a charting function to indicate the price performance over
   relatively long periods of time. eg week/month(s). Granularity can
   be anything from 50 points to 1,000.

 - The charting service will have hundreds of users, so concurrent
   charting requests may happen.

Provide a high-level description of the database design you would
propose for this solution, along with technical details around the
database's features.

How you store and represent the data and/or at what granularity (if
this is applicable) is completely your choice. Please include in your
description what led you to propose each of your design choices.

Include a high level description of any other code, processes or
functionality that would have to be built in conjunction with creating
this db design to serve the above requirement.

## Solution discussion

### Assumptions

- Compression assumes 5:1 ratio is achievable (untested but a
  reasonable assumption from experience).

- 1 million rows per symbol per day for raw data calculations.

- Raw data arrival at an even rate across the day, including at
  weekends.


### Initial approach

Starting from the ground up, this is fundamentally a sampling problem,
which leans towards some form of asof join, using aj operations at its
core.

My initial design for how to find these points is given in
[init.q](init.q), starting in function `getStockSamples`.  We first
use a utility function `calculateSamplePoints` to divide the range
into evenly-spaced samples, and provide both this sample size and the
underlying points as a return value.

### Optimization and storage considerations

Although aj is a fast way to join data, it can be made faster by
looking at the problem we are trying to solve.  We do not need to look
at every tick if we are sampling across multiple days or ranges, and
in fact we may wish to apply some kind of cleaning or summarization of
the data in order that we do not pick up on spurious noise or signals
when presenting this to users.  I believe that 1-minute binned data
would be sufficient for our purpose.  For any given date, for 5-minute
bins we would have 12 x 24 = 288 samples, and as asof-join uses binary
search after finding the data quickly with \`p or \`g attributes, this
would require log2(288) ~= 8 searches on for each sample.  1 minute
binned data would use log2(60 x 24) ~= 10 searches for each point.
This compares with log2(1,000,000) ~= 20 searches for each sample, so
we would expect 1-minute and 5-minute binned data to be at least 2x
quicker.

The reality may be even more favourable for binned data due to
filesystem caching.  Each day will contain approximately the amounts
of data shown below.  Note that we assume an average size per row of
timestamp(8) + sym(8) + price (4) = 20 bytes/row for partitioned data,
and 24 bytes (date column included) for flat files (date column is not
strictly necessary but is a useful convenience for small files).
Compression assumes 5:1 ratio is achievable (untested but a reasonable
assumption for our purposes).  I have assumed 1 million rows per
symbol per day for raw data.  Finally, I assume data is arriving at an
even rate across the day, including at weekends.

```
q)toSI:{.Q.fmt[6;2;last s],(" ",/:" kMGTP",\:"B")@-1+count s:(1023<){x%1024.}\x}
q)tcols:(`$("table type";"points per day per sym"; "size per day per sym"; "size per day";"size 30 days";"size 3 years";"size flat file";"size per day compressed";"size 3 years compressed"))
q)raw:([]ttype:`$("raw data";"1-second bin";"1-minute bin";"5-minute bin";"1-hourly bin";"daily data"); ppdsym:(1000000;86400;60*24;12*24;24;1))
q)tcols xcol 0!(toSI'')2!{update sizepdc:sizepd%5, size3yc:size3y%5 from x}update sizepd:ppdsym*5000*20, size30:ppdsym*5000*30*20, size3y:ppdsym*5000*3*365*20, sizeflat:ppdsym*5000*3*365*24 from raw
```

| table type    | points per day per sym  | size per day per sym | size per day | size 30 days | size 3 years | size flat file | size per day compressed | size 3 years compressed
| ------------- | ----------------------: | -------------------: | -----------: | -----------: | -----------: | -------------: | ----------------------: | ----------------------:
|     raw data  |                 1000000 |             19.07 MB |     93.13 GB |      2.73 TB |     99.59 TB |      119.51 TB |                18.63 GB |                19.92 TB
| 1-second bin  |                   86400 |              1.65 MB |      8.05 GB |    241.40 GB |      8.60 TB |       10.33 TB |                 1.61 GB |                 1.72 TB
| 1-minute bin  |                    1440 |             28.13 kB |    137.33 MB |      4.02 GB |    146.85 GB |      176.22 GB |                27.47 MB |                29.37 GB
| 5-minute bin  |                     288 |              5.63 kB |     27.47 MB |    823.97 MB |     29.37 GB |       35.24 GB |                 5.49 MB |                 5.87 GB
| 1-hourly bin  |                      24 |            480.00  B |      2.29 MB |     68.66 MB |      2.45 GB |        2.94 GB |               468.75 kB |               501.25 MB
|   daily data  |                       1 |             20.00  B |     97.66 kB |      2.86 MB |    104.43 MB |      125.31 MB |                19.53 kB |                20.89 MB

( * As I later recommend this data is stored in a flat-file format,
note that this data will be uncompressed on load and require the full
uncompressed size.  This is not a concern as we shall see. )

User queries tend to be quite strongly correlated by sym and time, so
we should aim for a solution with reasonable cache hit ratios.  A
modern server may have 6TB RAM, but it would not be feasible to keep a
significant part of the raw dataset in cache.  Even with a good
compression ratio this would not be possible.  Compression would also
have the effect of reducing the performance of queries on cached data,
as kdb decompresses data blocks on demand.  From experience this
typically causes 'warm-query' performance to be approximately half of
the uncompressed case.

By comparison, it would be trivial to keep all of the 1-minute data in
memory on a single server.  We could then use multiple processes using
either socket sharding or an mserve-like process to be able to service
multiple users in parallel.  Our throughput may increase by 1 or 2
orders of magnitude due to filesystem caching, and by a further order
of magnitude given 10-20 mirrors.  So binned data may be 100-1,000x
faster than sampling raw tick data for the volumes we expect.

I did consider whether monthly-partitioned data would be useful, as
for 5-minute data the overhead of filesystem operations may be
dominant, and reduce the benefit of having fewer points to sample.
Size of data for this is approximated by the 30-day figures in the
table above.  This does have its own costs however.  Looking purely at
binary search complexity, the time to search a month-partitioned set
of summary figures would increase by 1.47x for 1-minute binned data,
and 1.60x for 5 minute bins.  It is unlikely to be worth the
operational complexity, especially given the ability to keep the
entire dataset in memory, where in-memory VFS operations in RAM will
be at least an order of magnitude faster than even the fastest
NVMe-based retrieval.

We may still want to use different summary representations for
different granularities, as this will ensure we obtain the best
performance over a range of user queries, and provides appropriate
precision where needed.  Inside the call to `getStockSamples`, once we
have a sample increment and table of sample points, we use a binary
search to find the table of interest.

There is an approx 10:1 reduction in storage cost if 1-second bins are
appropriate.  Given the description of expected use, it seems that raw
tick data would almost never be needed for the granularity required.

Finally, given how small the data storage requirements are for daily
samples ( <100MB **total** ), I think it would be worth storing daily
data as a flat file within the database, with the `g# attribute set
either on-disk or upon loading.

So for the purpose of this exercise, I have decided that to use the
sample increment as follows:

- If the sample increments are smaller than 1 minute, use 1-second
  binned data.

- If the sample increment is above 1 minute, we use the trade1min
  table.

- If the sample increment is greater than 1 day, use daily stats

It is not obvious that hourly binned data is worth the cost and
complexity versus 1-minute data.  Storing the data as a flat file
would mean searching the entire space for a given sym on every call,
which is likely to be hit diminishing returns, and cannot be done in
parallel outside of kdb's internal multi-threading.  It is likely to
be faster to either use 1-minute binned data (which has fewer points
per sample to explore) at smaller sample intervals, or to use daily
data for a cost in accuracy at wider increments.

It would be possilbe to store hourly data by month.  This would need
to be stored in a separate HDB, and require a more complex gateway/HDB
architecture, and the resulting IPC and complexity is likely to slow
down queries.

It could instead be done implicitly by joining as below in the inner
snap loop.  This maps dates to the first partition of the month, and
ignores all other date partitions which can be left empty..

```
   $[tab=`tradeDaily;
        aj[joincols;rack;tab];
	
     tab=`trade1hour;
        raze {[jc;r;t;m] aj[jc;select from r where (`month$date)=m;
                               select from t where date=`date$d]
                }[joincols;rack;tab;] peach distinct `month$rack`date;
	     
     raze {[jc;r;t;d] aj[jc;select from r where date=d;
                            select from t where date=d]
             }[joincols;rack;tab;] peach distinct rack`date
     ]
     
```

This might strike a better balance between parallelism and efficiency
of individual joins, but adds significant complexity in both the API
provided and the operational complexity of ensuring we store data in
the correct partition and re-sort as needed in the case of a rolling
3-year HDB window.  I would revisit this based on business demands if
the performance required cannot be obtained using 1-minute binned
data.

Given the increased cost to store 1-second binned data, it may be
decided that there is no need for this.  To store all data for three
years across all granularities would use <10TB of data, which by
modern standards is a very small dataset.

Note that within the `snap` function we check to see if we are joining
daily data, and if so we perform the whole join in a single aj
operation, rather than parallelising on date.  Given this will never
be considering more than 3 * 365 ~= 1,100 data points, this will
likely perform the entire join about as quickly as joining a single
date against 1-minute summary data.

### Do we need to keep the raw data?

The raw dataset is obviously a lot of data to store at approx. 100TB
raw for three years.  As mentioned above, it seems very unlikely that
we would make good use of this outlay, and so, unless the cost of this
can be amortized over other requirements it would not seem to be worth
the cost to keep.

### Proposed storage on disk

As per the above conclusions, I would store the 1-second, 1-minute and
daily representations of the data in a HDB format, with \`p attribute
on sym for daily partitioned datasets and \`g attribute on daily file.
Within each partition, the data should be sorted ``` `sym`time xasc ```.
This would give an approximate structure as follows:

```
   summaryguidata/
      2020.01.01/
         trade1sec/
	    price
	    sym
	    .d
	 trade1min/
	    price
	    sym
	    .d
      2020.01.02/
         trade1sec/
	    price
	    sym
	    .d
	 trade1min/
	    price
	    sym
	    .d
      ...
      2022.12.31/
         trade1sec/
	    price
	    sym
	    .d
	 trade1min/
	    price
	    sym
	    .d
      init.q
      sym
      tradeDaily
```

As mentioned above, as we expect the trade1min data to be mainly used
from cache, and as the dataset is not large enough to warrant it, I
would not use compression here.

Counter to this, I would consider compression on trade1sec.  The
dataset is potentially large enough uncompressed that we would not be
able to store a significant fraction of it, in which case we would
spend a lot of time re-loading this from disk.  If we store the data
compressed, it may mean that our warm-query performance suffers.
However, we do not expect from the description that this data will be
heavily used (we expect far greater use of the trade1min and
tradeDaily datasets), and so in the case where data is not often found
in cache and we can use compression to load less data from disk in
preference to CPU, compression offers a net benefit to cold query
performance and a storage cost benefit in using 1/5th the storage on
disk.

Thereefore, outside of relatively fixed cost of sym and init.q
storage, this is expected to use approximately (1.72 TB + 176.22 GB +
125.31 MB) ~= 1.89 TB, which is easy to store on a single
high-performance storage device.

### Solution Setup

It is not clear from the details of the task that there is any
realtime component to this, and so I have proceeded on that basis.  It
would be possible to extend the existing design to account for this if
needed.

The simplest way to run this would be as an HDB loading the above DB,
using socket sharding / SO_REUSEPORT

```
   q summaryguidata -p rp,5012 -s 10
```

We may wish to extend init.q so that on startup an HDB process
connects to some kind of monitoring or control process and registers a
given PID and ID so that specific processes can be restarted if they
become unresponsive.

This control process may also be responsible for starting the
processes as a background task, and ensuring we have sufficient
processes running to service this load.

As this will be mainly performing asof-joins in-memory using
trade1min, I would expect to limit the number of processes by how many
CPUs are available on the server.  In the above example, 10 secondary
threads are used, so if we have 100 CPUs available.  Some amount of
tuning would be needed to find the optimimum combination of secondary
threads and processes.

### Design strengths and weaknesses

The design proposed above gives a highly performant solution across a
range of user scenarios, allowing a business unit to make tradeoffs
between cost, performance, and accuracy based on varying sizes of
binned data, all the way through to joining against raw tick data.

The use of socket sharding and a control process allows for
performance to scale as is required to support multiple users.  As
specified the solution does not provide any way to optimize for number
of secondary threads vs number of processes; this needs to be
considered for tweaking.

Timeouts and "bad queries" are not currently considered.  These should
be rare enough given the API that it is very hard to write a query
that cannot be serviced quickly, due to the manner in which we
automatically scale the granularity of the data.  A heartbeat
mechanism in the control process may help us to ensure that services
are healthy and/or alert when they are not.

One additional benefit of storing this data in summary format is that
it is largely agnostic to data volumes. Within the areas I have worked
before we have assumed that data peaks are 2x average and data volumes
grow to 1.5x every three years.  The exact values will vary by source,
but we would expect very predictable requirements from this solution
over time.

To improve accuracy further, it would be possible to weight the number
of sample points by some measure e.g. volatility.  In such a design,
`calculateSamplePoints` would return a list of different granularities
for different time periods, and we could join each period in turn
using a different summary dataset.  This would need to have some very
rapid way of finding the volatility in order that the main business of
sampling the data is not severely impacted.
