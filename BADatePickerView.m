//
//  BADatePickerView.m
//  BADatePickerView
//
//  Created by ALLARD Benjamin on 16/08/16.
//

#import "BADatePickerView.h"


@implementation BADatePickerView
{
    //default date picker datasets to reset
    NSArray * dayPossibilities;
    NSArray * monthPossibilities;
    
    //current date picker datasets
    NSMutableArray * months;
    NSMutableArray * years;
    NSMutableArray * days;
    
    //index of columns of the picker view
    NSInteger indexOfDays;
    NSInteger indexOfMonths;
    NSInteger indexOfYears;
    
    //date tools
    NSDateComponents *startDateComponents;
    NSDateComponents *currentDateComponents;
    NSDateFormatter *dateFormatter ;
    BOOL thisYearSelected;
    
    NSDate * currentDateSelected;
    
    //determine which format is used by the region, and set the correct order for the pickerview columns
    NSMutableArray * dateStringFormat;
    NSMutableDictionary * monthNumber;
    
    
}
@synthesize periodicity = _periodicity;
@synthesize startDate = _startDate;

static NSInteger const NUMBER_OF_COLUMNS = 3;
- (instancetype)initWithCoder:(NSCoder *)coder
{
    
    
    self = [super initWithCoder:coder];
    if (self) {
        
        self.delegate = self;
        self.dataSource= self;
        
        _calendar = [NSCalendar currentCalendar];
        
        // init all NSArray, NSMutableArray, ...
        dateFormatter = [[NSDateFormatter alloc] init];
        
        days = [[NSMutableArray alloc]init];
        months = [[NSMutableArray alloc]init];
        years = [[NSMutableArray alloc]init];
        
        dateStringFormat = [[NSMutableArray alloc]init];
        monthNumber = [[NSMutableDictionary alloc] init];
        
        //setAttributes of PickerView
        [self setShowsSelectionIndicator:YES];
        
        //initialize by default (without periodicity, startedDate as today, number of years 50)
        [self initializeWithNumberOfYears:50 startedDate:nil];
        
    }
    return self;
}

- (void)setCalendar:(NSCalendar *)calendar
{
    _calendar = calendar;
    dateFormatter.timeZone = calendar.timeZone;
    dateFormatter.calendar = calendar;
}

/**
 *  Determine which date format is use on the phone
 */
- (void)initDateFormat {
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    df.timeZone = self.calendar.timeZone;
    [df setDateStyle:NSDateFormatterShortStyle];
    [df setTimeStyle:NSDateFormatterShortStyle];
    
    //spare all date elements
    NSArray * array = [[df dateFormat] componentsSeparatedByString:@"/"];
    if([array count] <=1)
    {
        array = [[df dateFormat] componentsSeparatedByString:@"."];
    }
    
    dateStringFormat = [[NSMutableArray alloc]init];
    
    //adding date format element
    for (int i=0; i<3&&i<[array count]; i++) {
        NSString * string =[[NSString alloc]initWithString:[array[i] substringToIndex:1]];
        [dateStringFormat addObject:string];
    }
    
    
    for (int i=0;i<[[df monthSymbols]count];i++)
    {
        [monthNumber setValue:[NSNumber numberWithInt:i+1] forKey:[df monthSymbols][i] ];
    }
}

/**
 *  Clean days array to conserve only the day of the start date, when i have a periodicity and a startdate after today
 */
- (void)removeOthersDays {
    NSInteger startDateDay = [startDateComponents day];
    
    //bugFixing 28 or 29 february as startedDate
    if((startDateDay==28 || startDateDay==29)&&[startDateComponents month]==2)
    {
        startDateDay=30;
    }
    
    long i=0;
    while (i<[days count]) {
        if([[days objectAtIndex:i] integerValue]!=startDateDay)
        {
            [days removeObjectAtIndex:i];
        }
        else
        {
            i++;
        }
    }
}

/**
 *  Delete days before the started date
 */
- (void)removeDaysBeforeStartedDate {
    
    NSInteger startDateDay = [startDateComponents day];
    long i=0;
    while (i<[days count] && [days[i] integerValue]<startDateDay)
    {
        [days removeObjectAtIndex:i];
    }
}

