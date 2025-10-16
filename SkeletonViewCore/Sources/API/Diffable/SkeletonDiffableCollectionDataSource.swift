//  SkeletonDiffableCollectionDataSource.swift
//  SkeletonView
//
//  Created for Diffable Data Source support (UICollectionView).
//
//  This mirrors the table view diffable integration, orchestrating the SkeletonView lifecycle
//  with UICollectionViewDiffableDataSource snapshots.
//
//  Usage sample:
//  enum Section: Hashable { case main }
//  struct Item: Hashable { let id = UUID(); let title: String }
//  collectionView.isSkeletonable = true
//  let ds = collectionView.makeSkeletonDiffableDataSource { collectionView, indexPath, item in
//      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
//      cell.isSkeletonable = true
//      return cell
//  }
//  ds.beginLoading()
//  // After fetch: build snapshot and call ds.endLoadingAndApply(snapshot)
//
#if canImport(UIKit)
import UIKit

@available(iOS 13.0, tvOS 13.0, *)
public final class SkeletonDiffableCollectionViewDataSource<SectionID: Hashable, ItemID: Hashable>: UICollectionViewDiffableDataSource<SectionID, ItemID>, SkeletonCollectionViewDataSource {
    // Indicates whether the collection is currently in loading state (skeleton visible).
    public private(set) var isLoading: Bool = false
    // Number of inline placeholder items when using inline placeholders instead of relying solely on the skeleton dummy datasource.
    private var placeholderItemCount: Int
    // Configuration closure for each placeholder cell (only used if useInlinePlaceholders == true).
    public var configurePlaceholderCell: ((UICollectionView, IndexPath) -> UICollectionViewCell)?
    // Toggle to enable inline placeholder items while loading and diffable snapshot is empty.
    private let useInlinePlaceholders: Bool
    // Weak reference to avoid ambiguity with superclass API "collectionView" symbol.
    private weak var hostCollectionViewRef: UICollectionView?

    // MARK: - Init
    public init(collectionView hostCollectionView: UICollectionView,
                placeholderItemCount: Int = 8,
                useInlinePlaceholders: Bool = false,
                cellProvider: @escaping UICollectionViewDiffableDataSource<SectionID, ItemID>.CellProvider,
                supplementaryViewProvider: SupplementaryViewProvider? = nil) {
        self.placeholderItemCount = placeholderItemCount
        self.useInlinePlaceholders = useInlinePlaceholders
        self.hostCollectionViewRef = hostCollectionView
        super.init(collectionView: hostCollectionView, cellProvider: cellProvider)
        if useInlinePlaceholders {
            hostCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonPlaceholderCell")
        }
        self.supplementaryViewProvider = supplementaryViewProvider
    }

    // MARK: - Loading lifecycle

    /// Starts loading mode and optionally shows skeleton.
    /// - Parameter showSkeleton: When true, shows skeleton automatically. Safe for diffable datasources.
    public func beginLoading(showSkeleton: Bool = true) {
        guard !isLoading else { return }
        isLoading = true
        
        // Show skeleton if requested - safe for diffable datasources since we maintain the same dataSource
        if showSkeleton {
            if useInlinePlaceholders {
                // For inline placeholders, we just need to reload to show placeholder cells
                let empty = NSDiffableDataSourceSnapshot<SectionID, ItemID>()
                apply(empty, animatingDifferences: false)
            } else {
                // For traditional skeleton overlay, show it directly
                hostCollectionViewRef?.showAnimatedSkeleton()
            }
        }
    }

    /// Marks loading as finished (does not hide skeleton until a snapshot is applied or explicitly calling hide on the view).
    public func endLoading() { isLoading = false }

    /// Convenience: end loading and apply snapshot in one step.
    public func endLoadingAndApply(_ snapshot: NSDiffableDataSourceSnapshot<SectionID, ItemID>,
                                   animatingDifferences: Bool = true,
                                   completion: (() -> Void)? = nil) {
        endLoading()
        applySnapshot(snapshot, animatingDifferences: animatingDifferences, completion: completion)
    }

