# COVIDData

COVIDData has the single purpose of retrieving current data from GitHub related to COVID.  The site used to access this data is at https://github.com/CSSEGISandData/COVID-19.

The data retrieved in each call will include all data for dates available during the COVID-19 pandemic.  4 groups of data can be retrieved:
- Global Deaths
- Global Confirmations
- US Deaths
- US Confirmations

The data is returned as a list of dicrionaries where each dictionary includes a region.  The dictionary will include attributes of the region as well as a series of entries with the date as the key and the respective data value (deaths or confirmed cases).

This package is intended to be useable for any appllication that will use COVID data.

## Enums
### `Scope` 
	.us
	.global

### `DataType`
	.deaths
	.confirmed


## Class
A COVIDData instance must be created to access the functionality of this package.  The scope of the data and the type of data must be included in the initialization.

### `COVIDData(scope: Scope, dataType: DataType)`

	scope: Scope: [.us or .global]
	dataType: DataType: [.deaths, .confirmed]

An instance of `COVIDData` will be returned which will provide access to the functions described below.

## Available Methods
### `getData(lowerCase: Bool = false, castData: Bool = false) -> [[String: String]]`

	lowerCase: Bool: (false) Whether or not keys should be converted to lowercase.
	castData: Bool: (false) Whether or not data values are case to their intended types.


### `getDataDefinition(scope: String) -> [String: NSAttributeType]`
Returns a dictionary of data elements and their respective data type that is used when cast.