/**
 * Initialiase the day possibilities in a array
 */
- (void)initializeDaysPossibilities
{
    //inits days
    dayPossibilities = [NSArray arrayWithObjects:[[NSNumber alloc] initWithInt:1], [[NSNumber alloc] initWithInt:5],[[NSNumber alloc] initWithInt:10],[[NSNumber alloc] initWithInt:15],[[NSNumber alloc] initWithInt:20], [[NSNumber alloc] initWithInt:25], [[NSNumber alloc] initWithInt:30], nil];
    
    days = [NSMutableArray arrayWithArray:dayPossibilities];
    
    //prepare picker to show the first date
    [self removeDaysBeforeStartedDate];
}

/**
 * Initialiase the months possibilities in a array
 */
- (void)initializeMonthsPossibilities
{
    //init months
    months = [[NSMutableArray alloc] init];
    
    //adding all months from the dateformatter at the array
    for(int month = 0; month < 12; month++)
    {
        [months addObject:[[dateFormatter monthSymbols]objectAtIndex: month]];
    }
    
    //settings monthsPossibilities
    monthPossibilities = [months copy];
}


/**
 * Initialiase the years possibilities in a array
 */
- (void)initYearsPossibilities
{
    //Adding years from started date to numberOfYearFromNow
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    calendar.locale = self.calendar.locale;
    calendar.timeZone = self.calendar.timeZone;
    NSDateComponents *addComponents = [[NSDateComponents alloc] init];
    dateFormatter.dateFormat = @"yyyy";
    
    [years removeAllObjects];
    
    for (int nbYears = 0;nbYears < [self numberOfYearFromNow];nbYears++)
    {
        addComponents.year = nbYears;
        [years addObject:[dateFormatter stringFromDate:[calendar dateByAddingComponents:addComponents toDate:self.startDate options:0]]];
    }
}

-(void)initializeWithNumberOfYears:(NSInteger)numberOfYears startedDate:(NSDate *) startedDate
{
    //settings params
    if(!startedDate)
    {
        self.startDate = [NSDate date];
    }
    else{
        self.startDate = startedDate;
    }
    self.numberOfYearFromNow = numberOfYears;
    
    //initialize date format
    [self initDateFormat];
    [self setIndex];
    
    //init days
    [self initializeDaysPossibilities];
    
    //init months
    [self initializeMonthsPossibilities];
    [self removePreviousMonth:NO];
    
    //init years
    [self initYearsPossibilities];
    
    [self reloadAllComponents];
}

-(void)initializeWithPeriodicity:(NSUInteger)periodicity numberOfYears:(NSInteger)numberOfYears startedDate:(NSDate *) startedDate
{
    //settings params
    if(!startedDate)
    {
        self.startDate = [NSDate date];
    }
    else{
        self.startDate = startedDate;
    }
    self.numberOfYearFromNow = numberOfYears;
    self.periodicity = periodicity;
    
    
    
    //initialize date format
    [self initDateFormat];
    [self setIndex];
    
    
    //init days
    [self initializeDaysPossibilities];
    [self removeOthersDays];
    
    
    //init months
    [self initializeMonthsPossibilities];
    [self removeUnrelevantMonthWithPeriodicity];
    //prepare pickerview of month : delete previous month
    [self removePreviousMonth:YES];
    
    
    //init years
    [self initYearsPossibilities];
    if([months count]==0)
    {
        [self selectNextYear];
        months = [NSMutableArray arrayWithArray:monthPossibilities];
    }
    
    [self selectRow:0 inComponent:indexOfDays animated:NO];
    [self selectRow:0 inComponent:indexOfMonths animated:NO];
    [self selectRow:0 inComponent:indexOfYears animated:NO];
}


#pragma mark - UIPickerViewDataSource

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return NUMBER_OF_COLUMNS;
}

// returns the number of rows in the component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSInteger numberOfRows = [[self getArrayOfComponent:component] count];
    return numberOfRows;
}

#pragma mark - UIPickerViewDelegate

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString * label = @"";
    label = [NSString stringWithFormat:@"%@",[[self getArrayOfComponent:component] objectAtIndex:row]];
    return label;
}

