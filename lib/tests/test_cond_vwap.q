.utl.require "task-202307"

.tst.desc["conditional vwap"] {
   before {
      .task2.init[];
      };

   should["take a client order and market trades tables as inputs and
      return a table which contains one record per client id , the
      sym,start and end columns, and an extra column, the conditional
      vwap described above."] {
      
      res:.task2.condVwap[clientorders;markettrades];
      type[res] musteq 98h;
      cols[res] musteq cols[clientorders] union `vwap;
      res[`vwap] musteq 100.33561496527777 101.84163936170214;
      };
   };


