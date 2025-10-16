## UITableView

Si quieres mostrar el skeleton en una `UITableView`, necesitas conformar con el protocolo `SkeletonTableViewDataSource`.

``` swift
public protocol SkeletonTableViewDataSource: UITableViewDataSource {
    func numSections(in collectionSkeletonView: UITableView) -> Int // Default: 1
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier
    func collectionSkeletonView(_ skeletonView: UITableView, skeletonCellForRowAt indexPath: IndexPath) -> UITableViewCell? // Default: nil
    func collectionSkeletonView(_ skeletonView: UITableView, prepareCellForSkeleton cell: UITableViewCell, at indexPath: IndexPath)
}
```

Como puedes ver, este protocolo hereda de `UITableViewDataSource`, así que puedes reemplazar este protocolo con el del skeleton.

Este protocolo tiene implementación por defecto para algunos métodos. Por ejemplo, el número de filas para cada sección se calcula en runtime:

``` swift
func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int
// Default:
// It calculates how many cells need to populate whole tableview
```

> 📣 **IMPORTANTE!** 

> Si devuelves `UITableView.automaticNumberOfSkeletonRows` en el método anterior, actúa como el comportamiento por defecto (es decir, calcula cuántas celdas se necesitan para poblar toda la tableview).

Hay solo un método que necesitas implementar para que Skeleton conozca el identificador de celda. Este método no tiene implementación por defecto:
 ``` swift
 func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
    return "CellIdentifier"
}
 ```
 
 Por defecto, la librería dequea las celdas de cada indexPath, pero también puedes hacer esto si quieres hacer algunos cambios antes de que aparezca el skeleton:
 ``` swift
 func collectionSkeletonView(_ skeletonView: UITableView, skeletonCellForRowAt indexPath: IndexPath) -> UITableViewCell? {
     let cell = skeletonView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath) as? Cell
     cell?.textField.isHidden = indexPath.row == 0
     return cell
 }
 ```
 
Si prefieres dejar la parte de deque a la librería puedes configurar la celda usando este método:
 ``` swift
 func collectionSkeletonView(_ skeletonView: UITableView, prepareCellForSkeleton cell: UITableViewCell, at indexPath: IndexPath) {
     let cell = cell as? Cell
     cell?.textField.isHidden = indexPath.row == 0
 }
 ```

 
Además, puedes esqueletizar tanto los headers como los footers. Necesitas conformar con `SkeletonTableViewDelegate`.

```swift
public protocol SkeletonTableViewDelegate: UITableViewDelegate {
    func collectionSkeletonView(_ skeletonView: UITableView, identifierForHeaderInSection section: Int) -> ReusableHeaderFooterIdentifier? // default: nil
    func collectionSkeletonView(_ skeletonView: UITableView, identifierForFooterInSection section: Int) -> ReusableHeaderFooterIdentifier? // default: nil
}
```

> 📣 **IMPORTANTE!** 
> 
> 1️⃣ Si usas celdas redimensionables (**`tableView.rowHeight = UITableViewAutomaticDimension`**), es obligatorio definir **`estimatedRowHeight`**.
> 
> 2️⃣ Cuando añades elementos en una **`UITableViewCell`** deberías añadirlos al **`contentView`** y no directamente a la celda.
> ```swift
> self.contentView.addSubview(titleLabel) ✅         
> self.addSubview(titleLabel) ❌
> ```

  

**UICollectionView**

Para `UICollectionView`, necesitas conformar con `SkeletonCollectionViewDataSource`.

``` swift
public protocol SkeletonCollectionViewDataSource: UICollectionViewDataSource {
    func numSections(in collectionSkeletonView: UICollectionView) -> Int  // default: 1
    func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> ReusableCellIdentifier
    func collectionSkeletonView(_ skeletonView: UICollectionView, supplementaryViewIdentifierOfKind: String, at indexPath: IndexPath) -> ReusableCellIdentifier? // default: nil
    func collectionSkeletonView(_ skeletonView: UICollectionView, skeletonCellForItemAt indexPath: IndexPath) -> UICollectionViewCell?  // default: nil
    func collectionSkeletonView(_ skeletonView: UICollectionView, prepareCellForSkeleton cell: UICollectionViewCell, at indexPath: IndexPath)
    func collectionSkeletonView(_ skeletonView: UICollectionView, prepareViewForSkeleton view: UICollectionReusableView, at indexPath: IndexPath)
}
```

El resto del proceso es el mismo que con `UITableView`.