//determine the width of the component for the pickerview
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    CGFloat componentWidth = 0;
    CGFloat pickerViewSizeWidth = pickerView.frame.size.width;
    
    if(component==indexOfDays)
    {
        //days = 1/4
        componentWidth = pickerViewSizeWidth/12*3;
    }
    else
    {
        if(component==indexOfMonths)
        {
            //months = 1/4-1/3 = 5/12
            componentWidth = pickerViewSizeWidth/12*5;
        }
        else
        {
            if(component==indexOfYears)
            {
                //year = 1/3
                componentWidth = pickerViewSizeWidth/12*4;
            }
        }
    }
    return componentWidth;
    
}

// Make action when a specific row is selected
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    
    /**
     *  When I have a periodicity :
     *      - The day is fix
     *      - The months are shown in function of the periodicity and it's possible to select only from the first periodicity (the months before and the current month are deleted of the choice)
     
     *  When I haven't a periodicity :
     *      - I could choose a day inside the range of days preset before
     *      - I remove choice after the 28
     */
    
    BOOL dayChanged = NO;
    BOOL monthChanged = NO;
    BOOL yearChanged = NO;
    BOOL nextMonth = NO;
    BOOL isThisMonthSelected =NO;
    NSInteger indexOfMonthSelected = [self selectedRowInComponent:indexOfMonths];
    NSInteger indexOfYearSelected = [self selectedRowInComponent:indexOfYears];
    NSInteger indexOfDaySelected = [self selectedRowInComponent:indexOfDays];
    
    if(indexOfMonthSelected<[months count])
    {
        isThisMonthSelected = [months[indexOfMonthSelected] isEqualToString:[dateFormatter monthSymbols][[startDateComponents month]-1]];
        
    }
    NSString * currentMonthSelectedString = months[indexOfMonthSelected] ;
    NSInteger  currentMonth = [self getMonthNumberFromMonthString:currentMonthSelectedString];
    
    thisYearSelected = [years[indexOfYearSelected] integerValue]==[startDateComponents year];
    
    //if I haven't possibilities
    if(![days count])
    {
        days = [NSMutableArray arrayWithArray:dayPossibilities];
        indexOfDaySelected = 0;
        if(indexOfMonthSelected+1<[months count])
        {
            //still in the same year, take next month
            indexOfMonthSelected+=1;
            currentMonthSelectedString = months[indexOfMonthSelected] ;
            currentMonth = [self getMonthNumberFromMonthString:currentMonthSelectedString];
            isThisMonthSelected = false;
        }
        else{
            //not still in the same year, take first month
            if(indexOfYearSelected+1<[years count])
            {
                indexOfYearSelected+=1;
                thisYearSelected=false;
                
                months = [NSMutableArray arrayWithArray:monthPossibilities];
                indexOfMonthSelected=0;
                currentMonthSelectedString = months[indexOfMonthSelected] ;
                currentMonth = [self getMonthNumberFromMonthString:currentMonthSelectedString];
                isThisMonthSelected = false;
            }
            
        }
    }
    
    NSInteger currentDaySelected = [days[indexOfDaySelected] integerValue];
    NSInteger currentYear = [years[indexOfYearSelected] integerValue];
    
    
    //manage day only if no periodicity
    
    
    if(thisYearSelected)
    {
        monthChanged = YES;
        if(self.periodicity==0)
        {
            [self removePreviousMonth:NO];
        }
        else
        {
            [self removePreviousMonth:YES];
        }
    }
    else
    {
        monthChanged = YES;
        months = [NSMutableArray arrayWithArray:monthPossibilities];
    }
    
    if(monthChanged)
    {
        [self reloadComponent:indexOfMonths];
        [self selectThisMonth:currentMonthSelectedString];
    }
    
    if(yearChanged)
    {
        [self selectThisYear:currentYear];
    }
    
    
    isThisMonthSelected =[months[[self selectedRowInComponent:indexOfMonths]] isEqualToString:[dateFormatter monthSymbols][[startDateComponents month]-1]];
    
    currentMonthSelectedString = months[[self selectedRowInComponent:indexOfMonths]] ;
    currentMonth = [self getMonthNumberFromMonthString:currentMonthSelectedString];
    
    
    
    if(self.periodicity==0)
    {
        dayChanged = YES;
        days = [NSMutableArray arrayWithArray:dayPossibilities];
        
        
        //if this month and this year remove previous day
        if(isThisMonthSelected && thisYearSelected && !nextMonth)
        {
            dayChanged = YES;
            [self removeDaysBeforeStartedDate];
        }
        
    }
    else
    {
        dayChanged = YES;
    }
    
    
    if([days count]>0)
    {
        //if i haven't a periodicity
        if(self.periodicity==0)
        {
            [days removeLastObject];
            //if february
            if([currentMonthSelectedString isEqualToString:[self getFebruaryMonthString]])
            {
                if(![self dateIsLeapYear:currentYear month:currentMonth day:currentDaySelected])
                {
                    [days addObject:[[NSNumber alloc] initWithInt:28]];
                }
                else
                {
                    [days addObject:[[NSNumber alloc] initWithInt:29]];
                }
   
            }
            else
            {
                [days addObject:[[NSNumber alloc] initWithInt:30]];
            }
            dayChanged = YES;
        }
        else
        {
            if(currentDaySelected>=28)
            {
                [days removeLastObject];
                //if february
                if([currentMonthSelectedString isEqualToString:[self getFebruaryMonthString]])
                {
                    if(![self dateIsLeapYear:currentYear month:currentMonth day:currentDaySelected])
                    {
                        [days addObject:[[NSNumber alloc] initWithInt:28]];
                    }
                    else
                    {
                        [days addObject:[[NSNumber alloc] initWithInt:29]];
                    }
                    
                }
                else
                {
                    [days addObject:[[NSNumber alloc] initWithInt:30]];
                }
                dayChanged = YES;

            }
        }
    }

    
    //reload component changed
    if(dayChanged)
    {
        [self reloadComponent:indexOfDays];
        [self selectThisDay:currentDaySelected];
    }
    
    currentDaySelected = [days[[self selectedRowInComponent:indexOfDays]] integerValue];
    
    //create date from each row selected inside the differents components
    currentDateComponents = [[NSDateComponents alloc] init];
    [currentDateComponents setDay:currentDaySelected];
    [currentDateComponents setMonth:currentMonth];
    [currentDateComponents setYear:currentYear];
    currentDateSelected = [self.calendar dateFromComponents:currentDateComponents];
    
    if ( [[self baDatePickerViewDelegate] respondsToSelector:@selector(pickerView:dateValueChanged:)] ) {
        [[self baDatePickerViewDelegate] pickerView:pickerView dateValueChanged:currentDateSelected];
    }
    
}



