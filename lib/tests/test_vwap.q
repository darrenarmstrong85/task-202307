.utl.require "task-202307"

.tst.desc["vwap function"]{
   before {
      `now mock .z.p;
      `today mock `date$now
      };

   should["return a table with expected schema"] {
      `trade mock ([]date:1#today; sym:`EURUSD; time:now; size:1; price:10);

      v:.task1.getVwap[`;.z.p;.z.p];
      type[v] musteq 98h;
      (0!meta[v])[`c`t] mustmatch (`sym`vwap;"sf");
      };

   should["Find vwaps with expected values"] {
      `trade mock ([]
         date:today;
         sym:`EURUSD`EURUSD`USDCHF`USDCHF`GBPUSD`GBPUSD`EURCHF`EURCHF`USDJPY`USDJPY;
         time:now;
         size: (  1;  9;  2;  2;  0; 100; 0N;  10; 0N; 0N);
         price:( 10; 20; 10; 20; 50;   1;  5; 100; 20; 20));

      `expected mock flip `sym`vwap! flip (
         (`EURUSD; 19f);
         (`USDCHF; 15f);
         (`GBPUSD;  1f);
         (`EURCHF;100f);
         (`USDJPY;  0n));

      `v mock .task1.getVwap[`EURUSD`USDCHF`GBPUSD`EURCHF`USDJPY;.z.p-1D;.z.p+1D];
      all[(`sym xkey v) = (`sym xkey expected)] musteq 1b;
      };

   should["Find vwaps in expected range"] {
      `trade mock ([]
         date:today;
         sym:`EURUSD;
         time:asc ((now-til 100), (now+1+til 100));
         size: ((100#2), 100#1);
         price:((100#-1),100#1)
	 );

      v:.task1.getVwap[`EURUSD;now;now+1D];
      exec vwap mustgt 0 from v;
      };
   };
