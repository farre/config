{-# Language FlexibleContexts, TypeOperators #-}
import Yi
import Yi.MiniBuffer
import Yi.Keymap.Emacs (defKeymap, eKeymap, mkKeymap)
import Yi.Keymap.Emacs.Utils (readUniversalArg)
import Control.Monad
import Data.Maybe
import Prelude hiding ((.))

config =
  defaultEmacsConfig { defaultKm = myKeymap
                     , modeTable = fmap (onMode $ prefIndent) (modeTable defaultConfig)
                     }

-- Set soft tabs of 4 spaces in width.
prefIndent :: Mode s -> Mode s
prefIndent m =
  m { modeIndentSettings = IndentSettings
      { expandTabs = True
      , shiftWidth = 2
      , tabSize = 4
      }
    }

main = yi config

myKeymap :: KeymapSet
myKeymap = mkKeymap $ override Yi.Keymap.Emacs.defKeymap $ \proto _self ->
   proto {
           eKeymap = eKeymap proto ||>
           -- Add a M-g binding for goto-line
           (metaCh 'g' ?>>! (gotoLn . fromDoc :: Int ::: LineNumber -> BufferM Int)) ||>
           ((ctrl $ spec KDel) ?>>! (deleteB unitWord Forward)) ||>
           ((metaCh ' ') ?>>! placeMark)
         }

placeMark :: BufferM ()
placeMark = do
  putA highlightSelectionA True
  pointB >>= setSelectionMarkPointB