#pragma mark - utils for delegate
-(void)selectNextYear
{
    if([years count]!=0 && [years count]>[self selectedRowInComponent:indexOfYears])
    {
        //NSInteger nextYear = years[1];
        BOOL yearFound = NO;
        int i=0;
        NSInteger nextYear = [years[i+1] integerValue];
        
        while(!yearFound && i< [years count] && [years[i] integerValue] <= nextYear)
        {
            if([years[i] integerValue] == nextYear)
            {
                [self selectRow:i inComponent:indexOfYears animated:NO];
                yearFound = YES;
            }
            else
            {
                [years removeObjectAtIndex:i];
            }
        }
        
    }
}

-(void)selectThisYear:(NSInteger)thisYear
{
    BOOL yearFound = NO;
    int i=0;
    while(i< [years count] && [years[i] integerValue] <= thisYear)
    {
        if([years[i] integerValue] == thisYear)
        {
            [self selectRow:i inComponent:indexOfYears animated:NO];
            yearFound = YES;
        }
        i++;
    }
    if(!yearFound)
    {
        [self selectRow:0 inComponent:indexOfYears animated:NO];
    }
}

-(void)selectThisMonth:(NSString *)thisMonth
{
    BOOL monthFound = NO;
    int i = 0;
    while (i<[months count] && !monthFound) {
        if([months[i]isEqualToString:thisMonth])
        {
            [self selectRow:i inComponent:indexOfMonths animated:NO];
            monthFound = YES;
        }
        i++;
    }
    if(!monthFound)
    {
        [self selectRow:0 inComponent:indexOfMonths animated:NO];
    }
}

