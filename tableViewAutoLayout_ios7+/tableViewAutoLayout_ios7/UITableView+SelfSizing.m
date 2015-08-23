//
//  UITableView+SelfSizing.m
//  SinaBlog
//
//  Created by Robin on 8/10/15.
//  Copyright © 2015 Robin. All rights reserved.
//

#import "UITableView+SelfSizing.h"
#import <objc/runtime.h>


@interface _SelfSizingCellHeightCache : NSObject
@property (nonatomic, strong) NSMutableArray *sections;
@end

static CGFloat const _SelfSizingCellHeightCacheAbsentValue = -1;

@implementation _SelfSizingCellHeightCache

- (void)buildHeightCachesAtIndexPathsIfNeeded:(NSArray *)indexPaths
{
    if (indexPaths.count == 0) {
        return;
    }
    
    if (!self.sections) {
        self.sections = @[].mutableCopy;
    }
    
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
        
        NSAssert(indexPath.section >= 0, @"Error negative section = '%@'.", @(indexPath.section));
        
        for (NSInteger section = 0; section <= indexPath.section; ++section) {
            if (section >= self.sections.count) {
                self.sections[section] = @[].mutableCopy;
            }
        }
        NSMutableArray *rows = self.sections[indexPath.section];
        for (NSInteger row = 0; row <= indexPath.row; ++row) {
            if (row >= rows.count) {
                rows[row] = @(_SelfSizingCellHeightCacheAbsentValue);
            }
        }
    }];
}

- (BOOL)hasCachedHeightAtIndexPath:(NSIndexPath *)indexPath
{
    [self buildHeightCachesAtIndexPathsIfNeeded:@[indexPath]];
    NSNumber *cachedNumber = self.sections[indexPath.section][indexPath.row];
    return ![cachedNumber isEqualToNumber:@(_SelfSizingCellHeightCacheAbsentValue)];
}

- (void)cacheHeight:(CGFloat)height byIndexPath:(NSIndexPath *)indexPath
{
    [self buildHeightCachesAtIndexPathsIfNeeded:@[indexPath]];
    self.sections[indexPath.section][indexPath.row] = @(height);
}

- (CGFloat)cachedHeightAtIndexPath:(NSIndexPath *)indexPath
{
    [self buildHeightCachesAtIndexPathsIfNeeded:@[indexPath]];
#if CGFLOAT_IS_DOUBLE
    return [self.sections[indexPath.section][indexPath.row] doubleValue];
#else
    return [self.sections[indexPath.section][indexPath.row] floatValue];
#endif
}

@end

@interface UITableView (SelfSizingPrivate)

@property (nonatomic, strong, readonly) _SelfSizingCellHeightCache *p_cellHeightCache;
@property (nonatomic, assign) BOOL p_autoCacheInvalidationEnabled;
@property (nonatomic, assign) BOOL p_precacheEnabled;

- (id)p_cellForReuseIdentifier:(NSString *)identifier;
- (void)p_precacheIfNeeded;

@end

@implementation UITableView (SelfSizingPrivate)

- (id)p_cellForReuseIdentifier:(NSString *)identifier
{
    NSAssert(identifier.length > 0, @"Expect a valid identifier - %@", identifier);
    
    NSMutableDictionary *templateCellsByIdentifiers = objc_getAssociatedObject(self, _cmd);
    if (!templateCellsByIdentifiers) {
        templateCellsByIdentifiers = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, templateCellsByIdentifiers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    UITableViewCell *templateCell = templateCellsByIdentifiers[identifier];
    
    if (!templateCell) {
        templateCell = [self dequeueReusableCellWithIdentifier:identifier];
        NSAssert(templateCell != nil, @"Cell must be registered to table view for identifier - %@", identifier);
        templateCell.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        templateCellsByIdentifiers[identifier] = templateCell;
    }
    
    return templateCell;
}


- (_SelfSizingCellHeightCache *)p_cellHeightCache
{
    _SelfSizingCellHeightCache *cache = objc_getAssociatedObject(self, _cmd);
    if (!cache) {
        cache = [_SelfSizingCellHeightCache new];
        objc_setAssociatedObject(self, _cmd, cache, OBJC_ASSOCIATION_RETAIN);
    }
    return cache;
}


- (BOOL)p_autoCacheInvalidationEnabled
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setP_autoCacheInvalidationEnabled:(BOOL)enabled
{
    objc_setAssociatedObject(self, @selector(p_autoCacheInvalidationEnabled), @(enabled), OBJC_ASSOCIATION_RETAIN);
}

- (void)p_precacheIfNeeded{
    
    if (!self.p_precacheEnabled) {
        return;
    }

    
    if (![self.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
        return;
    }
    
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFStringRef runLoopMode = kCFRunLoopDefaultMode;
    NSMutableArray *mutableIndexPathsToBePrecached = self.p_allIndexPathsToBePrecached.mutableCopy;
    
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler
    (kCFAllocatorDefault, kCFRunLoopBeforeWaiting, true, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity _) {

        if (mutableIndexPathsToBePrecached.count == 0) {
            CFRunLoopRemoveObserver(runLoop, observer, runLoopMode);
            CFRelease(observer);
            return;
        }

        NSIndexPath *indexPath = mutableIndexPathsToBePrecached.firstObject;
        [mutableIndexPathsToBePrecached removeObject:indexPath];
        
        [self performSelector:@selector(p_precacheIndexPath:)
                     onThread:[NSThread mainThread]
                   withObject:indexPath
                waitUntilDone:NO
                        modes:@[NSDefaultRunLoopMode]];
    });
    
    CFRunLoopAddObserver(runLoop, observer, runLoopMode);

}


- (void)p_precacheIndexPath:(NSIndexPath *)indexPath
{
    if ([self.p_cellHeightCache hasCachedHeightAtIndexPath:indexPath]) {
        return;
    }
    if (indexPath.section >= [self numberOfSections] ||
        indexPath.row >= [self numberOfRowsInSection:indexPath.section]) {
        return;
    }
    
    CGFloat height = [self.delegate tableView:self heightForRowAtIndexPath:indexPath];
    [self.p_cellHeightCache cacheHeight:height byIndexPath:indexPath];
}

- (NSArray *)p_allIndexPathsToBePrecached
{
    NSMutableArray *allIndexPaths = @[].mutableCopy;
    for (NSInteger section = 0; section < [self numberOfSections]; ++section) {
        for (NSInteger row = 0; row < [self numberOfRowsInSection:section]; ++row) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            if (![self.p_cellHeightCache hasCachedHeightAtIndexPath:indexPath]) {
                [allIndexPaths addObject:indexPath];
            }
        }
    }
    return allIndexPaths.copy;
}

