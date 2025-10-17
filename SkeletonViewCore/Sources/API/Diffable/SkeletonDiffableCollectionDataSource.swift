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
public protocol SkeletonDiffableCollectionViewDataSourceDelegate: AnyObject {
    func skeletonDiffableDataSourceNumberOfSections(_ dataSource: Any, in collectionView: UICollectionView) -> Int
    func skeletonDiffableDataSource(_ dataSource: Any, numberOfPlaceholderItemsIn section: Int, in collectionView: UICollectionView) -> Int
    func skeletonDiffableDataSource(_ dataSource: Any, cellIdentifierForPlaceholderAt indexPath: IndexPath, in collectionView: UICollectionView) -> ReusableCellIdentifier
    func skeletonDiffableDataSource(_ dataSource: Any, supplementaryViewIdentifierOfKind kind: String, at indexPath: IndexPath, in collectionView: UICollectionView) -> ReusableCellIdentifier?
    func skeletonDiffableDataSource(_ dataSource: Any, skeletonCellForItemAt indexPath: IndexPath, in collectionView: UICollectionView) -> UICollectionViewCell?
    func skeletonDiffableDataSource(_ dataSource: Any, configurePlaceholderCell cell: UICollectionViewCell, at indexPath: IndexPath, in collectionView: UICollectionView)
    func skeletonDiffableDataSource(_ dataSource: Any, prepareCellForSkeleton cell: UICollectionViewCell, at indexPath: IndexPath, in collectionView: UICollectionView)
    func skeletonDiffableDataSource(_ dataSource: Any, prepareViewForSkeleton view: UICollectionReusableView, at indexPath: IndexPath, in collectionView: UICollectionView)
}

@available(iOS 13.0, tvOS 13.0, *)
public extension SkeletonDiffableCollectionViewDataSourceDelegate {
    func skeletonDiffableDataSourceNumberOfSections(_ dataSource: Any, in collectionView: UICollectionView) -> Int { 1 }
    func skeletonDiffableDataSource(_ dataSource: Any, numberOfPlaceholderItemsIn section: Int, in collectionView: UICollectionView) -> Int { UICollectionView.automaticNumberOfSkeletonItems }
    func skeletonDiffableDataSource(_ dataSource: Any, cellIdentifierForPlaceholderAt indexPath: IndexPath, in collectionView: UICollectionView) -> ReusableCellIdentifier { "Cell" }
    func skeletonDiffableDataSource(_ dataSource: Any, supplementaryViewIdentifierOfKind kind: String, at indexPath: IndexPath, in collectionView: UICollectionView) -> ReusableCellIdentifier? { nil }
    func skeletonDiffableDataSource(_ dataSource: Any, skeletonCellForItemAt indexPath: IndexPath, in collectionView: UICollectionView) -> UICollectionViewCell? { nil }
    func skeletonDiffableDataSource(_ dataSource: Any, configurePlaceholderCell cell: UICollectionViewCell, at indexPath: IndexPath, in collectionView: UICollectionView) { }
    func skeletonDiffableDataSource(_ dataSource: Any, prepareCellForSkeleton cell: UICollectionViewCell, at indexPath: IndexPath, in collectionView: UICollectionView) { }
    func skeletonDiffableDataSource(_ dataSource: Any, prepareViewForSkeleton view: UICollectionReusableView, at indexPath: IndexPath, in collectionView: UICollectionView) { }
}

@available(iOS 13.0, tvOS 13.0, *)
public protocol AnySkeletonDiffableCollectionDataSource: SkeletonCollectionViewDataSource {}

@available(iOS 13.0, tvOS 13.0, *)
public final class SkeletonDiffableCollectionViewDataSource<SectionID: Hashable, ItemID: Hashable>: UICollectionViewDiffableDataSource<SectionID, ItemID>, SkeletonCollectionViewDataSource, AnySkeletonDiffableCollectionDataSource {
    /// Indicates whether the collection is currently in loading state (skeleton visible or inline placeholders).
    public private(set) var isLoading: Bool = false
    /// Number of inline placeholder items when using inline placeholders instead of relying only on the skeleton dummy data source.
    private var placeholderItemCount: Int
    /// Toggle to enable inline placeholder items while loading and the diffable snapshot is empty.
    private let useInlinePlaceholders: Bool
    /// Weak reference to avoid ambiguity with superclass API "collectionView" symbol.
    private weak var hostCollectionViewRef: UICollectionView?
    /// Delegate to customize skeleton behavior.
    public weak var skeletonDelegate: SkeletonDiffableCollectionViewDataSourceDelegate?
    /// Optional sentinel section to prevent crashes in layouts that do not tolerate 0 sections (iOS 18 enforces this more strictly).
    private var sentinelSection: SectionID?
    /// Optional closure to dynamically generate a sentinel section if one was not explicitly configured.
    private var sentinelProvider: (() -> SectionID)?
    /// When true, if the snapshot is empty it reuses previous sections from the last known snapshot before adding a sentinel.
    public var autoPreservePreviousSectionsOnEmptySnapshot: Bool = true
    /// Configure a sentinel section that will be added if the snapshot is empty and the layout does not accept 0 sections.
    public func configureSentinelSection(_ section: SectionID) { sentinelSection = section }
    /// Configure a dynamic provider for a sentinel section.
    public func configureAutoSentinel(using provider: @escaping () -> SectionID) { sentinelProvider = provider }
    // Added properties to control re-entrancy of applySnapshot
    private var isApplyingDiffable: Bool = false
    private var pendingSnapshot: NSDiffableDataSourceSnapshot<SectionID, ItemID>?

