# BADatePickerView
Create a custom iOS UIDatePickerView

/!\ WARNING : Don't set the UIPickerViewDataSource and UIPickerViewDelegate, both of them are use in internal. You could use the BADatePickerViewDelegate to iteract with the custom date picker.


This date picker can select a day with the following values : 1, 5, 10, 15, 20, 25, 30.
It's possible to set a month periodicity (in number of month) between the starting date and the selecting date. When a periodicity is set, the day will not be modified.
