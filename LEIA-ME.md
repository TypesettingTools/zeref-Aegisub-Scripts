# __All About__

## __Instação__

Os arquivos contidos na pasta macros devem ser copiados para a
pasta _autoload_ no diretório do Aegisub.

Os arquivos contidos na pasta libraries devem ser copiados para a
pasta include no diretório do Aegisub.

## __Compatibilidade__

_Não tem compatibilidade com macOS._

As macros só funcionarão em versões do Aegisub que possuirem luajit e moonscript,
provavelmente depois da versão 3.2.x.

As macros foram testadas na versão 3.2.2 e master v9262.

Os sistemas testados foram, Windows 10 e Linux Debian 10.

No Windows foram testados nas arquiteturas x64 e x86, no linux apenas a versão x64.

As compilações das _Dynamic-link library_ (.dll) do Windows foram feitas no Windows 10.

As compilações dos _Shared Object_ (.so) do Linux foram feitas no Debian 10.

Aqui estão os códigos fontes para caso queiram compilar novos binarios.

[clipper](https://github.com/zerefxx/Lua-clipper),
[png](https://github.com/lvandeve/lodepng), 
[jpg](https://github.com/libjpeg-turbo/libjpeg-turbo), 
[gif](https://github.com/luapower/giflib)

## __Macros__

As interfaces em geral foram remasterizadas usando o [Aegisub master v9262](https://github.com/TypesettingTools/Aegisub).

Nas macros, eu padronizei algumas coisas.

- Todas extensões delas possuem zeref.
- Quase todas possuem os botões Save e Reset.
- Não possuem suporte para o Dependency Control (Não sei como posso fazer isso).

## Botões "_Save_ e _Reset_"

![N|Solid](images_macros/buttons.png)

Em quase todas macros possui esses dois botões.

Eles são importantes para um salvamento e redefinições em tempo real de configurações.

#### <span style="color:red">_Save_</span>

Salva aquela configuração que você está no momento.

O mais legal é que a macro não precisa ser fechada para o salvamento ocorrer.

Ele salva e ao mesmo tempo já chama a interface carregando as configurações salvadas.

O salvamento gerará um pequeno arquivo que ficará localizado na pasta data do Aegisub.

#### <span style="color:red">_Reset_</span>

Extendendo o _Save_, o _Reset_, reseta todas as configurações salvadas pelo _Save_.

Dessa forma, não é necessário você deletar os arquivos de configuração para obter
os valores padrões da interface.

## Checkbox _"Remove selected layers?"_

![N|Solid](images_macros/remove.png)

Em algumas macros você irá se cruzar com essa checkbox.

Ela tem simplismente o poder de eliminar a linha original da seleção de linhas,
isso depois de gerar o resultado da determinada macro.

---
### <span style="color:red">__Envelope Distort__</span>

![N|Solid](images_macros/envelope.png)

![N|Solid](images_macros/envelope_mesh.png)

Como podem ver, existem 2 macros dentro da _Envelope Distort._

- Make with - Mesh
- Make with - Perspective

__Definição__:

>Faz distorções de Envelope e Perspective em shapes e texto.

### Elementos da macro _Make with - Mesh_:

#### <span style="color:red">_Control Points_</span>

É a definição de pontos que vão ser gerados na Caixa Delimitadora.

Caso o _Control Points_ for 1, retornará uma Caixa Delimitadora comum, caso for maior
que 1, irá gerar um corte recursivo nela, dobrando a quantidade de pontos.

#### <span style="color:red">_Generator_</span>

É a definição de que tipo de coisa você gerará.

Só possui dois tipos de elementos nessa lista,
o _Mesh_ e o _Warp_.

O _Mesh_, você irá gerar a sua Caixa Delimitadora em forma de \clip,
a partir da definição do valor de _Control Points_.

O _Warp_, você irá gerar a transformação da shape, a partir do \clip
gerado pelo Mesh ou feito manualmente por você.

#### <span style="color:red">_Type_</span>

É a definição de que tipo de Pontos de Controle que será gerado.
Só possui dois tipos de elementos nessa lista,
o _Line_ e o _Bezier_.

Caso o _Type_ for _Line_, será gerado pontos de controle de line,
caso for bezier será gerado pontos de controle de bezier. 

#### <span style="color:red">_Tolerance_</span>

É a definição de comprimento da curva bezier.

Isso irá definir a precisão da curva bezier.

### _Make with - Perspective_.

Como devem ter percebido, a macro _Make with - Perspective_, não possui interface.

Ele gera uma perspectiva a partir do \clip gerado pelo Mesh com a configuração padrão do _Make with - Mesh_.

Você também pode fazer manualmente esse \clip tendo em mente que ele terá que ter apenas
quatro pontos de line formando uma caixa delimitadora.

---
### <span style="color:red">__Everything Shape__</span>

![N|Solid](images_macros/every_shape.png)

__Definição__:

>Faz várias operações em shapes.

### Elementos da macro _Everything Shape_.

#### <span style="color:red">_Mode List_</span>

Sendo o principal elemento da macro, o _Mode List_ define que tipo de coisa que
você quer fazer em uma shape ou texto.

Os elementos contidos em _Mode List_ são:

- Shape to Clip >> Transforma shapes para tags \clip.
- Clip to Shape >> Transforma tags \clip para shapes.
- Shape Origin >> Move shapes para origem do plano.
- Shape Poly >> Move os pontos para o alinhamento 7.
- Shape Expand >> Transforma shapes de acordo com as tags de perspective (\fax, \fay...).
- Shape Smooth >> Arredonda as bordas de shapes.
- Shape Simplify >> Simplifica consideravelmente a quantidade de pontos das shapes.
- Shape Split >> Corta shapes em pequenos pedaços.
- Shape Merge >> Mescla shapes de n linhas selecionadas.
- Shape Move >> Move os pontos da shape.
- Shape Round >> Arredonda os pontos da shape.
- Shape Clipper >> Corta shapes a partir da tag \clip ou \iclip.
- Text to Clip >> Transforma textos em \clip.
- Text to Shape >> Transforma textos em shape.

#### <span style="color:red">_Tolerance_</span>

É a definição de vários tipos de tolerancias relacionada com alguns modos.
Os não mencionados, não fazem parte.

Para _Shape Smooth_, é a definição do tamanho do arredondamento das bordas.

Para _Shape Simplify_, é a definição do tamanho de error na simplificação.

Para _Shape Split_, é a definição desse tamanho dividido pelo valor real do
comprimento das sequencias de pontos de line ou de bezier.

Para _Shape Round_, é a definição da quantidade de decimais depois do ponto.

#### <span style="color:red">_X - Axis e Y - Axis_</span>

É a definição de valores de x e y.

Esses valores são exclusivos para o elemento Shape Move de _Mode List_.

O eixo X será movido pela caixa _X - Axis_ e o eixo Y será movido pela caixa _Y - Axis_.

### <span style="color:red">_Botão Configure_</span>

![N|Solid](images_macros/every_shape_config.png)

Aqui está uma outra interface contida dentro da macro _Everything Shape_.

Essa foi feita exclusivamente para configurar alguns elementos de _Mode List_.

#### <span style="color:red">_Simplify Modes_</span>

É a definição de que tipo de simplificação será usado.

Só possui dois tipos de elementos nessa lista,
o _Line_ e o _Line and Bezier_.

O elemento _Line_ só simplificará pontos de line, caso tenha bezier contida na shape,
ele converterá esse pontos de bezier em line e simplificará, retornando apenas line.

O elemento _Line and Bezier_ também só simplificará os pontos de line, porém,
invés de retornar somentes pontos de line, retorna uma simplificação de pontos
de line para bezier.

#### <span style="color:red">_Split Modes_</span>

É a definição de que tipo de cortes será usado.

Os elementos contidos em _Split Modes_ são:

- Full >> Corta tanto os pontos de line como os de bezier.
- Line Only >> Corta somente pontos de line.
- Bezier Only >> Corta somente pontos de bezier.

---
### <span style="color:red">__Gradient Cut__</span>

![N|Solid](images_macros/gradient_cut.png)

__Definição__:

>Faz um gradiente em uma shape ou texto.

### Elementos da macro _Gradient Cut_.

#### <span style="color:red">_Gradient Types_</span>

Os elementos contidos em _Gradient Types_ são:

- Horizontal >> Gera o gradient no sentido Horizontal.
- Vertical >> Gera o gradient no sentido Vertical.

#### <span style="color:red">_Gap Size_</span>

Define o tamanho do corte de cada camada em pixels.

#### <span style="color:red">_Accel_</span>

Define a aceleração relativa da interpolação das cores.

#### <span style="color:red">_Colors_</span>

São as paletas de cores que vão definir de forma decrescente o gradient.

### <span style="color:red">_Botão Add+_</span>

Esse botão irá adicionar mais paletas de cores na interface.

---
### <span style="color:red">__Interpolate Master__</span>

![N|Solid](images_macros/interpolate.png)

__Definição__:

>Essa macro faz com que possamos interpolar valores de tags em linhas selecionadas.

>Você terá que fazer sua mudança desejada na primeira e última linha da seleção,
depois disso, é só marcar as tags que você quer fazer a interpolação.

>Para interpolação de clip, está disponível a interpolação de clip com vetor, porém
é necessário ambos terem a mesma quantidade de pontos.

### Elementos da macro _Interpolate Master_.

#### <span style="color:red">_Ignore Text_</span>

É necessário ativar essa opção para casos onde tiver mais de uma camada de tag.

#### <span style="color:red">_Accel_</span>

Define a aceleração relativa da interpolação.

---
### <span style="color:red">__Stroke Panel__</span>

![N|Solid](images_macros/stroke_panel.png)

__Definição__:

>Faz uma stroke ou um offset em volta de sua shape ou texto.

### Elementos da macro _Stroke Panel_.

#### <span style="color:red">_Stroke Corner_</span>

Os elementos contidos em _Stroke Corner_ são:

- Miter >> É o tipo de corner pontudo.
- Round >> É o tipo de corner arredondado.
- Square >> É o tipo de corner quadrado.

#### <span style="color:red">_Aligin Stroke_</span>

Os elementos contidos em _Stroke Corner_ são:

- Center >> Gera a outline no centro das arestas da shape.
- Inside >> Gera a outline dentro das arestas da shape.
- Outside >> Gera a outline fora das arestas da shape.

#### <span style="color:red">_Stroke Weight_</span>

É o tamanho da stroke.

#### <span style="color:red">_Miter Limit_</span>

[Miter Limit](http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Classes/ClipperOffset/Properties/MiterLimit.htm)

#### <span style="color:red">_Arc Tolerance_</span>

[Arc Tolerance](http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Classes/ClipperOffset/Properties/ArcTolerance.htm)

#### <span style="color:red">_Primary Color_</span>

É a cor primaria, equivalente a \1c.

#### <span style="color:red">_Stroke Color_</span>

É a cor da borda, equivalente a \3c.

#### <span style="color:red">_Generate only offset?_</span>

Caso for marcado, retorna só o offset.

---
### <span style="color:red">__Text in Clip__</span>

![N|Solid](images_macros/text_in_clip.png)

__Definição__:

>Faz com que os caracteres do texto se envolvam ao clip.

#### <span style="color:red">_Modes_</span>

Os elementos contidos em _Modes_ são:

- Center >> Gera uma saída alinhada no centro do clip.
- Left >> Gera uma saída alinhada na esquerda do clip.
- Right >> Gera uma saída alinhada na direita do clip.
- Around >> Gera uma saída alinhada ao redor do clip.
- Animated - Start to End >> Gera uma animação do começo ao fim do clip.
- Animated - End to Start >> Gera uma animação do fim ao começo do clip.

#### <span style="color:red">_Offset_</span>

Caso os modos não forem de animação, o valor de offset será equivalente
a um deslocamento de posição, caso forem de animação, o valor de offset será
equivalente ao step da duração de frame.

---
### <span style="color:red">__Image Trace__</span>

![N|Solid](images_macros/image_tracer.png)

__Definição__:

>Transforma imagens em shapes de forma customizada.

#### <span style="color:red">_Preset_</span>

Os elementos contidos em _Preset_ são:

- Custom >> Modo que permite customizar livremente os valores.
- Default >> Modo padrão do traçado.
- Detailed >> Modo que consegue detalhar bem os traços.
- Black and White >> Modo que retorna as cores somente preto e branco.
- Grayscale >> Modo que retorna as cores em escalas de cinza.
- 3 Colors >> Modo que retorna as 3 cores mais abrangentes na imagem.
- 6 Colors >> Modo que retorna as 6 cores mais abrangentes na imagem.
- 16 Colors >> Modo que retorna as 16 cores mais abrangentes na imagem.
- Smoothed >> Modo que retorna aos traços mais suavisados.

#### <span style="color:red">_Mode_</span>

Os elementos contidos em _Mode_ são:

- Custom >> Modo que permite customizar livremente os valores.
- Color >> Baseia-se em uma _Pellete_ determinística: grade retangular.
- Black and White >> Baseia-se na _Pellete_ de cores definida pelo número de cores e limita em 2 cores.
- Grayscale >> Baseia-se na _Pellete_ de cores definida pelo número de cores e limita em 7 cores.

#### <span style="color:red">_Pallete_</span>

Os elementos contidos em _Pallete_ são:

- Sampling >> Gera uma _Pallete_ a partir de valores aleatórios.
- Rectangular Grid >> Gera uma _Pallete_ determinística: grade retangular.
- Number of colors >> Gera uma _Pallete_ a partir do número de cores definido.

#### <span style="color:red">_Number of Colors_</span>

Define a quantidade do cores que será mapeada na imagem.

#### <span style="color:red">_Min Color Ratio_</span>

Define a quantidade minima de ratio, para casos onde possuem poucos pixels.

#### <span style="color:red">_Color Quant Cycles_</span>

Define a quantidade de ciclos no processamento de quantização.

#### <span style="color:red">_Right Angle ENH?_</span>

Define se deseja o realce do ângulo reto na interpolação de paths.

#### <span style="color:red">_Line Tres_</span>

Define o "error minimo" (precisão) dos valores de line.

#### <span style="color:red">_Bezier Tres_</span>

Define o "error minimo" (precisão) dos valores de Bezier.

#### <span style="color:red">_Pathomit_</span>

Define a remoção dos paths a partir desse valor.

#### <span style="color:red">_Round_</span>

Define a quantidade de decimais depois do ponto.

#### <span style="color:red">_Stroke Size_</span>

Define o tamanho da borda.

#### <span style="color:red">_Stroke Size_</span>

Define o tamanho da borda.

#### <span style="color:red">_Scale_</span>

Define a escala da shape, 1 equivale a 100%.

#### <span style="color:red">_Blur Radius_</span>

Define o raio do blur, que pode ser até 5.

#### <span style="color:red">_Blur Radius_</span>

Define o delta do blur, que pode ser até 1024.

Caso a diferença entre o pixel com blur e o pixel sem blur
for maior que delta, retorna o valor original do pixel.

#### <span style="color:red">_Ignore White?_</span>

Faz com que remova as partes de cor branca.

#### <span style="color:red">_Ignore Black?_</span>

Faz com que remova as partes de cor preta.

---
## __Bibliotecas__

A maioria das coisas relevantes aqui foram feitas por outras pessoas.

Deixarei os repositórios originais de onde eu obtive acesso a elas.

#### <span style="color:red">_img_libs_</span>

- [png, jpg, buffer](https://github.com/koreader/koreader-base/tree/master/ffi)
- [bmp](https://github.com/max1220/lua-bitmap)
- [gif](https://luapower.com/giflib)
- [image_tracer](https://github.com/jankovicsandras/imagetracerjs)

#### <span style="color:red">_others_</span>

- [Yutils](https://github.com/Youka/Yutils)
- [requireffi](https://github.com/TypesettingTools/ffi-experiments/tree/master/requireffi)
- [clipper](https://github.com/zerefxx/Lua-clipper)

#### <span style="color:red">_ZF/utils_</span>

É onde é armazada as principais funções utilizadas nas macros.

Aqui está a lista de class e metodos presentes nelas no momento.

   - <span style="color:red">class MATH</span>
      - new: =>
      - round: (x, dec) =>
      - distance: (x1, y1, x2, y2) => 
      - interpolation: (pct, min, max) =>
<br><br>
   - <span style="color:red">class TABLE</span>
      - new: (t) =>
      - copy: =>
      - map: (fn) =>
      - slice: (f, l, s) =>
      - push: (...) =>
      - concat: (...) =>
      - reduce: (fn, init) =>
      - view: (table_name, indent) =>
<br><br>
   - <span style="color:red">class l2b</span>
      - new: =>
      - polyline2bezier: (polyline, ____error) =>
      - solution: (shape, dist, ____error) =>
<br><br>
   - <span style="color:red">class l2l</span>
      - new: =>
      - simplify: (points, tolerance, highestQuality, closed) =>
      - solution: (points, tolerance, highestQuality, closed) =>
<br><br>
   - <span style="color:red">class BEZIER</span>
      - new: (...) =>
      - line: (t, b0, b1) =>
      - quadratic: (t, b0, b1, b2) =>
      - cubic: (t, b0, b1, b2, b3) =>
      - bernstein: (t, i, n) =>
      - create: (len) =>
      - len: (steps) =>
<br><br>
   - <span style="color:red">class SHAPER</span>
      - new: (shape, closed) =>
      - split: (size, seg, len_t) =>
      - bounding: (shaper) =>
      - info: =>
      - filter: (fils) =>
      - displace: (px, py) =>
      - scale: (sx, sy) =>
      - rotate: (angle, cx, cy) =>
      - origin: (min) =>
      - org_points: (an) =>
      - to_clip: (an, px, py) =>
      - unclip: (an, px, py) =>
      - perspective: (destin) =>
      - to_bezier: =>
      - envelop_distort: (ctrl_p1, ctrl_p2) =>
      - expand: (line, meta) =>
      - smooth_edges: (radius) =>
      - build: (typer, dec) =>
<br><br>
   - <span style="color:red">class POLY</span>
      - new: =>
      - to_points: (shape, scale) =>
      - to_shape: (points, rescale) =>
      - create_path: (path) =>
      - create_paths: (paths) =>
      - simplify: (paths, ass, tol, sp) =>
      - clean: (paths, sp) =>
      - get_solution: (path, rescale) =>
      - clipper: (sbj, clp, ft, ct, sp) =>
      - offset: (points, size, jt, et, mtl, act, sp) =>
      - to_outline: (points, size, jt, mode, mtl, act) =>
      - clip: (subj, clip, x, y, iclip) =>
<br><br>
   - <span style="color:red">class TEXT</span>
      - new: =>
      - to_shape: (line, text) =>
      - to_clip: (line, text, an, px, py) =>
<br><br>
   - <span style="color:red">class SUPPORT</span>
      - new: =>
      - interpolation: (pct, tp, ...) =>
      - tags2styles: (subs, line) =>
      - find_coords: (line, meta, ogp) =>
      - html_color: (color, mode) =>
      - clip_to_draw: (clip) =>
<br><br>
   - <span style="color:red">class CONFIG</span>
      - new: =>
      - file_exist: (file, dir) =>
      - read: (filename) =>
      - load: (GUI, macro_name) =>
      - save: (GUI, elements, macro_name, macro_version) =>
<br><br>
   - <span style="color:red">class TAGS</span>
      - new: (tags) =>
      - find: =>
      - clean: (text) =>
      - remove: (modes, tags) =>

Dentro da biblioteca <span style="color:red">_ZF/utils_</span> também tem algumas bibliotecas alheias.

   - [polyline2bezier](https://github.com/ynakajima/polyline2bezier)
   - [simplify-js](https://github.com/mourner/simplify-js)

Para mais informações, acesse o código fonte.

Qualquer dúvida vocês podem me chamar no discord _Zeref#8844_, só não garanto responder rapidamente.

[![License: MIT](https://img.shields.io/badge/License-MIT-red.svg)](https://opensource.org/licenses/MIT)