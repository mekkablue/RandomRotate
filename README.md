# RandomRotate

Glyphs.app filter for randomly rotating glyphs around their center. After installation, trigger the filter with *Filter > Random Rotate,* enter a number for the maximum rotation angle, and apply the value:

![RandomRotate](RandomRotate.png)

### Custom Parameter

Use the gear menu in the lower left corner to copy a custom parameter with the current settings. You can then proceed to paste it in *File > Font Info > Instances,* in the *Custom Parameters* field of a listed font instance. At the end of the parameter value, add `; exclude:` or `; include:`, followed by a comma-separated list of glyph names, for excluding the indicated glyphs at export time, or limiting the filter’s effect to the glyphs, respectively. Example:

```
RandomRotate; maxAngle:40.0; exclude: a,b,c,adieresis
```

### Installation

1. In *Window > Plugin Manager,* look for *RandomRotate.*
2. Click the *Install* button next to its entry.
3. Restart Glyphs.

### Requirements

The plugin works in Glyphs 2.5 in High Sierra. I can only test it in current app and OS versions, and perhaps it works on earlier versions too.

### License

Copyright 2018 Rainer Erich Scheichelbauer (@mekkablue).
Based on sample code by Georg Seifert (@schriftgestalt) and Jan Gerner (@yanone).

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

See the License file included in this repository for further details.
