.utl.require "crispy-winner"

.tst.desc["sampling generation function calculateSamplePoints"] {
   should["generate the correct sampling points between t1 and t2"] {
      t1:2023.07.07D;
      t2:2023.07.08D;
      num:1000;
      samples:calculateSamplePoints[t1;t2;num];

      count[samples] musteq 1000;
      first[samples`time] musteq t1;
      last[samples`time] musteq t2;

      / skip first,last result as we know this is t1,t2
      (-1 _ 1_deltas[first samples`time;samples`time]) musteq 0D00:01:26.486486486l
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
      `calculateSamplePoints mock {[t1;t2;num] `testArgs set (t1;t2;num); ([]time:num#t1)};

      getStockSamples[`testSym;now;now;100];
      testArgs mustmatch (now;now;100);
      };

   should["include sym in results returned"] {
      `now mock .z.p;
      res:getStockSamples[`testSym;now;now;100];
      res[`sym] musteq `testSym;
      };
   };
