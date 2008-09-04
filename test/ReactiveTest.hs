module Main where

import Control.Concurrent.Reactive 
import Control.Concurrent
import System.IO

-- The inwards api is
--   say 
--   p <- start			-- start a message about progress towards a goal.
--   start_test p (args)	-- staring a test
--   progress p			-- 
--   done p			-- 

-- You can only test one at a time.

data ProgressReport = ProgressReport
	{ pr_text	:: String -> IO ()	-- say something
	, pr_progress	:: String -> IO ()	-- temp message, overwritten by next message, or text
	}


mkProgressReport :: Handle -> IO ProgressReport
mkProgressReport h =
	reactiveObjectIO handle state (\ _pid _req act ->  
	    ProgressReport 
		   { pr_text = \ str -> act $ \ st -> do unwind st
						 	 hPutStr h str
							 hFlush h
							 return ""
		   , pr_progress = \ str -> act $ \ st -> do unwind st
							     hPutStr h str
							     hFlush h
							     return str
	 	   })
 where
	unwind str = hPutStr h $ ['\b' | _ <- str ] ++ [' ' | _ <- str ] ++ ['\b' | _ <- str ]
	state = ""
	handle () s = return s

main = do
	report <- mkProgressReport stdout
	pr_text report  "Hello: "
	sequence [ do pr_progress report (show n)
		      threadDelay $ 1000 * 1000
		 | n <- [1..10]
		 ]
	pr_text report  "[Done]\n"
	return ()
