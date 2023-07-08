/
 You have been tasked with implementing a kdb+ based solution for a
 new UI feature which provides charting of different stock prices over
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
\

calculateSamplePoints:{[t1;t2;num]
   size:(t2-t1) div num-1;
   samples:(t1+til[num-1]*size),t2;

   :`sampleSize`samples!(size;([]time:samples));
   }

getStockSamples:{[s;st;et;num]
   points:calculateSamplePoints[st;et;num];

   lookupMap:`trade`trade1min`trade5min!0D 0D00:01 0D00:05;
   tab:lookupMap bin points`sampleSize;

   :`sym xcols update sym:s from points`samples;
   }
