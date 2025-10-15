![](../Assets/header2.jpg)

<p align="center">
    <a href="https://github.com/Juanpe/SkeletonView/actions?query=workflow%3ACI">
      <img src="https://github.com/Juanpe/SkeletonView/workflows/CI/badge.svg">
    </a>
    <a href="https://codebeat.co/projects/github-com-juanpe-skeletonview-main"><img alt="codebeat badge" src="https://codebeat.co/badges/1f37bbab-a1c8-4a4a-94d7-f21740d461e9" /></a>
    <a href="https://cocoapods.org/pods/SkeletonView"><img src="https://img.shields.io/cocoapods/v/SkeletonView.svg?style=flat"></a>
    <a href="https://github.com/Carthage/Carthage/"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat"></a>
    <a href="https://swift.org/package-manager/"><img src="https://img.shields.io/badge/SPM-supported-Green.svg?style=flat"></a>
    <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FJuanpe%2FSkeletonView%2Fbadge%3Ftype%3Dplatforms"/>
    <a href="https://badge.bow-swift.io/recipe?name=SkeletonView&description=An%20elegant%20way%20to%20show%20users%20that%20something%20is%20happening%20and%20also%20prepare%20them%20to%20which%20contents%20he%20is%20waiting&url=https://github.com/juanpe/skeletonview&owner=Juanpe&avatar=https://avatars0.githubusercontent.com/u/1409041?v=4&tag=1.20.0"><img src="https://raw.githubusercontent.com/bow-swift/bow-art/master/badges/nef-playgrounds-badge.svg" alt="SkeletonView Playground" style="height:20px"></a>   
</p>

<p align="center">
  <a href="#-caracteristicas">Características</a>
  • <a href="#-guias">Guías</a>
  • <a href="#-instalacion">Instalación</a>
  • <a href="#-uso">Uso</a>
  • <a href="#-otros">Otros</a>
  • <a href="#️-contribuir">Contribuir</a>
</p>

**🌎 README disponible en otros idiomas: [🇬🇧](../README.md) . [🇪🇸](README_es.md) . [🇨🇳](README_zh.md) . [🇧🇷](README_pt-br.md) . [🇰🇷](README_ko.md) . [🇫🇷](README_fr.md) . [🇩🇪](README_de.md)**

Hoy en día casi todas las apps tienen procesos asíncronos: llamadas a API, tareas largas, etc. Mientras esos procesos se completan, normalmente mostramos algún indicador para que el usuario sepa que “algo” está ocurriendo.

**SkeletonView** nace para cubrir esa necesidad mostrando de forma elegante que se está cargando contenido y, además, preparando al usuario para la estructura que verá.

¡Disfrútalo! 🙂

##