    /// Resets into a fresh loading state, optionally preserving current section identifiers and showing skeleton again.
    /// Use when you need to replay a loading cycle (e.g. pull‑to‑refresh with full skeleton experience).
    /// - Parameters:
    ///   - keepSections: Preserve existing sections (empties their items) so layout metrics remain stable.
    ///   - showSkeleton: Show skeleton immediately (default true).
    ///   - animatingDifferences: Animate transition to the empty snapshot (default false to avoid flicker).
    public func resetAndShowSkeleton(keepSections: Bool = true,
                                     showSkeleton: Bool = true,
                                     animatingDifferences: Bool = false) {
        let performReset = { [weak self] in
            guard let self = self else { return }
            self.isLoading = true
            if showSkeleton { self.hostCollectionViewRef?.showAnimatedSkeleton() }
            var empty = NSDiffableDataSourceSnapshot<SectionID, ItemID>()
            if keepSections {
                let sections = self.snapshot().sectionIdentifiers
                if !sections.isEmpty { empty.appendSections(sections) }
            }
            self.applySnapshot(empty, animatingDifferences: animatingDifferences)
        }
        if Thread.isMainThread { performReset() } else { DispatchQueue.main.async(execute: performReset) }
    }

    /// Applies snapshot and coordinates skeleton visibility.
    public func applySnapshot(_ snapshot: NSDiffableDataSourceSnapshot<SectionID, ItemID>,
                              animatingDifferences: Bool = true,
                              completion: (() -> Void)? = nil) {
        let work = { [weak self] in
            guard let self = self else { return }
            self.apply(snapshot, animatingDifferences: animatingDifferences) { [weak self] in
                guard let self = self else { return }
                let isEmpty = snapshot.numberOfItems == 0
                if self.isLoading && !isEmpty { self.isLoading = false }
                if !self.isLoading { self.hostCollectionViewRef?.hideSkeleton(reloadDataAfter: false, transition: .crossDissolve(0.15)) }
                completion?()
            }
        }
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }

    // MARK: - Inline placeholder support
    // Inline placeholders provide lightweight cells while loading WITHOUT swapping to SkeletonView's internal dummy data source.
    // This lets diffable preserve section structure (useful for compositional layouts) and still show shimmer.
    // Enable via `useInlinePlaceholders: true` and optionally customize with `configurePlaceholderCell`.
    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if useInlinePlaceholders && isLoading && snapshot().numberOfItems == 0 { return placeholderItemCount }
        return super.collectionView(collectionView, numberOfItemsInSection: section)
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if useInlinePlaceholders && isLoading && snapshot().numberOfItems == 0 {
            if let configured = configurePlaceholderCell?(collectionView, indexPath) { return configured }
            // Fallback generic registered cell (registered in init when inline placeholders enabled).
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonPlaceholderCell", for: indexPath)
            cell.isSkeletonable = true
            return cell
        }
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    // MARK: - SkeletonCollectionViewDataSource
    public func numSections(in collectionSkeletonView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return placeholderItemCount
    }
    
    public func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> ReusableCellIdentifier {
        // Return the first registered cell identifier from the real cell provider
        // For now, we'll use a default identifier that should be registered
        return "Cell"
    }
}

@available(iOS 13.0, tvOS 13.0, *)
public extension UICollectionView {
    /// Convenience factory returning a diffable data source integrated with SkeletonView.
    func skeletonDiffableDataSource<SectionID: Hashable, ItemID: Hashable>(
        placeholderItems: Int = 8,
        useInlinePlaceholders: Bool = false,
        cellProvider: @escaping UICollectionViewDiffableDataSource<SectionID, ItemID>.CellProvider,
        supplementaryViewProvider: UICollectionViewDiffableDataSource.SupplementaryViewProvider? = nil) -> SkeletonDiffableCollectionViewDataSource<SectionID, ItemID> {
        let ds = SkeletonDiffableCollectionViewDataSource<SectionID, ItemID>(collectionView: self,
                                                                             placeholderItemCount: placeholderItems,
                                                                             useInlinePlaceholders: useInlinePlaceholders,
                                                                             cellProvider: cellProvider,
                                                                             supplementaryViewProvider: supplementaryViewProvider)
        self.dataSource = ds
        return ds
    }
    
    // MARK: - Convenient Skeleton Diffable Methods
    