- (BOOL)p_precacheEnabled
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setP_precacheEnabled:(BOOL)precacheEnabled
{
    objc_setAssociatedObject(self, @selector(p_precacheEnabled), @(precacheEnabled), OBJC_ASSOCIATION_RETAIN);
}

@end


@implementation UITableView (SelfSizingSwizzle)
+ (void)load
{
    SEL selectors[] = {
        @selector(reloadData),
        @selector(insertSections:withRowAnimation:),
        @selector(deleteSections:withRowAnimation:),
        @selector(reloadSections:withRowAnimation:),
        @selector(moveSection:toSection:),
        @selector(insertRowsAtIndexPaths:withRowAnimation:),
        @selector(deleteRowsAtIndexPaths:withRowAnimation:),
        @selector(reloadRowsAtIndexPaths:withRowAnimation:),
        @selector(moveRowAtIndexPath:toIndexPath:)
    };
    
    for (NSUInteger index = 0; index < sizeof(selectors) / sizeof(SEL); ++index) {
        SEL originalSelector = selectors[index];
        SEL swizzledSelector = NSSelectorFromString([@"s_" stringByAppendingString:NSStringFromSelector(originalSelector)]);
        
        Method originalMethod = class_getInstanceMethod(self, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
        
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}


- (void)s_reloadData
{
    if (self.p_autoCacheInvalidationEnabled) {
        [self.p_cellHeightCache.sections removeAllObjects];
    }
    [self s_reloadData]; // Primary call
    [self p_precacheIfNeeded];
}

- (void)s_insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation
{
    if (self.p_autoCacheInvalidationEnabled) {
        [sections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [self.p_cellHeightCache.sections insertObject:@[].mutableCopy atIndex:idx];
        }];
    }
    [self s_insertSections:sections withRowAnimation:animation]; // Primary call
    [self p_precacheIfNeeded];
}

- (void)s_deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation
{
    if (self.p_autoCacheInvalidationEnabled) {
        [sections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [self.p_cellHeightCache.sections removeObjectAtIndex:idx];
        }];
    }
    [self s_deleteSections:sections withRowAnimation:animation]; // Primary call
}

- (void)s_reloadSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation
{
    if (self.p_autoCacheInvalidationEnabled) {
        [sections enumerateIndexesUsingBlock: ^(NSUInteger idx, BOOL *stop) {
            if (idx < self.p_cellHeightCache.sections.count) {
                NSMutableArray *rows = self.p_cellHeightCache.sections[idx];
                for (NSInteger row = 0; row < rows.count; ++row) {
                    rows[row] = @(_SelfSizingCellHeightCacheAbsentValue);
                }
            }
        }];
    }
    [self s_reloadSections:sections withRowAnimation:animation]; // Primary call
    [self p_precacheIfNeeded];
}

- (void)s_moveSection:(NSInteger)section toSection:(NSInteger)newSection
{
    if (self.p_autoCacheInvalidationEnabled) {
        NSInteger sectionCount = self.p_cellHeightCache.sections.count;
        if (section < sectionCount && newSection < sectionCount) {
            [self.p_cellHeightCache.sections exchangeObjectAtIndex:section withObjectAtIndex:newSection];
        }
    }
    [self s_moveSection:section toSection:newSection]; // Primary call
}

