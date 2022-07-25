# **Aegisub-Macros**

Aegisub-Macros is a collection of automations for the Aegisub tool. These automations were made exclusively for Typesetting, which is a type of function found in Fansubs.

---

## **Table of contents**

* [**Dependencies**](#id-1)
* [**Installation**](#id-2)
* [**How to use?**](#id-3)
    - [**All Characters To**](#id-3-1)
    - [**Split Text By**](#id-3-2)
    - [**Make Image**](#id-3-3)
        - [**Pixels**](#id-3-3-1)
        - [**Potrace**](#id-3-3-2)
    - [**Line To FBF**](#id-3-4)
    - [**Text in Clip**](#id-3-5)
    - [**Gradient Cut**](#id-3-6)
    - [**Everything Shape**](#id-3-7)
* [**Thanks**](#id-4)
* [**Final considerations**](#id-5)

---

## **Dependencies** <a id="id-1"></a>

Aegisub-Macros depends on some external libraries for its functioning, follow the list below and check all these dependencies:

* [**Yutils**](https://github.com/Youka/Yutils)
* [**requireffi**](https://github.com/TypesettingTools/ffi-experiments/tree/master/requireffi)

Furthermore, Aegisub-macros contains some additional dependencies for its full functionality. They are intended for specific macros and can be found in the branch [**build**](https://github.com/zerefxx/Aegisub-macros/tree/build).

---

## **Installation** <a id="id-2"></a>

<!-- https://github.com/zerefxx/Aegisub-macros/releases -->
1. [Download](https://github.com/zerefxx/Aegisub-macros/releases) the latest released version according to your operating system
2. Extract the file and copy the `autoload` and `include` folders
3. Find your Aegisub's `automation` directory and open it
4. Paste the `autoload` and `include` folders

### Find `automation` directory:

* Windows (**Aegisub Installed**): Open the file explorer and type `%appdata%` in the search engine and then open the Aegisub folder, if you don't have the `automation` folder, do another search only now changing the typing to `%programfiles%` and open the Aegisub folder.

* Windows (**Aegisub Portable**): Identify where you extracted the Aegisub Portable and open the folder.

* Linux: Open the folder `~/.aegisub/`

* MacOS: Open the folder `~/Library/Application Support/Aegisub/`

---

## **How to use?** <a id="id-3"></a>

Macros were developed to be used in the simplest possible way, especially because they are automations and not complications.

The tutorial will follow a sequence from the simplest macro to the most complex in terms of usability and functions.

Most macros will contain some of the same things, so to avoid repetition in the explanations, I'll leave their description here.

If you find a checkbox called **Remove selected layers?** know that its function is only to remove the lines you selected, if it is enabled. Otherwise, your original line will not be removed, but commented out to avoid conflicts.

If you find a button called **Reset**, know that it is used to reset your macro settings to the original state, but it is important to know that this reset will only be saved if the macro executes another execution, otherwise the macro will be in current state.

To start processing a macro, click the **Ok** button.

To cancel the execution of the macro click on the **Cancel** button.

---

### - Macro: **All Characters To** <a id="id-3-1"></a>

It has no interface, but it does have _submacros_. Its functionality is to convert characters to a specific mode, defined by _submacros_. Below is the description for each of these modes:

| Name        | Description                                              |
| ----------- | -------------------------------------------------------- |
| Upper-case  | Converts characters to upper-case                        |
| Lower-case  | Converts characters to lower-case                        |
| Capitalized | Converts the first character of a sentence to upper-case |

---

### - Macro: **Splits Text By** <a id="id-3-2"></a>

It has no interface, but it does have _submacros_. Its functionality is to split the text in a specific way, defined by the _submacros_. Below is the description for each of these modes:

| Name  | Description                           |
| ----- | ------------------------------------- |
| Chars | Splits text to character by character |
| Words | Splits text to word by word           |
| Tags  | Splits text to tag by tag             |

---

### - Macro: **Make Image** <a id="id-3-3"></a>

First of all, it is important to explain the dependence that this macro has on additional libraries, you can use this macro as long as you have at least 1 image decoding library and that the image you want to convert is compatible with this library or use a **.bmp** image that does not depend on external libraries.

Its functionality is to convert an image to **.ass** format in a specific way, defined by _submacros_.

When entering any of the _submacros_ you will come across a file explorer window, where you can select the image you want to convert to.

Below is the description for each of these modes:

---

### - Submacro: **Pixels** <a id="id-3-3-1"></a>

Converts an image's pixels into **.ass** drawing pixels by adding the colors and opacities.

### **Interface options settings:**

**Output Type:** Defines the output mode you want to convert pixels to.

| Name                     | Description                                         |
| ------------------------ | --------------------------------------------------- |
| All in one line          | Converts pixels to just 1 line                      |
| On several lines - "Rec" | Converts pixels to just their height value in lines |
| Pixel by Pixel           | Converts pixel by pixel                           |

---

### - Submacro: **Potrace** <a id="id-3-3-2"></a>

Convert the image to a vector graphic, which allows smoothing and scaling of the image.

### **Interface options settings:**

| Name                | Description                                        |
| ------------------- | -------------------------------------------------- |
| Turnpolicy          | Resolves ambiguities in path decomposition         |
| Corner threshold    | Defines the limit for corners                      |
| Delete until        | Defines the size of the spots that will be deleted |
| Tolerance           | Defines the curve optimization tolerance           |
| Curve optimization? | Enables or disables curve optimization             |

---

### - Macro: **Line To FBF** <a id="id-3-4"></a>

Its functionality is to convert the original line to frame by frame and it can also do all the line transformations. This means that it can transform `\move` , `\fad` , `\fade` and `\t` tags frame by frame accurately.

The differential of this macro is that it can transform vector `\clip` with the `\t` tag, as long as they have the same number of points.

### **Interface options settings:**

**Frame steps:** Defines what the frame space will be until the next line.

---

### - Macro: **Text in Clip** <a id="id-3-5"></a>

Its functionality is to make text or a shape distort around a `\clip` .

### **Interface options settings:**

**Modes:** Defines which type of distortion will be distributed in the text.

| Name                     | Description                               |
| ------------------------ | ----------------------------------------- |
| Left                     | At the beginning of `\clip` |
| Center                   | At the center of `\clip` |
| Right                    | At the end of `\clip` |
| Around                   | Around the `\clip` |
| Animated - Left to Right | Animated from beginning to end of `\clip` |
| Animated - Right to Left | Animated from end to beginning of `\clip` |

**Enable Shape:** Defines if the distortion will occur in a shape or in a text, if the option is activated and your line contains text, this text will be converted into a shape, and if your line contains a shape and this option is not enabled, your line will not be processed.

**Offset:** Defines the offset of the text in relation to `\clip` and also defines what the frame space will be until the next line in the case where the defined mode is animated.

---

### - Macro: **Gradient Cut** <a id="id-3-6"></a>

Its functionality is to create a gradient in a text or in a shape through cuts in sequence, it uses the clipper library to make these cuts, that is, it needs an additional dependency.

**Add+** button, adds a color palette to the interface. If the interface reaches 16 colors, it will no longer be possible to add.

**Rem-** button, removes a color palette from the interface. If the interface contains only 2 color palettes, it will no longer be possible to remove.

### **Interface options settings:**

**Gradient Type:** Defines which type of gradient will be used.

| Name       | Description                                            |
| ---------- | ------------------------------------------------------ |
| Vertical   | Gradient is made vertically                            |
| Horizontal | Gradient is made horizontal                            |
| By Angle   | Gradient is made in the direction of the defined angle |

**Gap Size:** Defines what the gap between the cuts will be, in theory the greater this value the more the gradient loses its quality, but for some specific cases this option can be quite useful.

**Accel:** Defines the interpolation acceleration in relation to the gradient color, defined to 1 means a linear interpolation between the colors.

**Angle:** Defines the angle if your **Gradient Type** is defined to **By Angle**.

**Colors:** Defines the colors will be in the gradient.

---

### - Macro: **Everything Shape** <a id="id-3-7"></a>

First of all, it is interesting to talk about the macro's relationship with text, it treats text in the same way as a shape, because it is able to identify if the text is in fact a text, and if it is, it automatically converts it to a shape . Furthermore, it is important to know that some macro features need the clipper library, that is, it needs an additional dependency.

Its functionality is to make a lot of manipulations in shapes, unfortunately it is not possible to have a definitive description for this macro because of so many features that are implemented in it, so follow the definitions below to know what each functionality contained in it is capable of doing.

---

### **Interface options settings:**

**Close paths:** Defines if the new shape will be closed or open, open means that the last point in the path is not equal to the first point and closed is the opposite.

> All options that are below this sentence are processed by the button `Shape` .

**Mode List:** Defines which way the shape will be manipulated.

| Name                | Description                                                                                                                                                                   |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Clip To Shape       | Converts the `\clip` or `\iclip` tag into a shape                                                                                                                             |
| Shape Bounding Box  | Replaces the shape with its bounding box                                                                                                                                      |
| Shape Clipper       | Makes a real cut in the shape through the overlay made by the `\clip` or `\iclip` tag                                                                                         |
| Shape Expand        | Distorts the shape according to positioning, scale and perspective tags ( `\org` , `\pos` , `frx` , `\fry` , `\frz` , `\fax` , `\fay` , `\fscx` , `\fscy` , `\p` )                       |
| Shape Flatten       | Flattens the segments of the shape uniformly, thus increasing the number of points. The flattening distance is defined in the **Tolerance** option                            |
| Shape Merge         | Merges multiple shapes to just 1 shape.                                                                                                                                       |
| Shape Move          | Moves the shape through the X-Axis and Y-Axis options settings                                                                                                                |
| Shape Origin        | Moves the shape into its origin                                                                                                                                               |
| Shape Round         | Rounds the floating points of the shape. The precision is defined in the **Tolerance** option                                                                                 |
| Shape Round Corners | Rounds the corners of the shape. The rounding radius is defined in the **Tolerance** option                                                                                   |
| Shape Simplify      | Removes self-intersections from the shape and simplifies the number of points present in the shape. The accuracy of the simplification is defined in the **Tolerance** option |

**Simplify Modes:** Defines what type of simplification will be. The simplification will be done both for the **Shape Simplify** option contained in **Mode List:** and for the options related to **Stroke**.

| Name | Description                                 |
| ---- | ------------------------------------------- |
| Full | Simplifies line segments to bezier segments |
| Line | Simplifies line segments                    |

**Flatten Modes:** Defines on which segment type the flattening will be made.

| Name   | Description                        |
| ------ | ---------------------------------- |
| Full   | Flattening only in any segment     |
| Bezier | Flattening only in bezier segments |
| Line   | Flattening only in linear segments |

**X-Axis:** Defines the movement on the X axis when the mode is **Shape Move**.

**Y-Axis:** Defines the movement on the Y axis when the mode is **Shape Move**.

**Tolerance:** This option has several definitions, because it is used as a specific variable in different modes. In **Shape Flatten** mode it is defined as the flattening distance, in **Shape Round** mode it is defined as the precision for the rounding, in **Shape Round Corners** mode it is defined as the rounding radius and in **Shape Simplify** mode is defined as the precision of the simplification.

> All options that are below this sentence are processed by the button `Stroke` .

**Stroke Corner:** Defines the type of corner of the stroke.

| Name   | Description                     |
| ------ | ------------------------------- |
| Miter  | Defines stroke corner to Miter  |
| Round  | Defines stroke corner to Round  |
| Square | Defines stroke corner to Square |

**Align Stroke:** Defines the alignment of the stroke in relation to the shape.

| Name    | Description                                                                      |
| ------- | -------------------------------------------------------------------------------- |
| Center  | Defines that the stroke will inflate both the inner and outer space of the shape |
| Inside  | Defines that the stroke will inflate in the shape internal space                 |
| Outside | Defines that the stroke will inflate in the shape external space                 |

**Stroke Weight:** Defines the stroke size in pixels.

**Miter Limit:** Defines the maximum distance in delta multiples that vertices can be shifted from their original positions before the square is applied. (Square truncates a miter by 'cutting' it 1 × delta away from the original vertex.)

**Arc Tolerance:** Defines the quality of the arc, smaller values will make the arc smoother, but it will have a higher processing cost.

**Generate only offset:** Defines if the output will be just the offset instead of the stroke itself.

> All options that are below this sentence are processed by the button `Envelope` .

**Control Points:** Defines the amount of divisions that will be made in the bounding box, the amount of new segments can be found by multiplying 4 (original number of segments) times the defined value. This option is only valid if the **Type** option is set to **Line** and the **Generator** option is set to **Mesh**.

**Type:** Defines the type of segment that will be in the mesh. This option is only valid if the **Generator** option is set to **Mesh**.

| Name   | Description          |
| ------ | -------------------- |
| Line   | Line segments only   |
| Bezier | Bezier segments only |

**Generator:** Defines the type of output that will be processed.

| Name        | Description                                                      |
| ----------- | ---------------------------------------------------------------- |
| Mesh        | Creates a new mesh using the `\clip` tag                         |
| Warp        | Envelope distortion through a mesh defined by the `\clip` tag    |
| Perspective - A | Perspective distortion through a mesh defined by the `\clip` tag that uses the \clip bounding box as reference |
| Perspective - B | Perspective distortion through a mesh defined by the `\clip` tag that uses the shape bounding box as reference |

---

## **Thanks** <a id="id-4"></a>

Thanks to all the authors of the external libraries that are part of Aegisub-macros.

* [Yutils](https://github.com/Youka/Yutils) Youka
* [requireffi](https://github.com/TypesettingTools/ffi-experiments/tree/master/requireffi) torque
* [clipper](http://www.angusj.com/delphi/clipper.php) Angus Johnson
* [giflib](http://giflib.sourceforge.net/) Gershon Elber, Eric S. Raymond, Toshio Kuratomi.
* [libjpeg-turbo](https://libjpeg-turbo.org/) Miyasaka Masaru
* [lodepng](https://lodev.org/lodepng/) Lode Vandevenne
* [lua-bitmap](https://github.com/max1220/lua-bitmap) Max Sahm
* [polyline2bezier](https://github.com/ynakajima/polyline2bezier) Philip J. Schneider's
* [simplify-js](https://github.com/mourner/simplify-js) Vladimir Agafonkin
* [libass](https://github.com/libass/libass) libass

---

## **Final considerations** <a id="id-5"></a>

These macros are the result of several complications and headaches that I've suffered being a Fansubber, even nowadays I don't have that energy anymore it's really cool to know that I can make some people's lives easier.

Overall, all that's left is to enjoy.
