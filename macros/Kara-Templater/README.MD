# __Kara Templater Mod News__

## Check the files in the examples folder for better understanding

## _1_ - Two new template types, char and word, have been added.

## New char infos

- char = table containing all char values

__VALUES FROM INDEX__

- char.i = index of char
- char.si = index of char in syl
- char.wi = index of char in word
- char.n = max index of char.i
- char.sn = max index of char.si
- char.wn = max index of char.wi

__TIME VALUES__

- char.duration = duration of each char
- char.start_time = start of each char
- char.mid_time = mid of the duration of each char
- char.end_time = end of each char

__POSITIONING VALUES__

- char.left = left of each char
- char.center = center of each char
- char.right = right of each char
- char.top = top of each char, same as line.top
- char.middle = middle of each char, same as line.middle
- char.bottom = bottom of each char, same as line.middle

__VALUES OF DIMENSIONS__

- char.width = width of the char
- char.height = height of the char
- char.descent
- char.external_leading

![Example](https://user-images.githubusercontent.com/71021203/113371900-c6a62f00-933d-11eb-8e2a-b3ecdc2d594f.png)

__VALUES OF CHAR SYLLABLE__

- char.syl = table containing the values of char syllable references

_index_
- char.syl.i = the same as char.si
- char.syl.n = same as char.sn

_time_
- char.syl.duration = duration of each syl
- char.syl.start_time = start of each syl
- char.syl.mid_time = mid of each syl duration
- char.end_time = end of each syl
- char.si_duration = duration of interpolation of syl duration in char
- char.si_start_time = start of interpolation of syl duration in char
- char.si_mid_time = mid of interpolation of syl duration in char
- char.si_end_time = end of interpolation of syl duration in char

__VALUES OF CHAR WORD__

- char.word = table containing the values of char references in word

_index_
- char.word.i = same as char.wi
- char.word.n = same as char.wn

_time_
- char.wi_duration = duration of interpolation of word duration in char
- char.wi_start_time = start of interpolation of word duration in char
- char.wi_mid_time = mid of interpolation of word duration in char
- char.wi_end_time = end of interpolation of word duration in char

__OTHER CHAR VALUES__

- char.style = style reference information, same as line.styleref
- char.text = the char itself
- char.text_stripped = the char itself

## New word infos

- word = table containing all values of word

__VALUES FROM INDEX__

- word.i = word index
- word.n = max index of word.i

__TIME VALUES__

- word.duration = duration of each word
- word.start_time = start of each word
- word.mid_time = mid of the duration of each word
- word.end_time = end of each word

__POSITIONING VALUES__

- word.left = left of each word
- word.center = center of each word
- word.right = right of each word
- word.top = top of each word, same as line.top
- word.middle = middle of each word, same as line.middle
- word.bottom = bottom of each word, same as line.middle

__VALUES OF DIMENSIONS__

- word.width = word width
- word.height = word height
- word.descent
- word.external_leading

![Example](https://user-images.githubusercontent.com/71021203/113371900-c6a62f00-933d-11eb-8e2a-b3ecdc2d594f.png)

## _2_ - Two more loops have been added.

## New loops infos

__HOW TO USE__

_in effect_
- template loop {value1, value2, value3} or template loop value1

_in line_
- maxloop(value1, value2, value3)

_keys_
- value1 = j
- value2 = i
- value3 = k

_max keys_
- value1 = maxj
- value2 = maxi
- value3 = maxk

## _3_ - Bug fixes and extras.

- pre-line can now remove text using notext
- fixed syl.center, syl.left, syl.right
- added syl.n
- added bysyl, bychar, byword templates
- added a bunch of new retimes
- new retimes for char = char, prechar, porstchar, start2char, char2end, charpct
- new retimes for word = word, preword, porstword, start2word, word2end, wordpct