- (void)s_insertRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
    if (self.p_autoCacheInvalidationEnabled) {
        [self.p_cellHeightCache buildHeightCachesAtIndexPathsIfNeeded:indexPaths];
        [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
            NSMutableArray *rows = self.p_cellHeightCache.sections[indexPath.section];
            [rows insertObject:@(_SelfSizingCellHeightCacheAbsentValue) atIndex:indexPath.row];
        }];
    }
    [self s_insertRowsAtIndexPaths:indexPaths withRowAnimation:animation]; // Primary call
    [self p_precacheIfNeeded];
}

- (void)s_deleteRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
    if (self.p_autoCacheInvalidationEnabled) {
        [self.p_cellHeightCache buildHeightCachesAtIndexPathsIfNeeded:indexPaths];
        
        NSMutableDictionary *mutableIndexSetsToRemove = @{}.mutableCopy;
        [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
            
            NSMutableIndexSet *mutableIndexSet = mutableIndexSetsToRemove[@(indexPath.section)];
            if (!mutableIndexSet) {
                mutableIndexSetsToRemove[@(indexPath.section)] = [NSMutableIndexSet indexSet];
            }
            
            [mutableIndexSet addIndex:indexPath.row];
        }];
        
        [mutableIndexSetsToRemove enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSIndexSet *indexSet, BOOL *stop) {
            NSMutableArray *rows = self.p_cellHeightCache.sections[key.integerValue];
            [rows removeObjectsAtIndexes:indexSet];
        }];
    }
    [self s_deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)s_reloadRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
    if (self.p_autoCacheInvalidationEnabled) {
        [self.p_cellHeightCache buildHeightCachesAtIndexPathsIfNeeded:indexPaths];
        [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
            NSMutableArray *rows = self.p_cellHeightCache.sections[indexPath.section];
            rows[indexPath.row] = @(_SelfSizingCellHeightCacheAbsentValue);
        }];
    }
    [self s_reloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    [self p_precacheIfNeeded];
}

- (void)s_moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    if (self.p_autoCacheInvalidationEnabled) {
        [self.p_cellHeightCache buildHeightCachesAtIndexPathsIfNeeded:@[sourceIndexPath, destinationIndexPath]];
        
        NSMutableArray *sourceRows = self.p_cellHeightCache.sections[sourceIndexPath.section];
        NSMutableArray *destinationRows = self.p_cellHeightCache.sections[destinationIndexPath.section];
        
        NSNumber *sourceValue = sourceRows[sourceIndexPath.row];
        NSNumber *destinationValue = destinationRows[destinationIndexPath.row];
        
        sourceRows[sourceIndexPath.row] = destinationValue;
        destinationRows[destinationIndexPath.row] = sourceValue;
    }
    [self s_moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath]; 
}


@end




@implementation UITableView (SelfSizing)

- (CGFloat)heightForCellWithIdentifier:(NSString *)identifier cacheByIndexPath:(NSIndexPath *)indexPath configuration:(void (^)(id))configuration
{
    if (!identifier || !indexPath) {
        return 0;
    }
    
    if (!self.p_autoCacheInvalidationEnabled) {
        self.p_autoCacheInvalidationEnabled = YES;
    }
    
    if (!self.p_precacheEnabled) {
        self.p_precacheEnabled = YES;
        [self p_precacheIfNeeded];
    }
    
    if ([self.p_cellHeightCache hasCachedHeightAtIndexPath:indexPath]) {
        return [self.p_cellHeightCache cachedHeightAtIndexPath:indexPath];
    }
    
    CGFloat height = [self heightForCellWithIdentifier:identifier configuration:configuration];
    [self.p_cellHeightCache cacheHeight:height byIndexPath:indexPath];
    return height;
}

- (CGFloat)heightForCellWithIdentifier:(NSString *)identifier configuration:(void (^)(id))configuration
{
    if (!identifier) {
        return 0;
    }
    
    UITableViewCell *cell = [self p_cellForReuseIdentifier:identifier];
    
    [cell prepareForReuse];
    
    if (configuration) {
        configuration(cell);
    }
    
    CGFloat contentViewWidth = CGRectGetWidth(self.frame);
    
    if (cell.accessoryView) {
        contentViewWidth -= 16 + CGRectGetWidth(cell.accessoryView.frame);
    } else {
        static CGFloat systemAccessoryWidths[] = {
            [UITableViewCellAccessoryNone] = 0,
            [UITableViewCellAccessoryDisclosureIndicator] = 34,
            [UITableViewCellAccessoryDetailDisclosureButton] = 68,
            [UITableViewCellAccessoryCheckmark] = 40,
            [UITableViewCellAccessoryDetailButton] = 48
        };
        contentViewWidth -= systemAccessoryWidths[cell.accessoryType];
    }
    
    CGSize fittingSize = CGSizeZero;
    
    NSLayoutConstraint *tempWidthConstraint =
    [NSLayoutConstraint constraintWithItem:cell.contentView
                                 attribute:NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:1.0
                                  constant:contentViewWidth];
    [cell.contentView addConstraint:tempWidthConstraint];
    
    fittingSize = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    [cell.contentView removeConstraint:tempWidthConstraint];
    
    if (self.separatorStyle != UITableViewCellSeparatorStyleNone) {
        fittingSize.height += 1.0 / [UIScreen mainScreen].scale;
    }
    
    return fittingSize.height;
}

@end