    /// Starts loading and shows skeleton if the current dataSource is a SkeletonDiffableCollectionViewDataSource
    /// - Parameter showSkeleton: Whether to show the skeleton automatically (default: true)
    /// - Returns: true if operation was successful, false if dataSource is not a skeleton diffable dataSource
    @discardableResult
    func beginSkeletonLoading(showSkeleton: Bool = true) -> Bool {
        guard let skeletonDataSource = dataSource as? SkeletonDiffableCollectionViewDataSource<AnyHashable, AnyHashable> else {
            return false
        }
        skeletonDataSource.beginLoading(showSkeleton: showSkeleton)
        return true
    }
    
    /// Ends loading if the current dataSource is a SkeletonDiffableCollectionViewDataSource
    /// - Returns: true if operation was successful, false if dataSource is not a skeleton diffable dataSource
    @discardableResult
    func endSkeletonLoading() -> Bool {
        guard let skeletonDataSource = dataSource as? SkeletonDiffableCollectionViewDataSource<AnyHashable, AnyHashable> else {
            return false
        }
        skeletonDataSource.endLoading()
        return true
    }
    
    /// Ends loading and applies snapshot if the current dataSource is a SkeletonDiffableCollectionViewDataSource
    /// - Parameters:
    ///   - snapshot: The snapshot to apply
    ///   - animatingDifferences: Whether to animate the changes
    ///   - completion: Completion closure
    /// - Returns: true if operation was successful, false if dataSource is not a skeleton diffable dataSource
    @discardableResult
    func endSkeletonLoadingAndApply<SectionID: Hashable, ItemID: Hashable>(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionID, ItemID>,
        animatingDifferences: Bool = true,
        completion: (() -> Void)? = nil) -> Bool {
        
        guard let skeletonDataSource = dataSource as? SkeletonDiffableCollectionViewDataSource<SectionID, ItemID> else {
            return false
        }
        skeletonDataSource.endLoadingAndApply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
        return true
    }
    
    /// Resets and shows skeleton if the current dataSource is a SkeletonDiffableCollectionViewDataSource
    /// - Parameters:
    ///   - keepSections: Whether to preserve existing sections
    ///   - showSkeleton: Whether to show skeleton immediately
    ///   - animatingDifferences: Whether to animate the transition
    /// - Returns: true if operation was successful, false if dataSource is not a skeleton diffable dataSource
    @discardableResult
    func resetAndShowSkeleton(keepSections: Bool = true,
                             showSkeleton: Bool = true,
                             animatingDifferences: Bool = false) -> Bool {
        guard let skeletonDataSource = dataSource as? SkeletonDiffableCollectionViewDataSource<AnyHashable, AnyHashable> else {
            return false
        }
        skeletonDataSource.resetAndShowSkeleton(keepSections: keepSections,
                                               showSkeleton: showSkeleton,
                                               animatingDifferences: animatingDifferences)
        return true
    }
    
    /// Checks if the current dataSource is in loading state
    var isSkeletonLoading: Bool {
        guard let skeletonDataSource = dataSource as? SkeletonDiffableCollectionViewDataSource<AnyHashable, AnyHashable> else {
            return false
        }
        return skeletonDataSource.isLoading
    }
    
    /// Alias de conveniencia para mantener coherencia con UITableView y ejemplos/documentación.
    /// Internamente delega en `skeletonDiffableDataSource`.
    /// - Parameters:
    ///   - placeholderItems: Número de items placeholder cuando `useInlinePlaceholders` es true.
    ///   - useInlinePlaceholders: Activa placeholders inline (no intercambia al dataSource dummy interno).
    ///   - cellProvider: Proveedor de celdas diffable.
    ///   - supplementaryViewProvider: Proveedor opcional de supplementary views.
    /// - Returns: SkeletonDiffableCollectionViewDataSource configurado y asignado como dataSource.
    @discardableResult
    func makeSkeletonDiffableDataSource<SectionID: Hashable, ItemID: Hashable>(
        placeholderItems: Int = 8,
        useInlinePlaceholders: Bool = false,
        cellProvider: @escaping UICollectionViewDiffableDataSource<SectionID, ItemID>.CellProvider,
        supplementaryViewProvider: UICollectionViewDiffableDataSource<SectionID, ItemID>.SupplementaryViewProvider? = nil
    ) -> SkeletonDiffableCollectionViewDataSource<SectionID, ItemID> {
        return skeletonDiffableDataSource(placeholderItems: placeholderItems,
                                          useInlinePlaceholders: useInlinePlaceholders,
                                          cellProvider: cellProvider,
                                          supplementaryViewProvider: supplementaryViewProvider)
    }
}

#endif
