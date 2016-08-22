//
//  BADatePickerView.h
//  BADatePickerView
//
//  Created by ALLARD Benjamin on 16/08/16.

// /!\ WARNING DO NOT SET THE UIPickerViewDataSource AND THE UIPickerViewDelegate. It's use in internal, so if you set it, the BADatePickerView will not work correctly.
//

#import <UIKit/UIKit.h>

@protocol BADatePickerViewDelegate <NSObject>
@optional
- (void) dateValueChange:(NSDate *)newDate;
@end

@interface BADatePickerView : UIPickerView <UIPickerViewDataSource, UIPickerViewDelegate>

@property NSInteger numberOfYearFromNow;
@property (nonatomic) NSUInteger periodicity;
@property (nonatomic) NSDate * startDate;
@property (nonatomic, assign) id<BADatePickerViewDelegate> baDatePickerViewDelegate;


/**
 *  Initialize picker view
 */
-(void)initializeWithNumberOfYears:(NSInteger)numberOfYears startedDate:(NSDate *) startedDate;

/**
 *  Initialize picker view with a periodicity
 */
-(void)initializeWithPeriodicity:(NSUInteger)periodicity numberOfYears:(NSInteger)numberOfYears startedDate:(NSDate *) startedDate;


@end