    /// Modo inline placeholders activo? Expuesto para lógica que evita instalar dummy data source.
    public var usesInlinePlaceholders: Bool { useInlinePlaceholders }

    // MARK: - Init
    public init(collectionView hostCollectionView: UICollectionView,
                placeholderItemCount: Int = 30,
                useInlinePlaceholders: Bool = false,
                cellProvider: @escaping UICollectionViewDiffableDataSource<SectionID, ItemID>.CellProvider,
                supplementaryViewProvider: SupplementaryViewProvider? = nil,
                skeletonDelegate: SkeletonDiffableCollectionViewDataSourceDelegate? = nil) {
        self.placeholderItemCount = placeholderItemCount
        self.useInlinePlaceholders = useInlinePlaceholders
        self.hostCollectionViewRef = hostCollectionView
        self.skeletonDelegate = skeletonDelegate
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
                apply(empty, animatingDifferences: true)
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
        // Re-entry: queue the latest snapshot and exit.
        if isApplyingDiffable {
            pendingSnapshot = snapshot
            return
        }
        isApplyingDiffable = true
        let work = { [weak self] in
            guard let self = self else { return }
            if let cv = self.hostCollectionViewRef, cv.dataSource !== self { cv.dataSource = self }
            var finalSnapshot = snapshot
            let hadItemsNoSections = finalSnapshot.numberOfItems > 0 && finalSnapshot.sectionIdentifiers.isEmpty
            if hadItemsNoSections {
                if let section = self.sentinelSection ?? self.sentinelProvider?() ?? self.snapshot().sectionIdentifiers.first {
                    var rebuilt = NSDiffableDataSourceSnapshot<SectionID, ItemID>()
                    rebuilt.appendSections([section])
                    rebuilt.appendItems(finalSnapshot.itemIdentifiers, toSection: section)
                    finalSnapshot = rebuilt
                } else {
                    // No valid section -> discard items to avoid inconsistent state.
                    #if DEBUG
                    print("[SkeletonDiffable] Dropping items without section. Applying empty snapshot to avoid crash.")
                    #endif
                    finalSnapshot = NSDiffableDataSourceSnapshot<SectionID, ItemID>()
                }
            }
            if finalSnapshot.sectionIdentifiers.isEmpty && finalSnapshot.numberOfItems == 0 && self.layoutRequiresAtLeastOneSection() {
                if let sentinel = self.sentinelSection ?? self.sentinelProvider?() {
                    finalSnapshot.appendSections([sentinel])
                } else if self.autoPreservePreviousSectionsOnEmptySnapshot {
                    let previousSections = self.snapshot().sectionIdentifiers
                    if !previousSections.isEmpty { finalSnapshot.appendSections(previousSections) }
                }
            }
            self.apply(finalSnapshot, animatingDifferences: animatingDifferences) { [weak self] in
                guard let self = self else { return }
                let isEmpty = finalSnapshot.numberOfItems == 0
                if self.isLoading && !isEmpty { self.isLoading = false }
                // Move hideSkeleton outside diffable's internal lock.
                if !self.isLoading {
                    DispatchQueue.main.async { [weak self] in
                        self?.hostCollectionViewRef?.hideSkeleton(reloadDataAfter: false)
                    }
                }
                self.isApplyingDiffable = false
                if let next = self.pendingSnapshot {
                    self.pendingSnapshot = nil
                    // Apply next without animation to avoid visual cascade.
                    self.applySnapshot(next, animatingDifferences: true, completion: completion)
                } else {
                    completion?()
                }
            }
        }
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }

    // MARK: - Inline placeholder support
    // Inline placeholders provide lightweight cells while loading WITHOUT swapping to SkeletonView's internal dummy data source.
    // This lets diffable preserve section structure (useful for compositional layouts) and still show shimmer.
    // Enable via `useInlinePlaceholders: true` and optionally customize with `skeletonDelegate`.
    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if useInlinePlaceholders && isLoading && snapshot().numberOfItems == 0 {
            // Ask delegate first for number of placeholder items.
            let delegatedCount = skeletonDelegate?.skeletonDiffableDataSource(self, numberOfPlaceholderItemsIn: section, in: collectionView)
            return delegatedCount ?? placeholderItemCount
        }
        return super.collectionView(collectionView, numberOfItemsInSection: section)
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if useInlinePlaceholders && isLoading && snapshot().numberOfItems == 0 {
            let identifier = skeletonDelegate?.skeletonDiffableDataSource(self, cellIdentifierForPlaceholderAt: indexPath, in: collectionView) ?? "SkeletonPlaceholderCell"
            var cell: UICollectionViewCell
            if identifier == "SkeletonPlaceholderCell" {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
            } else {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
            }
            if let delegate = skeletonDelegate {
                delegate.skeletonDiffableDataSource(self, configurePlaceholderCell: cell, at: indexPath, in: collectionView)
            } else {
                cell.isSkeletonable = true
            }
            return cell
        }
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    // MARK: - SkeletonCollectionViewDataSource
    public func numSections(in collectionSkeletonView: UICollectionView) -> Int {
        skeletonDelegate?.skeletonDiffableDataSourceNumberOfSections(self, in: collectionSkeletonView) ?? 1
    }
    
    public func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        skeletonDelegate?.skeletonDiffableDataSource(self, numberOfPlaceholderItemsIn: section, in: skeletonView) ?? placeholderItemCount
    }
    
    public func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> ReusableCellIdentifier {
        skeletonDelegate?.skeletonDiffableDataSource(self, cellIdentifierForPlaceholderAt: indexPath, in: skeletonView) ?? "Cell"
    }
    
    public func collectionSkeletonView(_ skeletonView: UICollectionView, supplementaryViewIdentifierOfKind kind: String, at indexPath: IndexPath) -> ReusableCellIdentifier? {
        skeletonDelegate?.skeletonDiffableDataSource(self, supplementaryViewIdentifierOfKind: kind, at: indexPath, in: skeletonView)
    }
    
    public func collectionSkeletonView(_ skeletonView: UICollectionView, skeletonCellForItemAt indexPath: IndexPath) -> UICollectionViewCell? {
        skeletonDelegate?.skeletonDiffableDataSource(self, skeletonCellForItemAt: indexPath, in: skeletonView)
    }
    
    public func collectionSkeletonView(_ skeletonView: UICollectionView, prepareCellForSkeleton cell: UICollectionViewCell, at indexPath: IndexPath) {
        skeletonDelegate?.skeletonDiffableDataSource(self, prepareCellForSkeleton: cell, at: indexPath, in: skeletonView)
    }
    
    public func collectionSkeletonView(_ skeletonView: UICollectionView, prepareViewForSkeleton view: UICollectionReusableView, at indexPath: IndexPath) {
        skeletonDelegate?.skeletonDiffableDataSource(self, prepareViewForSkeleton: view, at: indexPath, in: skeletonView)
    }

    /// Determina si el layout actual requiere al menos una sección para evitar crash en snapshots vacíos (principalmente compositional layouts en iOS 18+).
    private func layoutRequiresAtLeastOneSection() -> Bool {
        guard let cv = hostCollectionViewRef else { return false }
        // Compositional layouts are the most strict. Add more types here if needed later.
        return cv.collectionViewLayout is UICollectionViewCompositionalLayout
    }
}

@available(iOS 13.0, tvOS 13.0, *)
public extension UICollectionView {
    /// Convenience factory returning a diffable data source integrated with SkeletonView.
    func makeSkeletonDiffableDataSource<SectionID: Hashable, ItemID: Hashable>(
            placeholderItems: Int = 8,
            useInlinePlaceholders: Bool = false,
            cellProvider: @escaping UICollectionViewDiffableDataSource<SectionID, ItemID>.CellProvider,
            supplementaryViewProvider: UICollectionViewDiffableDataSource.SupplementaryViewProvider? = nil,
            skeletonDelegate: SkeletonDiffableCollectionViewDataSourceDelegate? = nil) -> SkeletonDiffableCollectionViewDataSource<SectionID, ItemID> {
        let ds = SkeletonDiffableCollectionViewDataSource<SectionID, ItemID>(collectionView: self,
                                                                             placeholderItemCount: placeholderItems,
                                                                             useInlinePlaceholders: useInlinePlaceholders,
                                                                             cellProvider: cellProvider,
                                                                             supplementaryViewProvider: supplementaryViewProvider,
                                                                             skeletonDelegate: skeletonDelegate)
        self.dataSource = ds
        return ds
    }
    