- [🌟 Características](#-caracteristicas)
- [🎬 Guías](#-guias)
- [📲 Instalación](#-instalacion)
- [🐒 Uso](#-uso)
  - [🌿 Colecciones](#-colecciones)
  - [🔠 Textos](#-textos)
  - [🦋 Apariencia](#-apariencia)
  - [🎨 Colores personalizados](#-colores-personalizados)
  - [🏃‍♀️ Animaciones](#️-animaciones)
  - [🏄 Transiciones](#-transiciones)
  - [🧩 Data Source Diffable](#-diffable-data-source)
- [✨ Otros](#-otros)
- [❤️ Contribuir](#️-contribuir)
- [📢 Menciones](#-menciones)
- [🏆 Sponsors](#-sponsors)
- [👨🏻‍💻 Autor](#-autor)
- [👮🏻 Licencia](#-licencia)

## 🌟 Características

* Fácil de usar
* Todas las UIViews pueden ser skeletonables
* Totalmente personalizable
* Universal (iPhone & iPad)
* Integración cómoda con Interface Builder
* Sintaxis Swift simple
* Código legible

## 🎬 Guías

| [![](https://img.youtube.com/vi/75kgOhWsPNA/maxresdefault.jpg)](https://youtu.be/75kgOhWsPNA)|[![](https://img.youtube.com/vi/MVCiM_VdxVA/maxresdefault.jpg)](https://youtu.be/MVCiM_VdxVA)|[![](https://img.youtube.com/vi/Qq3Evspeea8/maxresdefault.jpg)](https://youtu.be/Qq3Evspeea8)|[![](https://img.youtube.com/vi/Zx1Pg1gPfxA/maxresdefault.jpg)](https://www.youtube.com/watch?v=Zx1Pg1gPfxA)
|:---:  | :---:  | :---: | :---:
|[**SkeletonView Guides - Getting started**](https://youtu.be/75kgOhWsPNA)|[**How to Create Loading View with Skeleton View in Swift 5.2**](https://youtu.be/MVCiM_VdxVA) by iKh4ever Studio|[**Create Skeleton Loading View in App (Swift 5) - Xcode 11, 2020**](https://youtu.be/Qq3Evspeea8) by iOS Academy| [**Cómo crear una ANIMACIÓN de CARGA de DATOS en iOS**](https://www.youtube.com/watch?v=Zx1Pg1gPfxA) by MoureDev

## 📲 Instalación

* **CocoaPods**
```ruby
pod 'SkeletonView'
```
* **Carthage**
```ruby
github "Juanpe/SkeletonView"
```
* **Swift Package Manager**
```swift
dependencies: [
  .package(url: "https://github.com/Juanpe/SkeletonView.git", from: "1.7.0")
]
```
> 📣 **IMPORTANTE**
> Desde la versión 1.30.0 `SkeletonView` soporta **XCFrameworks**. Si quieres instalarlo como XCFramework usa este repo: [SkeletonView-XCFramework](https://github.com/Juanpe/SkeletonView-XCFramework.git).

## 🐒 Uso

Solo **3** pasos para usar `SkeletonView`:

1️⃣ Importa el módulo donde lo necesites:
```swift
import SkeletonView
```
2️⃣ Marca qué vistas serán `skeletonable` (por código o Interface Builder):
```swift
avatarImageView.isSkeletonable = true
```
3️⃣ Muestra el skeleton (4 opciones):
```swift
(1) view.showSkeleton()                 // Sólido
(2) view.showGradientSkeleton()         // Gradiente
(3) view.showAnimatedSkeleton()         // Sólido animado
(4) view.showAnimatedGradientSkeleton() // Gradiente animado
```

**Previsualización**

<table>
<tr>
<td width="25%"><center>Sólido</center></td>
<td width="25%"><center>Gradiente</center></td>
<td width="25%"><center>Sólido animado</center></td>
<td width="25%"><center>Gradiente animado</center></td>
</tr>
<tr>
<td><img src="../Assets/solid.png"></td>
<td><img src="../Assets/gradient.png"></td>
<td><img src="../Assets/solid_animated.gif"></td>
<td><img src="../Assets/gradient_animated.gif"></td>
</tr>
</table>

> 📣 **IMPORTANTE**
> `SkeletonView` es recursivo. Si llamas a `show*` en la vista contenedora principal mostrará el skeleton en todas las subviews skeletonables (p.e. en el root view de un UIViewController).

### 🌿 Colecciones

`SkeletonView` es compatible con `UITableView` y `UICollectionView`.

## 🧩 Diffable Data Source

Soporte para `UITableViewDiffableDataSource` y `UICollectionViewDiffableDataSource` (iOS/tvOS 13+) vía:
* `SkeletonDiffableTableViewDataSource`
* `SkeletonDiffableCollectionViewDataSource`

Coordina el ciclo de vida del skeleton con snapshots diffable:
* Muestra skeleton mientras hay carga.
* Mantiene skeleton si aplicas snapshot vacío estando en carga.
* Oculta automáticamente tras el primer snapshot no vacío (o manual con `endLoading`).
* Placeholders inline opcionales (`useInlinePlaceholders`) sin cambiar a un data source dummy: se mantienen secciones/layout.
* Reinicia un ciclo de carga con `resetAndShowSkeleton`.

#### Ejemplo UITableView (inline placeholders)
```swift
@available(iOS 13.0, *)
final class MiTablaVC: UIViewController {
    enum Section { case main }
    struct Row: Hashable { let id = UUID(); let title: String }
    @IBOutlet private weak var tableView: UITableView!
    private var ds: SkeletonDiffableTableViewDataSource<Section, Row>!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.isSkeletonable = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        ds = tableView.makeSkeletonDiffableDataSource(useInlinePlaceholders: true) { tv, indexPath, row in
            let cell = tv.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.isSkeletonable = true
            cell.textLabel?.text = row.title
            return cell
        }
        ds.configurePlaceholderCell = { tv, indexPath in
            let c = tv.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            c.isSkeletonable = true
            c.textLabel?.text = "Cargando…"
            c.textLabel?.alpha = 0.55
            return c
        }
        ds.beginLoading()
        cargar()
    }
    private func cargar() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            let datos = (0..<10).map { Row(title: "Fila \($0)") }
            var snap = NSDiffableDataSourceSnapshot<Section, Row>()
            snap.appendSections([.main])
            snap.appendItems(datos)
            DispatchQueue.main.async { self.ds.endLoadingAndApply(snap) }
        }
    }
}
```

#### Ejemplo UICollectionView (inline placeholders)
```swift
@available(iOS 13.0, *)
final class MiColeccionVC: UIViewController {
    enum Section { case main }
    struct Item: Hashable { let id = UUID(); let title: String }
    @IBOutlet private weak var collectionView: UICollectionView!
    private var ds: SkeletonDiffableCollectionViewDataSource<Section, Item>!
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.isSkeletonable = true
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        ds = collectionView.makeSkeletonDiffableDataSource(useInlinePlaceholders: true) { cv, indexPath, item in
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
            cell.isSkeletonable = true
            return cell
        }
        ds.configurePlaceholderCell = { cv, indexPath in
            let c = cv.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
            c.isSkeletonable = true
            c.backgroundColor = .secondarySystemFill
            return c
        }
        ds.beginLoading()
        cargar()
    }
    private func cargar() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            let items = (0..<12).map { Item(title: "Item \($0)") }
            var snap = NSDiffableDataSourceSnapshot<Section, Item>()
            snap.appendSections([.main])
            snap.appendItems(items)
            DispatchQueue.main.async { self.ds.endLoadingAndApply(snap) }
        }
    }
}
```

#### Resumen de API
```swift
beginLoading(showSkeleton: Bool = true)
endLoading()
endLoadingAndApply(_:animatingDifferences:completion:)
applySnapshot(_:animatingDifferences:completion:)
resetAndShowSkeleton(keepSections:showSkeleton:animatingDifferences:)
configurePlaceholderCell // Configura celda para placeholders inline
```
> Nota: placeholders inline desactivados por defecto. iOS/tvOS 13+.

También puedes esqueletizar headers y footers implementando `SkeletonTableViewDelegate`.
```swift
public protocol SkeletonTableViewDelegate: UITableViewDelegate {
    func collectionSkeletonView(_ skeletonView: UITableView, identifierForHeaderInSection section: Int) -> ReusableHeaderFooterIdentifier?
    func collectionSkeletonView(_ skeletonView: UITableView, identifierForFooterInSection section: Int) -> ReusableHeaderFooterIdentifier?
}
```

> 📣 **IMPORTANTE**
> 1️⃣ Si usas celdas con altura dinámica (`tableView.rowHeight = UITableViewAutomaticDimension`) define también `estimatedRowHeight`.
>
> 2️⃣ Añade subviews dentro de `contentView` de la celda, no directamente sobre la celda.
>
> ```swift
> contentView.addSubview(titleLabel) ✅
> addSubview(titleLabel) ❌
> ```

**UICollectionView**

Para `UICollectionView` implementa `SkeletonCollectionViewDataSource`:
```swift
public protocol SkeletonCollectionViewDataSource: UICollectionViewDataSource {
    func numSections(in collectionSkeletonView: UICollectionView) -> Int
    func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> ReusableCellIdentifier
    func collectionSkeletonView(_ skeletonView: UICollectionView, supplementaryViewIdentifierOfKind: String, at indexPath: IndexPath) -> ReusableCellIdentifier?
    func collectionSkeletonView(_ skeletonView: UICollectionView, skeletonCellForItemAt indexPath: IndexPath) -> UICollectionViewCell?
    func collectionSkeletonView(_ skeletonView: UICollectionView, prepareCellForSkeleton cell: UICollectionViewCell, at indexPath: IndexPath)
    func collectionSkeletonView(_ skeletonView: UICollectionView, prepareViewForSkeleton view: UICollectionReusableView, at indexPath: IndexPath)
}
```
El resto es el mismo proceso que con `UITableView`.

### 🔠 Textos

![](../Assets/multilines2.png)

Cuando una vista contiene texto, `SkeletonView` dibuja líneas simulando ese contenido.

Puedes ajustar varias propiedades para vistas multilínea:

| Variable | Tipo | Por defecto | Vista previa |
| ------- | ------- |------- | ------- |
| **lastLineFillPercent**  | `CGFloat` | `70`| ![](../Assets/multiline_lastline.png)
| **linesCornerRadius**  | `Int` | `0` | ![](../Assets/multiline_corner.png)
| **skeletonLineSpacing**  | `CGFloat` | `10` | ![](../Assets/multiline_lineSpacing.png)
| **skeletonPaddingInsets**  | `UIEdgeInsets` | `.zero` | ![](../Assets/multiline_insets.png)
| **skeletonTextLineHeight**  | `SkeletonTextLineHeight` | `.fixed(15)` | ![](../Assets/multiline_lineHeight.png)
| **skeletonTextNumberOfLines**  | `SkeletonTextNumberOfLines` | `.inherited` | ![](../Assets/multiline_corner.png)

Para cambiar porcentaje o radio:
```swift
descriptionTextView.lastLineFillPercent = 50
descriptionTextView.linesCornerRadius = 5
```
O en Interface Builder.

Número de líneas: por defecto se usa `numberOfLines`. Si es 0 se calcula para llenar el espacio. Para forzar:
```swift
label.skeletonTextNumberOfLines = 3 // .custom(3)
```

> **⚠️ DEPRECATED**
> `useFontLineHeight` fue eliminado. Usa `skeletonTextLineHeight = .relativeToFont`.

> **📣 IMPORTANTE**
> En vistas de una sola línea, esa línea se considera la última.

### 🦋 Apariencia

Si no configuras nada se usan valores por defecto:

- **tintColor**: `.skeletonDefault` (adaptativo dark mode)
- **gradient**: `SkeletonGradient(baseColor: .skeletonDefault)`
- **multilineHeight**: 15
- **multilineSpacing**: 10
- **multilineLastLineFillPercent**: 70
- **multilineCornerRadius**: 0
- **skeletonCornerRadius**: 0

Puedes leer/modificar a través de `SkeletonAppearance.default`:
```swift
SkeletonAppearance.default.multilineHeight = 20
SkeletonAppearance.default.tintColor = .green
```

> **⚠️ DEPRECATED**
> `useFontLineHeight` eliminado. Usa `textLineHeight = .relativeToFont`.

### 🎨 Colores personalizados

Color sólido:
```swift
view.showSkeleton(usingColor: UIColor.gray)
```
Gradiente:
```swift
let gradient = SkeletonGradient(baseColor: UIColor.midnightBlue)
view.showGradientSkeleton(usingGradient: gradient)
```
Hay 20 colores flat disponibles: `UIColor.turquoise`, `UIColor.greenSea`, ...

![](../Assets/flatcolors.png)

### 🏃‍♀️ Animaciones

Disponibles dos animaciones integradas: pulse (sólido) y sliding (gradiente). Puedes crear la tuya pasando un `SkeletonLayerAnimation`:
```swift
view.showAnimatedSkeleton { layer in
  let animation = CAAnimation()
  return animation
}
```
Builder para sliding:
```swift
let animation = SkeletonAnimationBuilder().makeSlidingAnimation(withDirection: .leftToRight)
view.showAnimatedGradientSkeleton(usingGradient: gradient, animation: animation)
```
Direcciones (`GradientDirection`): leftRight, rightLeft, topBottom, bottomTop, topLeftBottomRight, bottomRightTopLeft.

### 🏄 Transiciones

Transiciones para mostrar/ocultar suavemente:
```swift
view.showSkeleton(transition: .crossDissolve(0.25))
view.hideSkeleton(transition: .crossDissolve(0.25))
```
Valor por defecto: `crossDissolve(0.25)`.

## ✨ Otros

**Jerarquía**: Al ser recursivo, marca como skeletonable el contenedor para que descienda correctamente. Ejemplos visuales:

| Configuración | Resultado |
|:--:|:--:|
|<img src="../Assets/no_skeletonable.jpg" width="350"/> | <img src="../Assets/no_skeletonables_result.png" width="350"/>|
|<img src="../Assets/container_no_skeletonable.jpg" width="350"/> | <img src="../Assets/no_skeletonables_result.png" width="350"/>|
|<img src="../Assets/container_skeletonable.jpg" width="350"/> | <img src="../Assets/container_skeletonable_result.png" width="350"/>|
|<img src="../Assets/all_skeletonables.jpg" width="350"/>| <img src="../Assets/all_skeletonables_result.png" width="350"/>|
|<img src="../Assets/tableview_no_skeletonable.jpg" width="350"/> | <img src="../Assets/tableview_no_skeletonable_result.png" height="350"/>|
|<img src="../Assets/tableview_skeletonable.jpg" width="350"/> | <img src="../Assets/tableview_skeletonable_result.png" height="350"/>|

**Re-layout**:
```swift
override func viewDidLayoutSubviews() {
    view.layoutSkeletonIfNeeded()
}
```
> Desde 1.8.1 no es necesario salvo casos especiales.

**Actualizar skeleton**:
```swift
view.updateSkeleton()
view.updateGradientSkeleton()
view.updateAnimatedSkeleton()
view.updateAnimatedGradientSkeleton()
```
**Ocultar vistas cuando empieza animación**:
```swift
view.isHiddenWhenSkeletonIsActive = true
```
**Mantener interacción**:
```swift
view.isUserInteractionDisabledWhenSkeletonIsActive = false
```
**Desactivar ajuste automático de altura de fuente**:
```swift
label.useFontLineHeight = false
```
**Mostrar con retardo**:
```swift
view.showSkeleton(usingColor: .gray, animated: true, delay: 0.25, transition: .crossDissolve(0.2))
```
**Debug**: Activa variable de entorno `SKELETON_DEBUG` para ver el árbol.

**SO soportados**:
- iOS 9.0+
- tvOS 9.0+
- Swift 5.3

## ❤️ Contribuir

Es open source; puedes:
- Abrir un [issue](https://github.com/Juanpe/SkeletonView/issues/new)
- Enviar feedback por [email](mailto://juanpecatalan.com)
- Enviar un Pull Request

Lee las [contributing guidelines](https://github.com/Juanpe/SkeletonView/blob/main/CONTRIBUTING.md).

## 📢 Menciones

- [iOS Dev Weekly #327](https://iosdevweekly.com/issues/327#start)
- [Hacking with Swift Articles](https://www.hackingwithswift.com/articles/40/skeletonview-makes-loading-content-beautiful)
- [Top 10 Swift Articles November](https://medium.mybridge.co/swift-top-10-articles-for-the-past-month-v-nov-2017-dfed7861cd65)
- [30 Amazing iOS Swift Libraries (v2018)](https://medium.mybridge.co/30-amazing-ios-swift-libraries-for-the-past-year-v-2018-7cf15027eee9)
- [AppCoda Weekly #44](http://digest.appcoda.com/issues/appcoda-weekly-issue-44-81899)
- [iOS Cookies Newsletter #103](https://us11.campaign-archive.com/?u=cd1f3ed33c6527331d82107ba&id=48131a516d)
- [Swift Developments Newsletter #113](https://andybargh.com/swiftdevelopments-113/)
- [iOS Goodies #204](http://ios-goodies.com/post/167557280951/week-204)
- [Swift Weekly #96](http://digest.swiftweekly.com/issues/swift-weekly-issue-96-81759)
- [CocoaControls](https://www.cocoacontrols.com/controls/skeletonview)
- [Awesome iOS Newsletter #74](https://ios.libhunt.com/newsletter/74)
- [Swift News #36](https://www.youtube.com/watch?v=mAGpsQiy6so)
- [Best iOS articles, new tools & more](https://medium.com/flawless-app-stories/best-ios-articles-new-tools-more-fcbe673e10d)

## 🏆 Sponsors

Si te resulta útil, considera apoyar el proyecto via [GitHub Sponsors](https://github.com/sponsors/Juanpe) ❤️

## 👨🏻‍💻 Autor

[Juanpe Catalán](http://www.twitter.com/JuanpeCatalan)

## 👮🏻 Licencia

```
MIT License

Copyright (c) 2017 Juanpe Catalán

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
