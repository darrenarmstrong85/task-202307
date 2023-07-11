\d .utils

datesFromRange:{[sd;ed]
  sd+til[1+ed-sd]
  }

/ load data location, use Q debugger features to find out where this script is running from and therefore how to find files
getLocationOf:{[f;dummy] ` sv first[` vs hsym `${c:count x; x@c-3}value .z.s],f }

getTradesFileLocation:      getLocationOf[`trades.csv;]
getClientOrdersFileLocation:getLocationOf[`clientorders.csv;]

genTradesCsv:{
  trades:raze {[s;d] ungroup ([sym:s] date:d; time:d+(5;0N)#5000?1D-1; volume:(5;0N)#5000?100; rwalk:(5;0N)# (5000?1.0)-0.5)
     }[`EURUSD`USDCHF`GBPUSD`EURCHF`USDJPY;] each .utils.datesFromRange[2023.07.01;2023.07.05];

  trades:`date`sym`time xasc trades;
  trades:``rwalk _ update price:100+(sums;rwalk) fby sym from trades;

  :`date`sym`time xcols trades;
  }

seedTradesCsv:{
  system "S -314159"; / reset seed and so RNG to make this repeatable
  h:hopen {@[hdel;x;x]} p:getTradesFileLocation[];
  neg[h] csv 0: genCsv[];
  }

\d .