    /// Factory that auto-configures a sentinel section if SectionID supports string literal initialization and the layout is compositional.
    @available(iOS 13.0, tvOS 13.0, *)
    func makeAutoSkeletonDiffableDataSource<SectionID: Hashable & ExpressibleByStringLiteral, ItemID: Hashable>(
        placeholderItems: Int = 8,
        useInlinePlaceholders: Bool = false,
        cellProvider: @escaping UICollectionViewDiffableDataSource<SectionID, ItemID>.CellProvider,
        supplementaryViewProvider: UICollectionViewDiffableDataSource<SectionID, ItemID>.SupplementaryViewProvider? = nil,
        skeletonDelegate: SkeletonDiffableCollectionViewDataSourceDelegate? = nil
    ) -> SkeletonDiffableCollectionViewDataSource<SectionID, ItemID> {
        let ds = SkeletonDiffableCollectionViewDataSource<SectionID, ItemID>(collectionView: self,
                                                                             placeholderItemCount: placeholderItems,
                                                                             useInlinePlaceholders: useInlinePlaceholders,
                                                                             cellProvider: cellProvider,
                                                                             supplementaryViewProvider: supplementaryViewProvider,
                                                                             skeletonDelegate: skeletonDelegate)
        self.dataSource = ds
        if self.collectionViewLayout is UICollectionViewCompositionalLayout {
            ds.configureSentinelSection("SkeletonAutoSentinel")
        }
        return ds
    }

    /// Factory that enables automatic preservation of previous sections on empty snapshots.
    @available(iOS 13.0, tvOS 13.0, *)
    func makeSkeletonDiffableDataSourceWithAutoPreserve<SectionID: Hashable, ItemID: Hashable>(
        placeholderItems: Int = 8,
        useInlinePlaceholders: Bool = false,
        cellProvider: @escaping UICollectionViewDiffableDataSource<SectionID, ItemID>.CellProvider,
        supplementaryViewProvider: UICollectionViewDiffableDataSource<SectionID, ItemID>.SupplementaryViewProvider? = nil,
        skeletonDelegate: SkeletonDiffableCollectionViewDataSourceDelegate? = nil
    ) -> SkeletonDiffableCollectionViewDataSource<SectionID, ItemID> {
        let ds = SkeletonDiffableCollectionViewDataSource<SectionID, ItemID>(collectionView: self,
                                                                             placeholderItemCount: placeholderItems,
                                                                             useInlinePlaceholders: useInlinePlaceholders,
                                                                             cellProvider: cellProvider,
                                                                             supplementaryViewProvider: supplementaryViewProvider,
                                                                             skeletonDelegate: skeletonDelegate)
        self.dataSource = ds
        ds.autoPreservePreviousSectionsOnEmptySnapshot = true
        return ds
    }

    /// Factory that sets a dynamic provider to generate a sentinel section if the snapshot is empty in a compositional layout.
    @available(iOS 13.0, tvOS 13.0, *)
    func makeSkeletonDiffableDataSourceWithDynamicSentinel<SectionID: Hashable, ItemID: Hashable>(
        placeholderItems: Int = 8,
        useInlinePlaceholders: Bool = false,
        dynamicSentinel: @escaping () -> SectionID,
        cellProvider: @escaping UICollectionViewDiffableDataSource<SectionID, ItemID>.CellProvider,
        supplementaryViewProvider: UICollectionViewDiffableDataSource<SectionID, ItemID>.SupplementaryViewProvider? = nil,
        skeletonDelegate: SkeletonDiffableCollectionViewDataSourceDelegate? = nil
    ) -> SkeletonDiffableCollectionViewDataSource<SectionID, ItemID> {
        let ds = SkeletonDiffableCollectionViewDataSource<SectionID, ItemID>(collectionView: self,
                                                                             placeholderItemCount: placeholderItems,
                                                                             useInlinePlaceholders: useInlinePlaceholders,
                                                                             cellProvider: cellProvider,
                                                                             supplementaryViewProvider: supplementaryViewProvider,
                                                                             skeletonDelegate: skeletonDelegate)
        self.dataSource = ds
        if self.collectionViewLayout is UICollectionViewCompositionalLayout {
            ds.configureAutoSentinel(using: dynamicSentinel)
        }
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
}

#endif
