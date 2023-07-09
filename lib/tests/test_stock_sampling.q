.utl.require "crispy-winner"

`trade1sec  set update date:`date$time, sym:`g#sym from ([] sym:`testSym; time:2023.07.01D+til[`long$(2023.07.08D-2023.07.01D) div 0D00:05]*00:05; price:100f+sums ((`long$(2023.07.08D-2023.07.01D)div 0D00:05)?1.0)-0.5);
`trade1min  set update date:`date$time, sym:`g#sym from ([] sym:`testSym; time:2023.07.01D+til[`long$(2023.07.08D-2023.07.01D) div 0D00:05]*00:05; price:100f+sums ((`long$(2023.07.08D-2023.07.01D)div 0D00:05)?1.0)-0.5);
`tradeDaily set update time:`timestamp$date from select from trade1min where i=(rand;i) fby date;

.tst.desc["sampling generation function calculateSamplePoints"] {
   should["generate the correct sampling points between t1 and t2"] {
      t1:2023.07.07D;
      t2:2023.07.08D;
      num:1000;
      samples:calculateSamplePoints[t1;t2;num];
      type'[samples] musteq `sampleSize`samples!-16 98h;

      count[samples`samples] musteq 1000;
      t:samples[`samples;`time];
      first[t] musteq t1;
      last[t] musteq t2;

      / skip first,last result as we know this is t1,t2
      (-1 _ 1_deltas[first t;t]) musteq 0D00:01:26.486486486l
      };
   };

.tst.desc["sampling function getStockSamples"] {
   should["generate an output table of correct schema with same number of outputs as samples requested"] {
      res:getStockSamples[`testSym;2023.07.01D; 2023.07.08D; 100];
      count[res] musteq 100;
      };

   should["call util function to generate correctly spaced samples"]{
      `testArgs mock ();
      `now mock .z.p;
      `calculateSamplePoints mock {[t1;t2;num] `testArgs set (t1;t2;num); `sampleSize`samples!(t2-t1;([]time:num#t1))};

      getStockSamples[`testSym;now;now;100];
      testArgs mustmatch (now;now;100);
      };

   should["include sym in results returned"] {
      `now mock .z.p;
      res:getStockSamples[`testSym;now-1D;now;100];
      res[`sym] musteq `testSym;
      };

   should["call snap function with the correct granularity"] {
      `now mock .z.p;
      `snap mock {[tab;joincols;rack;opts] `snapArgs set (tab;joincols); update price:1f from rack};

      `snapArgs mock ();
      getStockSamples[`testSym;now-100D;now;10];
      snapArgs mustmatch (`tradeDaily;`sym`time);

      `snapArgs mock ();
      getStockSamples[`testSym;now-1D;now;1000];
      snapArgs mustmatch (`trade1min;`sym`time);

      `snapArgs mock ();
      getStockSamples[`testSym;now-1D;now;10000];
      snapArgs mustmatch (`trade1sec;`sym`time);
      }
   };
