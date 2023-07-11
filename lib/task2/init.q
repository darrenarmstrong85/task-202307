/
 The purpose of this mini project is for you to write a function to
 calculate the conditional market VWAP (volume-weighted average price)
 corresponding to a set of client orders.

 The implicit/required underlying data consist of 2 tables

 1. a clientorders table with the following columns:
    `id`version`sym`time`side`limit`start`end. Each record in this
    table corresponds to a client order.  sym is the financial
    instrument corresponding to that order and start/end are time
    stamps denoting the order lifetime (.e.g order with id=1 starts at
    2021.01.01D09:00 and ends at 2021.01.01.D10:30). side denotes
    whether the order is requesting to buy or sell the instrument and
    limit is the limit price (ie buy at most at this price, or sell at
    least at this price). Each order has a unique id and the limit
    price of an order may change over time, in which case its version
    will increment. If the limit does change for an id, you can assume
    that the start/end times are unaffected, ie as per the initial
    order's version start and end time.

2.  a markettrades table with the following columns:
    `sym`time`price`volume. sym is again the financial instrument,
    whereas price and volume denotes the market traded price and size
    at the time.  Example of clientorders (you should aim to build a
    more comprehensive input):

(For both tables, think about how the prices per symbol change over
time to make a more realistic input)

Conditional market VWAP for a given order, is defined as the market
vwap during the lifetime of a client order, which is conditional (ie
within the limit) to that order's limit price at the time (eg. if the
limit price for a buy order is 10.0, then any market prints >10.0
would not be included, and the opposite for a sell order).  In other
words, over the course of the order's life-cycle, include market
trades which could have filled the order.

Acceptance Criteria:

- Your function will take a client order and market trades tables as
  inputs and return a table which contains one record per client id ,
  the sym,start and end columns, and an extra column, the conditional
  vwap described above.

- The function should be tested using your testing framework of your
  choice and an example should be given on how to run the tests.

- A sample/example run of the function with some input/output should
  be documented (it can be the tests above).

- Treat the structure of the data and code as if it is production
  quality code that needs to run in a stable and supportable manner.

- The q files and all required code/tests should be sent over as a
  compressed file with instructions on how to run.
\

.task2.init:{[]
   `markettrades set ("DSPJF";enlist csv) 0: .utils.getTradesFileLocation[];
   };
