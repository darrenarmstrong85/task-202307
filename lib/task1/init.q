calculateSamplePoints:{[t1;t2;num]
   size:(t2-t1) div num-1;
   samples:(t1+til[num-1]*size),t2;

   :`sampleSize`samples!(size;([]date:`date$samples; time:samples));
   }

/
 in reality this may be a much more complex API, e.g. if we need to
 join across datasets or RDB/HDB pairs
\

snap:{[tab;joincols;rack;opts]
   $[tab=`tradeDaily;
        aj[joincols;rack;tab];
     raze {[jc;r;t;d] aj[jc;select from r where date=d;select from t where date=d]}[joincols;rack;tab;] peach distinct rack`date]
   }

getStockSamples:{[s;st;et;num]
   points:calculateSamplePoints[st;et;num];

   lookupMap:`trade1sec`trade1min`tradeDaily!0D 0D00:01 1D;
   tab:lookupMap bin points`sampleSize;

   rack:`sym xcols update sym:s from points`samples;

   snap[tab;`sym`time;rack;1#.q]
   }