-(void)selectThisDay:(NSInteger)thisDay
{
    
    //februaryCase
    
    if(thisDay==28 || thisDay==29)
    {
        thisDay=30;
    }
    
    //all case
    BOOL dayFound = NO;
    int i=0;
    while(i< [days count] && [days[i] integerValue] <= thisDay)
    {
        if([days[i] integerValue] == thisDay
           ||( thisDay==30 &&(
                              [days[i] integerValue]==28
                              || [days[i] integerValue]==29)))
        {
            [self selectRow:i inComponent:indexOfDays animated:NO];
            dayFound = YES;
        }
        i++;
    }
    if(!dayFound)
    {
        [self selectRow:0 inComponent:indexOfDays animated:NO];
    }
}


#pragma mark - Utils for locale change

-(NSArray *)getArrayOfComponent:(NSInteger)component
{
    NSArray * array = nil;
    if(component>=0 && component<[dateStringFormat count])
    {
        NSString * dateFormatElement = dateStringFormat[component];
        if ([dateFormatElement isEqualToString:@"d"]) {
            array = days;
        }
        else
        {
            if([dateFormatElement isEqualToString:@"M"])
            {
                array = months;
            }
            else
            {
                array = years;
            }
            
        }
        
    }
    return array;
    
}

-(void)setIndex
{
    
    for (NSInteger i=0; i<[dateStringFormat count];i++) {
        if ([dateStringFormat[i] isEqualToString:@"d"])
        {
            indexOfDays=i;
        }
        else
        {
            if ([dateStringFormat[i] isEqualToString:@"M"])
            {
                indexOfMonths = i;
            }
            else
            {
                indexOfYears = i;
            }
        }
    }
}

-(NSString *)getFebruaryMonthString
{
    return [dateFormatter monthSymbols][1];
}
-(NSInteger)getMonthNumberFromMonthString:(NSString *) monthString
{
    return [[monthNumber objectForKey:monthString] integerValue];
}


/**
 * remove month that are not corresponding with the periodicity
 */
-(void)removeUnrelevantMonthWithPeriodicity
{
    NSDateComponents *components = [self.calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:self.startDate];
    
    if(self.periodicity != 0)
    {
        NSInteger currentMonth = [components month];
        long i = currentMonth;
        //what to do when month = 12 ?
        NSInteger monthInFunctionOfPeriodicity = currentMonth+1;
        
        while(monthInFunctionOfPeriodicity!= currentMonth+12)
        {
            if(i>=[months count])
            {
                i=0;
            }
            
            if(((monthInFunctionOfPeriodicity - currentMonth) % self.periodicity)!=0)
            {
                [months removeObjectAtIndex:i];
            }
            else
            {
                i++;
            }
            
            monthInFunctionOfPeriodicity ++;
        }
    }
    
    monthPossibilities = [months copy];
    
}

-(void)removePreviousMonth:(BOOL)alsoCurrentMonth
{
    BOOL monthFound=NO;
    
    //determine current month and compare with
    NSDateComponents *components = [self.calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:self.startDate];
    NSInteger currentMonth = [components month];
    
    int i = 0;
    while (!monthFound && i<[months count]&&[self getMonthNumberFromMonthString:months[i]]<=currentMonth) {
        if([self getMonthNumberFromMonthString:months[i]]==currentMonth)
        {
            monthFound=YES;
            if(alsoCurrentMonth)
            {
                [months removeObjectAtIndex:i];
            }
        }
        else{
            [months removeObjectAtIndex:i];
        }
        
    }
    
    
}

-(BOOL)dateIsLeapYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day
{
    BOOL leap = (( year%100 != 0) && (year%4 == 0)) || year%400 == 0;
    return leap;
}

#pragma mark - setters / getters

/**
 * Set periodicity in number of month
 */
-(void)setPeriodicity:(NSUInteger)periodicity
{
    if( periodicity !=0)
    {
        _periodicity = periodicity;
    }
}

-(NSUInteger)periodicity
{
    return _periodicity;
}

-(void)setStartDate:(NSDate *)startDate
{
    _startDate = startDate;
    startDateComponents = [self.calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[self startDate]];
}

-(NSDate* )startDate
{
    return _startDate;
}


@end
