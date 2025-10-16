import XCTest
@testable import SkeletonView
import UIKit

@available(iOS 13.0, *)
final class DiffableSkeletonTests: XCTestCase {
    enum Section: Hashable { case main }
    struct Row: Hashable { let id = UUID() }
    struct Item: Hashable { let id = UUID() }

    func testTableInlineDoesNotInstallDummy() {
        let tableView = UITableView(frame: .init(x: 0, y: 0, width: 320, height: 480))
        tableView.isSkeletonable = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        let ds = tableView.makeSkeletonDiffableDataSource(placeholderRows: 3, useInlinePlaceholders: true) { tv, indexPath, row in
            let cell = tv.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.isSkeletonable = true
            return cell
        }
        tableView.beginSkeletonLoading()
        // Llamar explícitamente para simular overlay (no recomendado inline) y comprobar que NO substituye
        tableView.showAnimatedSkeleton()
        XCTAssertTrue(tableView.dataSource === ds, "Inline placeholders no debería instalar dummy data source")
    }

    func testCollectionOverlayInstallsDummy() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 50, height: 50)
        let collectionView = UICollectionView(frame: .init(x: 0, y: 0, width: 320, height: 480), collectionViewLayout: layout)
        collectionView.isSkeletonable = true
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        let cds = collectionView.makeSkeletonDiffableDataSource(placeholderItems: 4, useInlinePlaceholders: false) { cv, indexPath, item in
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
            cell.isSkeletonable = true
            return cell
        }
        collectionView.showAnimatedSkeleton()
        XCTAssertFalse(collectionView.dataSource === cds, "Overlay clásico debería instalar dummy data source")
    }

    func testCollectionSnapshotReassignsDataSourceAfterDummy() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 50, height: 50)
        let collectionView = UICollectionView(frame: .init(x: 0, y: 0, width: 320, height: 480), collectionViewLayout: layout)
        collectionView.isSkeletonable = true
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        let cds = collectionView.makeSkeletonDiffableDataSource(placeholderItems: 2, useInlinePlaceholders: false) { cv, indexPath, item in
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
            cell.isSkeletonable = true
            return cell
        }
        collectionView.showAnimatedSkeleton()
        // Ahora aplicar snapshot real
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems([Item(), Item()])
        cds.endLoadingAndApply(snapshot, animatingDifferences: false)
        XCTAssertTrue(collectionView.dataSource === cds, "Después de aplicar snapshot debe restaurarse el diffable data source")
    }
}
